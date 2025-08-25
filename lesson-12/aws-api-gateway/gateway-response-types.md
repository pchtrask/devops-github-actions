# AWS API Gateway - Valid Gateway Response Types

## Platné typy Gateway Response

Podle chybové zprávy jsou platné typy:

### Default Responses
- `DEFAULT_INTERNAL` - Výchozí pro 5xx chyby
- `DEFAULT_4XX` - Výchozí pro 4xx chyby  
- `DEFAULT_5XX` - Výchozí pro 5xx chyby

### Client Error Responses (4xx)
- `RESOURCE_NOT_FOUND` - 404 Not Found
- `UNAUTHORIZED` - 401 Unauthorized
- `ACCESS_DENIED` - 403 Forbidden
- `MISSING_AUTHENTICATION_TOKEN` - 403 Missing Auth Token
- `INVALID_API_KEY` - 403 Invalid API Key
- `BAD_REQUEST_PARAMETERS` - 400 Bad Request Parameters
- `BAD_REQUEST_BODY` - 400 Bad Request Body
- `REQUEST_TOO_LARGE` - 413 Request Too Large
- `UNSUPPORTED_MEDIA_TYPE` - 415 Unsupported Media Type
- `THROTTLED` - 429 Too Many Requests
- `QUOTA_EXCEEDED` - 429 Quota Exceeded

### Authentication/Authorization Errors
- `AUTHORIZER_FAILURE` - Custom authorizer failure
- `AUTHORIZER_CONFIGURATION_ERROR` - Authorizer config error
- `INVALID_SIGNATURE` - Invalid request signature
- `EXPIRED_TOKEN` - Expired authentication token

### Integration Errors (5xx)
- `INTEGRATION_FAILURE` - Backend integration failure
- `INTEGRATION_TIMEOUT` - Backend timeout
- `API_CONFIGURATION_ERROR` - API misconfiguration
- `BAD_INTEGRATION` - Bad integration configuration

### Security
- `WAF_FILTERED` - Request blocked by WAF

## Použití v SAM Template

```yaml
GatewayResponses:
  UNAUTHORIZED:
    StatusCode: 401
    ResponseTemplates:
      "application/json": '{"message": "Unauthorized - API Key required"}'
  
  ACCESS_DENIED:
    StatusCode: 403
    ResponseTemplates:
      "application/json": '{"message": "Forbidden - Invalid API Key"}'
  
  THROTTLED:
    StatusCode: 429
    ResponseTemplates:
      "application/json": '{"message": "Too Many Requests - Rate limit exceeded"}'
  
  INVALID_API_KEY:
    StatusCode: 403
    ResponseTemplates:
      "application/json": '{"message": "Invalid API Key"}'
  
  QUOTA_EXCEEDED:
    StatusCode: 429
    ResponseTemplates:
      "application/json": '{"message": "API Quota Exceeded"}'
```

## Poznámky

- ❌ `FORBIDDEN` není platný typ (použijte `ACCESS_DENIED`)
- ✅ `UNAUTHORIZED` je pro 401 chyby
- ✅ `ACCESS_DENIED` je pro 403 chyby
- ✅ `THROTTLED` je pro rate limiting (429)
- ✅ `INVALID_API_KEY` je specificky pro neplatné API klíče
