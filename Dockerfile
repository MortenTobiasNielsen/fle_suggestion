# Multi-stage build for Factorio Learning Environment with API
# Stage 1: Build the .NET API
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:9.0 AS build-api

# Install AOT prerequisites (clang, build tools)
RUN apt-get update && \
    apt-get install -y clang zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy solution and project files
COPY ["fle_suggestion.sln", "./"]
COPY ["API/API.csproj", "API/"]

# Restore dependencies
RUN dotnet restore "API/API.csproj"

# Copy source code
COPY . .

# Build and publish the API with AOT
WORKDIR "/src/API"
RUN dotnet publish "API.csproj" -c Release -o /app/publish

# Stage 2: Create the final runtime image with both Factorio and API
FROM --platform=linux/amd64 factoriotools/factorio:1.1.110 AS runtime

# Add metadata for better container management
LABEL maintainer="FLE Team"
LABEL version="0.2.0"
LABEL description="Factorio Learning Environment with custom mods, scenarios, and API"
# TODO: Add the actual repository
LABEL org.opencontainers.image.source="https://github.com/your-repo/factorio-learning-environment" 

# Switch to root briefly for file operations (AOT executable doesn't need .NET runtime)
USER root

# Set working directory
WORKDIR /opt/factorio

# Copy Factorio configuration files with explicit ownership
COPY --chown=factorio:factorio /server/config/ /opt/factorio/config/
COPY --chown=factorio:factorio /server/mods/ /opt/factorio/mods/
COPY --chown=factorio:factorio /server/scenarios/ /opt/factorio/scenarios/

# Copy API application
COPY --from=build-api --chown=factorio:factorio /app/publish /opt/api/

# Ensure proper permissions for all copied files
RUN find /opt/factorio/config /opt/factorio/mods /opt/factorio/scenarios \
    -type f -exec chmod 644 {} \; && \
    find /opt/factorio/config /opt/factorio/mods /opt/factorio/scenarios \
    -type d -exec chmod 755 {} \; && \
    find /opt/api -type f -exec chmod 644 {} \; && \
    find /opt/api -type d -exec chmod 755 {} \; && \
    chmod +x /opt/api/API

# Copy startup script
COPY --chown=factorio:factorio start-services.sh /opt/start-services.sh
RUN chmod +x /opt/start-services.sh

# Expose ports for game server, RCON, and API
EXPOSE 34197/udp
EXPOSE 27015/tcp
EXPOSE 5000/tcp

# Add health check to verify both services are running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD (netstat -ln | grep :34197 && netstat -ln | grep :5000) || exit 1

# Switch to factorio user for security
USER factorio

# Override the base image entrypoint and set our startup script
ENTRYPOINT []
CMD ["/opt/start-services.sh"]