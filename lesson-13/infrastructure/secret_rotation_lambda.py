import boto3
import json
import logging
import os
import random
import string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    AWS Secrets Manager rotation function for RDS PostgreSQL
    """
    service = boto3.client('secretsmanager')
    rds_client = boto3.client('rds')
    
    arn = event['Step1']['SecretId']
    token = event['Step1']['ClientRequestToken']
    step = event['Step1']['Step']
    
    # Setup the metadata
    metadata = service.describe_secret(SecretId=arn)
    versions = metadata["VersionIdsToStages"]
    
    if 'AWSCURRENT' not in versions:
        logger.error("Secret %s has no AWSCURRENT version", arn)
        raise ValueError("Secret %s has no AWSCURRENT version" % arn)
    
    # Call the appropriate step function
    if step == "createSecret":
        create_secret(service, arn, token)
    elif step == "setSecret":
        set_secret(service, rds_client, arn, token)
    elif step == "testSecret":
        test_secret(service, arn, token)
    elif step == "finishSecret":
        finish_secret(service, arn, token)
    else:
        logger.error("Invalid step parameter %s for secret %s", step, arn)
        raise ValueError("Invalid step parameter %s for secret %s" % (step, arn))

def create_secret(service, arn, token):
    """
    Create a new secret version with a new password
    """
    try:
        service.get_secret_value(SecretId=arn, VersionId=token, VersionStage="AWSPENDING")
        logger.info("createSecret: Successfully retrieved secret for %s.", arn)
    except service.exceptions.ResourceNotFoundException:
        # Generate new password
        current_secret = get_secret_dict(service, arn, "AWSCURRENT")
        current_secret['password'] = generate_password()
        
        # Put the secret
        service.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(current_secret),
            VersionStages=['AWSPENDING']
        )
        logger.info("createSecret: Successfully put secret for ARN %s and version %s.", arn, token)

def set_secret(service, rds_client, arn, token):
    """
    Set the secret in the database
    """
    current_secret = get_secret_dict(service, arn, "AWSCURRENT")
    pending_secret = get_secret_dict(service, arn, "AWSPENDING", token)
    
    # Update the database password
    try:
        rds_client.modify_db_instance(
            DBInstanceIdentifier='${db_instance_identifier}',
            MasterUserPassword=pending_secret['password'],
            ApplyImmediately=True
        )
        logger.info("setSecret: Successfully set password in RDS for ARN %s.", arn)
    except Exception as e:
        logger.error("setSecret: Failed to set password in RDS for ARN %s: %s", arn, str(e))
        raise e

def test_secret(service, arn, token):
    """
    Test the secret by connecting to the database
    """
    import psycopg2
    
    pending_secret = get_secret_dict(service, arn, "AWSPENDING", token)
    
    try:
        # Test database connection
        conn = psycopg2.connect(
            host=pending_secret['host'],
            port=pending_secret['port'],
            database=pending_secret['dbname'],
            user=pending_secret['username'],
            password=pending_secret['password']
        )
        
        # Test a simple query
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if result[0] == 1:
            logger.info("testSecret: Successfully connected to database for ARN %s.", arn)
        else:
            raise Exception("Database test query failed")
            
    except Exception as e:
        logger.error("testSecret: Failed to connect to database for ARN %s: %s", arn, str(e))
        raise e

def finish_secret(service, arn, token):
    """
    Finish the rotation by updating the version stages
    """
    metadata = service.describe_secret(SecretId=arn)
    current_version = None
    
    for version in metadata["VersionIdsToStages"]:
        if "AWSCURRENT" in metadata["VersionIdsToStages"][version]:
            if version == token:
                # The correct version is already marked as current, return
                logger.info("finishSecret: Version %s already marked as AWSCURRENT for %s", version, arn)
                return
            current_version = version
            break
    
    # Finalize by staging the secret version current
    service.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        ClientRequestToken=token,
        RemoveFromVersionId=current_version
    )
    logger.info("finishSecret: Successfully set AWSCURRENT stage to version %s for secret %s.", token, arn)

def get_secret_dict(service, arn, stage, token=None):
    """
    Get the secret dictionary from AWS Secrets Manager
    """
    kwargs = {'SecretId': arn, 'VersionStage': stage}
    if token:
        kwargs['VersionId'] = token
    
    response = service.get_secret_value(**kwargs)
    return json.loads(response['SecretString'])

def generate_password(length=32):
    """
    Generate a random password
    """
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ''.join(random.choice(characters) for _ in range(length))
    
    # Ensure password meets complexity requirements
    if (any(c.islower() for c in password) and
        any(c.isupper() for c in password) and
        any(c.isdigit() for c in password) and
        any(c in "!@#$%^&*" for c in password)):
        return password
    else:
        # Regenerate if requirements not met
        return generate_password(length)
