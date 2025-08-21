import json
import boto3
import uuid
import os
from datetime import datetime
from decimal import Decimal
from typing import Dict, Any, Optional

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("PRODUCTS_TABLE")
if not table_name:
    raise ValueError("PRODUCTS_TABLE environment variable is required")
table = dynamodb.Table(table_name)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Products API operations
    """
    try:
        http_method = event["httpMethod"]
        path_parameters = event.get("pathParameters") or {}
        query_parameters = event.get("queryStringParameters") or {}

        # Log the incoming request
        print(
            f"Method: {http_method}, Path: {event.get('path')}, Parameters: {path_parameters}"
        )

        if http_method == "GET":
            if "id" in path_parameters:
                return get_product(path_parameters["id"])
            else:
                return get_products(query_parameters)
        elif http_method == "POST":
            return create_product(json.loads(event["body"]))
        elif http_method == "PUT":
            return update_product(path_parameters["id"], json.loads(event["body"]))
        elif http_method == "DELETE":
            return delete_product(path_parameters["id"])
        else:
            return create_response(405, {"error": "Method not allowed"})

    except Exception as e:
        print(f"Error: {str(e)}")
        return create_response(
            500, {"error": "Internal server error", "message": str(e)}
        )


def get_products(query_params: Dict[str, str]) -> Dict[str, Any]:
    """Get all products with optional filtering"""
    try:
        # Basic scan - in production, consider pagination
        response = table.scan()
        products = response.get("Items", [])

        # Convert Decimal to float for JSON serialization
        products = convert_decimals(products)

        # Apply filters if provided
        if "category" in query_params:
            category_filter = query_params["category"].lower()
            products = [
                product
                for product in products
                if category_filter in product.get("category", "").lower()
            ]

        if "name" in query_params:
            name_filter = query_params["name"].lower()
            products = [
                product
                for product in products
                if name_filter in product.get("name", "").lower()
            ]

        if "min_price" in query_params:
            try:
                min_price = float(query_params["min_price"])
                products = [
                    product
                    for product in products
                    if product.get("price", 0) >= min_price
                ]
            except ValueError:
                return create_response(400, {"error": "Invalid min_price format"})

        if "max_price" in query_params:
            try:
                max_price = float(query_params["max_price"])
                products = [
                    product
                    for product in products
                    if product.get("price", 0) <= max_price
                ]
            except ValueError:
                return create_response(400, {"error": "Invalid max_price format"})

        # Sort by creation date (newest first)
        products.sort(key=lambda x: x.get("created_at", ""), reverse=True)

        return create_response(
            200,
            {
                "products": products,
                "count": len(products),
                "message": "Products retrieved successfully",
            },
        )

    except Exception as e:
        print(f"Error getting products: {str(e)}")
        return create_response(500, {"error": "Failed to retrieve products"})


def get_product(product_id: str) -> Dict[str, Any]:
    """Get a specific product by ID"""
    try:
        response = table.get_item(Key={"id": product_id})

        if "Item" not in response:
            return create_response(404, {"error": "Product not found"})

        product = convert_decimals(response["Item"])

        return create_response(
            200, {"product": product, "message": "Product retrieved successfully"}
        )

    except Exception as e:
        print(f"Error getting product {product_id}: {str(e)}")
        return create_response(500, {"error": "Failed to retrieve product"})


def create_product(product_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a new product"""
    try:
        # Validate required fields
        required_fields = ["name", "price", "category"]
        for field in required_fields:
            if field not in product_data or product_data[field] is None:
                return create_response(
                    400, {"error": f"Missing required field: {field}"}
                )

        # Validate price
        try:
            price = float(product_data["price"])
            if price < 0:
                return create_response(400, {"error": "Price must be non-negative"})
        except (ValueError, TypeError):
            return create_response(400, {"error": "Invalid price format"})

        # Validate stock if provided
        stock = product_data.get("stock", 0)
        try:
            stock = int(stock)
            if stock < 0:
                return create_response(400, {"error": "Stock must be non-negative"})
        except (ValueError, TypeError):
            return create_response(400, {"error": "Invalid stock format"})

        # Create product object
        product = {
            "id": str(uuid.uuid4()),
            "name": product_data["name"],
            "description": product_data.get("description", ""),
            "price": Decimal(str(price)),
            "category": product_data["category"],
            "stock": stock,
            "sku": product_data.get("sku", f"SKU-{str(uuid.uuid4())[:8]}"),
            "tags": product_data.get("tags", []),
            "active": True,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        # Save to DynamoDB
        table.put_item(Item=product)

        # Convert for response
        product = convert_decimals(product)

        return create_response(
            201, {"product": product, "message": "Product created successfully"}
        )

    except Exception as e:
        print(f"Error creating product: {str(e)}")
        return create_response(500, {"error": "Failed to create product"})


def update_product(product_id: str, product_data: Dict[str, Any]) -> Dict[str, Any]:
    """Update an existing product"""
    try:
        # Check if product exists
        existing_product = table.get_item(Key={"id": product_id})
        if "Item" not in existing_product:
            return create_response(404, {"error": "Product not found"})

        product = existing_product["Item"]

        # Update allowed fields
        updatable_fields = [
            "name",
            "description",
            "price",
            "category",
            "stock",
            "sku",
            "tags",
            "active",
        ]
        update_expression = "SET updated_at = :updated_at"
        expression_values = {":updated_at": datetime.utcnow().isoformat()}

        for field in updatable_fields:
            if field in product_data:
                value = product_data[field]

                # Validate specific fields
                if field == "price":
                    try:
                        value = float(value)
                        if value < 0:
                            return create_response(
                                400, {"error": "Price must be non-negative"}
                            )
                        value = Decimal(str(value))
                    except (ValueError, TypeError):
                        return create_response(400, {"error": "Invalid price format"})

                elif field == "stock":
                    try:
                        value = int(value)
                        if value < 0:
                            return create_response(
                                400, {"error": "Stock must be non-negative"}
                            )
                    except (ValueError, TypeError):
                        return create_response(400, {"error": "Invalid stock format"})

                update_expression += f", {field} = :{field}"
                expression_values[f":{field}"] = value
                product[field] = value

        # Update in DynamoDB
        table.update_item(
            Key={"id": product_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
        )

        product["updated_at"] = expression_values[":updated_at"]
        product = convert_decimals(product)

        return create_response(
            200, {"product": product, "message": "Product updated successfully"}
        )

    except Exception as e:
        print(f"Error updating product {product_id}: {str(e)}")
        return create_response(500, {"error": "Failed to update product"})


def delete_product(product_id: str) -> Dict[str, Any]:
    """Delete a product (soft delete by setting active=False)"""
    try:
        # Check if product exists
        existing_product = table.get_item(Key={"id": product_id})
        if "Item" not in existing_product:
            return create_response(404, {"error": "Product not found"})

        # Soft delete - set active to False
        table.update_item(
            Key={"id": product_id},
            UpdateExpression="SET active = :active, updated_at = :updated_at",
            ExpressionAttributeValues={
                ":active": False,
                ":updated_at": datetime.utcnow().isoformat(),
            },
        )

        return create_response(
            200, {"message": "Product deleted successfully", "product_id": product_id}
        )

    except Exception as e:
        print(f"Error deleting product {product_id}: {str(e)}")
        return create_response(500, {"error": "Failed to delete product"})


def convert_decimals(obj):
    """Convert DynamoDB Decimal objects to float for JSON serialization"""
    if isinstance(obj, list):
        return [convert_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create a standardized API response"""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        },
        "body": json.dumps(body, default=str),
    }
