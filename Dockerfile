# Use official Swift image with all toolchain + runtime
FROM swift:6.0-jammy

# Work inside /app in the container
WORKDIR /app

# Copy manifest and sources
COPY Package.swift ./
COPY Sources ./Sources

# Resolve dependencies (SwiftMCP, etc.)
RUN swift package resolve

# Build a release binary
RUN swift build -c release

# Default port for local run; Render will override PORT env var
ENV PORT=8080

# Document the port the app listens on
EXPOSE 8080

# Run the compiled server
CMD [".build/release/EatNeatMCP"]
