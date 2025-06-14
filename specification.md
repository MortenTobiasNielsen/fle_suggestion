# API Specification
This is the specification for a .NET 9 web API using minimal APIs.

## Base URL
`/api/v1`

## Endpoints

### Data Endpoints

#### GET /data/static
Retrieves static data for a specific agent.

**Query Parameters:**
- `agentId` (string, required): The ID of the agent
- `radius` (integer, required): Search radius (1-1000)

**Response:**
```json
{
    "name": "string",
    "data": {
        // Additional static data properties will be defined later
    }
}
```

#### GET /data/meta
Retrieves metadata for a specific agent.

**Query Parameters:**
- `agentId` (string, required): The ID of the agent
- `radius` (integer, required): Search radius (1-1000)

**Response:**
```json
{
    "name": "string",
    "metadata": {
        // Additional metadata properties will be defined later
    }
}
```

#### GET /data/state
Retrieves current state for a specific agent.

**Query Parameters:**
- `agentId` (string, required): The ID of the agent
- `radius` (integer, required): Search radius (1-1000)

**Response:**
```json
{
    "name": "string",
    "state": {
        // Additional state properties will be defined later
    }
}
```

### Actions Endpoints

#### POST /actions
Adds new actions to the list.

**Request Body:**
```json
{
    "actions": [
        {
            // Action properties will be defined later
        }
    ]
}
```

#### PUT /actions
Updates existing actions in the list.

**Request Body:**
```json
{
    "actions": [
        {
            // Action properties will be defined later
        }
    ]
}
```

#### DELETE /actions
Removes actions from the list.

**Request Body:**
```json
{
    "actionIds": ["string"]
}
```

## Error Responses
All endpoints return errors in the following format:

```json
{
    "statusCode": 400,
    "errorCode": "INVALID_REQUEST",
    "message": "Detailed error message",
    "details": {
        // Optional additional error details
    }
}
```

Common HTTP Status Codes:
- 200: Success
- 400: Bad Request
- 404: Not Found
- 500: Internal Server Error

## Communications Handler
The API will integrate with a communications handler using the RCON protocol. The implementation will use the CoreRCON NuGet package for .NET 9.

### Requirements:
- Implement all functionality from the Python communications handler (integration/communication_handler.py)
- Use RCON protocol for communication
- Utilize CoreRCON package for RCON implementation

## Performance Considerations
- Implement efficient data structures and algorithms
- Use appropriate caching strategies where beneficial
- Optimize database queries and data access patterns
- Consider using async/await patterns for I/O operations
