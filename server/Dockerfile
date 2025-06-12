# Factorio Learning Environment Docker image
# Note: Factorio headless server only supports x86_64 architecture
FROM --platform=linux/amd64 factoriotools/factorio:1.1.110

# Add metadata for better container management
LABEL maintainer="FLE Team"
LABEL version="0.2.0"
LABEL description="Factorio Learning Environment with custom mods and scenarios"
LABEL org.opencontainers.image.source="https://github.com/your-repo/factorio-learning-environment"

# Set working directory
WORKDIR /opt/factorio

# Copy configuration files with explicit ownership
# Note: Only copying to /opt/factorio/config (removed duplicate /factorio/config)
COPY --chown=factorio:factorio config/ /opt/factorio/config/
COPY --chown=factorio:factorio mods/ /opt/factorio/mods/
COPY --chown=factorio:factorio scenarios/ /opt/factorio/scenarios/

# Ensure proper permissions for all copied files
RUN find /opt/factorio/config /opt/factorio/mods /opt/factorio/scenarios \
    -type f -exec chmod 644 {} \; && \
    find /opt/factorio/config /opt/factorio/mods /opt/factorio/scenarios \
    -type d -exec chmod 755 {} \;

# Expose ports for game server and RCON
EXPOSE 34197/udp
EXPOSE 27015/tcp

# Add health check to verify the server is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD netstat -ln | grep :34197 || exit 1

# Switch to factorio user for security
USER factorio

# Set default command (can be overridden)
CMD ["/opt/factorio/bin/x64/factorio", "--start-server-load-latest", "--server-settings", "/opt/factorio/config/server-settings.json"]