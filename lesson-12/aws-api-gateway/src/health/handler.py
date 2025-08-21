import json
import boto3
import os
from datetime import datetime
from typing import Dict, Any


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Health check endpoint for the API
    """
    try:
        # Get environment information
        environment = os.environ.get("ENVIRONMENT", "unknown")
        region = os.environ.get("AWS_REGION", "unknown")

        # Check DynamoDB connectivity
        dynamodb_status = check_dynamodb_connectivity()

        # Determine overall health status
        overall_status = (
            "healthy" if dynamodb_status["status"] == "healthy" else "unhealthy"
        )
        status_code = 200 if overall_status == "healthy" else 503

        health_data = {
            "status": overall_status,
            "timestamp": datetime.utcnow().isoformat(),
            "environment": environment,
            "region": region,
            "version": "1.0.0",
            "services": {
                "dynamodb": dynamodb_status,
                "lambda": {
                    "status": "healthy",
                    "function_name": context.function_name,
                    "function_version": context.function_version,
                    "memory_limit": context.memory_limit_in_mb,
                    "remaining_time": context.get_remaining_time_in_millis(),
                },
            },
            "uptime": get_uptime(),
            "request_id": context.aws_request_id,
        }

        return create_response(status_code, health_data)

    except Exception as e:
        print(f"Health check error: {str(e)}")
        return create_response(
            503,
            {
                "status": "unhealthy",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e),
                "request_id": context.aws_request_id if context else "unknown",
            },
        )


def check_dynamodb_connectivity() -> Dict[str, Any]:
    """Check if DynamoDB tables are accessible"""
    try:
        dynamodb = boto3.resource("dynamodb")

        # Get table names from environment variables
        users_table_name = os.environ.get("USERS_TABLE")
        products_table_name = os.environ.get("PRODUCTS_TABLE")

        if not users_table_name or not products_table_name:
            return {
                "status": "unhealthy",
                "error": "Table names not found in environment variables",
                "message": "USERS_TABLE and PRODUCTS_TABLE environment variables are required",
            }

        tables_status = {}

        # Check Users table
        try:
            users_table = dynamodb.Table(users_table_name)
            users_table.load()
            tables_status["users_table"] = {
                "name": users_table_name,
                "status": "healthy",
                "table_status": users_table.table_status,
                "item_count": users_table.item_count,
            }
        except Exception as e:
            tables_status["users_table"] = {
                "name": users_table_name,
                "status": "unhealthy",
                "error": str(e),
            }

        # Check Products table
        try:
            products_table = dynamodb.Table(products_table_name)
            products_table.load()
            tables_status["products_table"] = {
                "name": products_table_name,
                "status": "healthy",
                "table_status": products_table.table_status,
                "item_count": products_table.item_count,
            }
        except Exception as e:
            tables_status["products_table"] = {
                "name": products_table_name,
                "status": "unhealthy",
                "error": str(e),
            }

        # Determine overall DynamoDB status
        all_healthy = all(
            table["status"] == "healthy" for table in tables_status.values()
        )

        return {
            "status": "healthy" if all_healthy else "unhealthy",
            "tables": tables_status,
            "message": (
                "All tables accessible" if all_healthy else "Some tables have issues"
            ),
        }

    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "message": "Failed to check DynamoDB connectivity",
        }


def get_uptime() -> Dict[str, Any]:
    """Get system uptime information"""
    try:
        # For Lambda, we can't get traditional uptime, so we return deployment info
        return {
            "message": "Lambda function is stateless - uptime not applicable",
            "deployment_time": datetime.utcnow().isoformat(),
            "cold_start": True,  # This would be more complex to track in real implementation
        }
    except Exception as e:
        return {"error": str(e), "message": "Failed to get uptime information"}


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create a standardized API response"""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0",
        },
        "body": json.dumps(body, default=str),
    }
