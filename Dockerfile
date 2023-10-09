# Use an image that has Docker and Docker Compose installed
FROM docker/compose:latest

RUN ls -l /

# Copy your project files into the image
COPY . /app

# Copy the script into the image
COPY env_to_file.sh /app/env_to_file.sh

# Set the working directory
WORKDIR /app

# Make the script executable
RUN chmod +x /app/env_to_file.sh

# Run the script to generate the .env file, then start docker-compose
ENTRYPOINT ["/bin/sh", "-c", "/app/env_to_file.sh && docker-compose up -d"]


# # OLD
# # Use an image that has Docker and Docker Compose installed
# FROM docker/compose:latest

# # Copy your project files into the image
# COPY . /

# # Set the working directory
# WORKDIR /

# # The command to run when the container starts
# CMD ["docker-compose", "up", "-d"]