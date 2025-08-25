import json
import boto3
import psycopg2
import os
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to demonstrate secure database access with encrypted storage
    """
    try:
        # Get database credentials from Secrets Manager
        print("Get database credentials")
        db_credentials = get_secret()
        
        # Connect to database
        print("Connect to database")
        connection = connect_to_database(db_credentials)
        
        # Process the request
        print("Process request")
        result = process_request(event, connection, db_credentials)
        
        # Close database connection
        print("Close database connection")
        connection.close()
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }

def get_secret():
    """
    Retrieve database credentials from AWS Secrets Manager
    """
    secret_arn = os.environ['SECRET_ARN']
    
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=os.environ.get('AWS_REGION', 'eu-central-1')
    )
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(get_secret_value_response['SecretString'])
        logger.info("Successfully retrieved database credentials from Secrets Manager")
        return secret
    except ClientError as e:
        logger.error(f"Error retrieving secret: {str(e)}")
        raise e

def connect_to_database(credentials):
    """
    Establish connection to PostgreSQL database
    """
    try:
        connection = psycopg2.connect(
            host=credentials['host'].split(':')[0],
            port=credentials['port'],
            database=credentials['dbname'],
            user=credentials['username'],
            password=credentials['password'],
            connect_timeout=3,
            sslmode='require'  # Enforce SSL connection
        )
        logger.info("Successfully connected to database")
        return connection
    except psycopg2.Error as e:
        logger.error(f"Error connecting to database: {str(e)}")
        raise e

def process_request(event, connection, credentials):
    """
    Process the incoming request and interact with database
    """
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    
    if path == '/health':
        return health_check(connection)
    elif path == '/users' and http_method == 'GET':
        return get_users(connection)
    elif path == '/users' and http_method == 'POST':
        body = json.loads(event.get('body', '{}'))
        return create_user(connection, body)
    elif path == '/encrypt-data' and http_method == 'POST':
        body = json.loads(event.get('body', '{}'))
        return encrypt_and_store_data(body)
    elif path == '/decrypt-data' and http_method == 'GET':
        query_params = event.get('queryStringParameters', {}) or {}
        return decrypt_and_retrieve_data(query_params.get('key'))
    else:
        return {
            'message': 'Secure Database API',
            'endpoints': [
                'GET /health - Health check',
                'GET /users - List users',
                'POST /users - Create user',
                'POST /encrypt-data - Encrypt and store data in S3',
                'GET /decrypt-data?key=<key> - Decrypt and retrieve data from S3'
            ]
        }

def health_check(connection):
    """
    Perform database health check
    """
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        
        return {
            'status': 'healthy',
            'database': 'connected',
            'version': version,
            'encryption': 'enabled'
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise e

def get_users(connection):
    """
    Retrieve users from database
    """
    try:
        cursor = connection.cursor()
        
        # Create table if it doesn't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        connection.commit()
        
        # Get users
        cursor.execute("SELECT id, name, email, created_at FROM users ORDER BY created_at DESC;")
        users = cursor.fetchall()
        cursor.close()
        
        return {
            'users': [
                {
                    'id': user[0],
                    'name': user[1],
                    'email': user[2],
                    'created_at': user[3].isoformat() if user[3] else None
                }
                for user in users
            ]
        }
    except Exception as e:
        logger.error(f"Error retrieving users: {str(e)}")
        raise e

def create_user(connection, user_data):
    """
    Create a new user in database
    """
    try:
        cursor = connection.cursor()
        
        # Create table if it doesn't exist
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Insert user
        cursor.execute(
            "INSERT INTO users (name, email) VALUES (%s, %s) RETURNING id, created_at;",
            (user_data.get('name'), user_data.get('email'))
        )
        
        user_id, created_at = cursor.fetchone()
        connection.commit()
        cursor.close()
        
        return {
            'message': 'User created successfully',
            'user': {
                'id': user_id,
                'name': user_data.get('name'),
                'email': user_data.get('email'),
                'created_at': created_at.isoformat()
            }
        }
    except psycopg2.IntegrityError as e:
        connection.rollback()
        logger.error(f"User creation failed - integrity error: {str(e)}")
        raise Exception("User with this email already exists")
    except Exception as e:
        connection.rollback()
        logger.error(f"Error creating user: {str(e)}")
        raise e

def encrypt_and_store_data(data):
    """
    Encrypt data using KMS and store in S3
    """
    try:
        s3_client = boto3.client('s3')
        kms_client = boto3.client('kms')
        
        bucket_name = os.environ['S3_BUCKET']
        kms_key_id = os.environ['KMS_KEY_ID']
        
        # Encrypt the data
        data_string = json.dumps(data)
        
        # Generate a unique key for the object
        import uuid
        object_key = f"encrypted-data/{uuid.uuid4()}.json"
        
        # Store in S3 with KMS encryption
        s3_client.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=data_string,
            ServerSideEncryption='aws:kms',
            SSEKMSKeyId=kms_key_id,
            ContentType='application/json'
        )
        
        logger.info(f"Successfully encrypted and stored data with key: {object_key}")
        
        return {
            'message': 'Data encrypted and stored successfully',
            'key': object_key,
            'encryption': 'KMS',
            'storage': 'S3'
        }
        
    except Exception as e:
        logger.error(f"Error encrypting and storing data: {str(e)}")
        raise e

def decrypt_and_retrieve_data(object_key):
    """
    Retrieve and decrypt data from S3
    """
    try:
        if not object_key:
            raise Exception("Object key is required")
            
        s3_client = boto3.client('s3')
        bucket_name = os.environ['S3_BUCKET']
        
        # Retrieve from S3 (automatic decryption with KMS)
        response = s3_client.get_object(
            Bucket=bucket_name,
            Key=object_key
        )
        
        # Read and parse the data
        data_string = response['Body'].read().decode('utf-8')
        decrypted_data = json.loads(data_string)
        
        logger.info(f"Successfully retrieved and decrypted data with key: {object_key}")
        
        return {
            'message': 'Data retrieved and decrypted successfully',
            'data': decrypted_data,
            'key': object_key,
            'encryption': 'KMS',
            'storage': 'S3'
        }
        
    except Exception as e:
        logger.error(f"Error retrieving and decrypting data: {str(e)}")
        raise e
