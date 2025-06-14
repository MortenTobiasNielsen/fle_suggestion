# FLE Suggestion
This project demonstrates a separated Factorio Learning Environment (FLE) setup with a containerized Factorio server and modern REST API. The architecture combines the Factorio game server with a .NET API for structured data access, providing both game control via RCON and data retrieval via HTTP endpoints.

## Architecture

The project uses a hybrid approach:
- **Factorio Server**: Headless game server with FLE mod for game logic
- **REST API**: .NET 9 AOT-compiled API for structured data access  
- **RCON Interface**: For game commands and actions
- **Docker**: Containerized deployment with both services

The project is organized into several main folders, each serving a specific purpose:

## API/
Contains the .NET 9 REST API project that provides structured access to Factorio game data.

- **Program.cs**: Main API application with endpoint definitions and OpenAPI configuration
- **Models/**: C# data models for game entities (MetaData, StateData, MapData, etc.)
- **Services/**: Communication handlers for RCON integration
- **API.csproj**: Project configuration with AOT compilation enabled

### API Endpoints
- `GET /data/meta/{agentId}` - Game metadata (items, recipes, technologies)
- `GET /data/state/{agentId}` - Current game state (agents, buildings, research)
- `GET /data/map/{agentId}` - Map information (tiles, offshore pump locations)
- `GET /scalar/v1` - Interactive API documentation (Scalar UI)
- `GET /openapi/v1.json` - OpenAPI specification

## integration/
Contains Python scripts and logic for integrating with the Factorio game, managing communication, automation, and scenario steps. Now uses the REST API for data retrieval and RCON for commands.

- **main.py**: Main integration script with hybrid API/RCON communication
- **docker_manager.py**: Handles Docker image management
- **communication_handler.py**: Manages RCON communication for actions
- **models/**: Data models used by the integration scripts
- **step_parser.py**: Parser for Factorio TAS Generator steps
- **steps_lab.lua**: Sample TAS Generator steps file for testing
- **config.json**: Configuration for integration (example)

## server/
Contains all files related to running the Factorio server, including scenarios, mods, and configuration.

- **scenarios/**: Contains the FLE_Lab scenario
- **mods/**: Contains the FLE mod  
- **config/**: Server configuration files (settings, passwords, etc.)

## Docker Configuration
- **Dockerfile**: Multi-stage build configuration for combined Factorio server + API
- **start-services.sh**: Startup script that runs both Factorio and API services
- **image_check.sh**: Script to check/build the Docker image


## Getting Started

### Prerequisites
- **Docker Desktop**: For running the containerized services
- **Python 3.9+**: For the integration scripts
- **.NET 9 SDK**: If you want to develop/modify the API (optional for running)
- **Git Bash/WSL**: For Windows users (to run shell scripts)

### Quick Start
1. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the integration script**:
   ```bash
   cd integration
   python main.py
   ```

The script will automatically:
- Build the Docker image (Factorio server + API)
- Start the container with both services
- Wait for RCON and API to be ready
- Execute the demo scenario
- Retrieve data via the REST API

### Accessing Services
Once running, you can access:
- **API Documentation**: `http://localhost:5000/scalar/v1` (Interactive Scalar UI)
- **OpenAPI Spec**: `http://localhost:5000/openapi/v1.json`
- **Game Data**: 
  - `http://localhost:5000/data/meta/1`
  - `http://localhost:5000/data/state/1`  
  - `http://localhost:5000/data/map/1`

### Development
1. **Copy FLE mod** to your Factorio installation (if you want to connect to the server):
   ```
   server/mods/FLE/ → %APPDATA%/Factorio/mods/FLE/
   ```

2. **Debug the integration**:
   - Put a breakpoint in `integration/main.py` after data retrieval
   - Run in debug mode to inspect the structured data

### Port Configuration
The container exposes:
- **34197/udp**: Factorio game server
- **27015/tcp**: RCON interface  
- **5000/tcp**: REST API

Multiple instances can run with different port mappings.