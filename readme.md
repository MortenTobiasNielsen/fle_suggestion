# FLE Suggestion
This is to show how it might look like with a separated server with the FLE mod. It is by no means meant to be a "everything works" type of demo, but hopefully you can at least run main.py and login to factorio if you would like to see what happens in the environment. 


The project is organized into several main folders, each serving a specific purpose:

## integration/
Contains Python scripts and logic for integrating with the Factorio game, managing communication, automation, and scenario steps. Includes the main entry point, step parsing, communication handlers, and supporting models.

- **main.py**: Main integration script.
- **docker_manager.py**: Handles Docker image management.
- **communication_handler.py**: Manages communication with the game.
- **models/**: Data models used by the integration scripts.
- **step_parser.py**: A parser for Factorio TAS Generator steps
- **steps_lab.lua**: A Factorio TAS Generator steps file. This is only to create some fast tests to both test and show what will happen in Factorio when a good amount of steps are loaded. 
- **config.json**: Configuration for integration. This is currently not used, but serves as an example of a complex configuration for experiments.

## server/
Contains all files related to running the Factorio server, including Docker setup, scenarios, mods, and configuration.

- **Dockerfile**: Docker configuration for the server.
- **image_check.sh**: Script to check/build the Docker image.
- **scenarios/**: Contains the FLE_Lab scenario.
- **mods/**: Contains the FLE mod.
- **config/**: Server configuration files (settings, passwords, etc.).
