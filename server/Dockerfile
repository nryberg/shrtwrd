# Use the official Go image as the build stage
FROM golang:1.23-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod file
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY main.go ./

# Copy the words.txt file (should be in the same directory now)
COPY words.txt ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o shrtwrd-server .

# Use a minimal alpine image for the final stage
FROM alpine:latest

# Install ca-certificates and wget for HTTPS requests and health checks
RUN apk --no-cache add ca-certificates wget

# Create a non-root user
RUN adduser -D -s /bin/sh appuser

# Set the working directory
WORKDIR /home/appuser/

# Copy the binary and words file from the builder stage
COPY --from=builder /app/shrtwrd-server .
COPY --from=builder /app/words.txt .

# Change ownership to the non-root user
RUN chown -R appuser:appuser /home/appuser/

# Switch to non-root user
USER appuser

# Expose port 8080 (for internal Docker network)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Run the binary
CMD ["./shrtwrd-server"]
