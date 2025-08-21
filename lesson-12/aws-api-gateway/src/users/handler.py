import json
import boto3
import uuid
import os
from datetime import datetime
from typing import Dict, Any, Optional

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("USERS_TABLE")
if not table_name:
    raise ValueError("USERS_TABLE environment variable is required")
table = dynamodb.Table(table_name)


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for Users API operations
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
                return get_user(path_parameters["id"])
            else:
                return get_users(query_parameters)
        elif http_method == "POST":
            return create_user(json.loads(event["body"]))
        elif http_method == "PUT":
            return update_user(path_parameters["id"], json.loads(event["body"]))
        elif http_method == "DELETE":
            return delete_user(path_parameters["id"])
        else:
            return create_response(405, {"error": "Method not allowed"})

    except Exception as e:
        print(f"Error: {str(e)}")
        return create_response(
            500, {"error": "Internal server error", "message": str(e)}
        )


def get_users(query_params: Dict[str, str]) -> Dict[str, Any]:
    """Get all users with optional filtering"""
    try:
        # Basic scan - in production, consider pagination
        response = table.scan()
        users = response.get("Items", [])

        # Apply filters if provided
        if "name" in query_params:
            name_filter = query_params["name"].lower()
            users = [
                user for user in users if name_filter in user.get("name", "").lower()
            ]

        if "email" in query_params:
            email_filter = query_params["email"].lower()
            users = [
                user for user in users if email_filter in user.get("email", "").lower()
            ]

        # Sort by creation date (newest first)
        users.sort(key=lambda x: x.get("created_at", ""), reverse=True)

        return create_response(
            200,
            {
                "users": users,
                "count": len(users),
                "message": "Users retrieved successfully",
            },
        )

    except Exception as e:
        print(f"Error getting users: {str(e)}")
        return create_response(500, {"error": "Failed to retrieve users"})


def get_user(user_id: str) -> Dict[str, Any]:
    """Get a specific user by ID"""
    try:
        response = table.get_item(Key={"id": user_id})

        if "Item" not in response:
            return create_response(404, {"error": "User not found"})

        return create_response(
            200, {"user": response["Item"], "message": "User retrieved successfully"}
        )

    except Exception as e:
        print(f"Error getting user {user_id}: {str(e)}")
        return create_response(500, {"error": "Failed to retrieve user"})


def create_user(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a new user"""
    try:
        # Validate required fields
        required_fields = ["name", "email"]
        for field in required_fields:
            if field not in user_data or not user_data[field]:
                return create_response(
                    400, {"error": f"Missing required field: {field}"}
                )

        # Validate email format (basic validation)
        email = user_data["email"]
        if "@" not in email or "." not in email:
            return create_response(400, {"error": "Invalid email format"})

        # Check if user with this email already exists
        existing_users = table.scan(
            FilterExpression=boto3.dynamodb.conditions.Attr("email").eq(email)
        )

        if existing_users["Items"]:
            return create_response(
                409, {"error": "User with this email already exists"}
            )

        # Create user object
        user = {
            "id": str(uuid.uuid4()),
            "name": user_data["name"],
            "email": email,
            "phone": user_data.get("phone", ""),
            "address": user_data.get("address", {}),
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "active": True,
        }

        # Save to DynamoDB
        table.put_item(Item=user)

        return create_response(
            201, {"user": user, "message": "User created successfully"}
        )

    except Exception as e:
        print(f"Error creating user: {str(e)}")
        return create_response(500, {"error": "Failed to create user"})


def update_user(user_id: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
    """Update an existing user"""
    try:
        # Check if user exists
        existing_user = table.get_item(Key={"id": user_id})
        if "Item" not in existing_user:
            return create_response(404, {"error": "User not found"})

        user = existing_user["Item"]

        # Update allowed fields
        updatable_fields = ["name", "email", "phone", "address", "active"]
        update_expression = "SET updated_at = :updated_at"
        expression_values = {":updated_at": datetime.utcnow().isoformat()}

        for field in updatable_fields:
            if field in user_data:
                if field == "email":
                    # Validate email format
                    email = user_data[field]
                    if "@" not in email or "." not in email:
                        return create_response(400, {"error": "Invalid email format"})

                    # Check if another user has this email
                    existing_users = table.scan(
                        FilterExpression=boto3.dynamodb.conditions.Attr("email").eq(
                            email
                        )
                        & boto3.dynamodb.conditions.Attr("id").ne(user_id)
                    )

                    if existing_users["Items"]:
                        return create_response(
                            409,
                            {"error": "Another user with this email already exists"},
                        )

                update_expression += f", {field} = :{field}"
                expression_values[f":{field}"] = user_data[field]
                user[field] = user_data[field]

        # Update in DynamoDB
        table.update_item(
            Key={"id": user_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
        )

        user["updated_at"] = expression_values[":updated_at"]

        return create_response(
            200, {"user": user, "message": "User updated successfully"}
        )

    except Exception as e:
        print(f"Error updating user {user_id}: {str(e)}")
        return create_response(500, {"error": "Failed to update user"})


def delete_user(user_id: str) -> Dict[str, Any]:
    """Delete a user (soft delete by setting active=False)"""
    try:
        # Check if user exists
        existing_user = table.get_item(Key={"id": user_id})
        if "Item" not in existing_user:
            return create_response(404, {"error": "User not found"})

        # Soft delete - set active to False
        table.update_item(
            Key={"id": user_id},
            UpdateExpression="SET active = :active, updated_at = :updated_at",
            ExpressionAttributeValues={
                ":active": False,
                ":updated_at": datetime.utcnow().isoformat(),
            },
        )

        return create_response(
            200, {"message": "User deleted successfully", "user_id": user_id}
        )

    except Exception as e:
        print(f"Error deleting user {user_id}: {str(e)}")
        return create_response(500, {"error": "Failed to delete user"})


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
