# Use an image that has Docker and Docker Compose installed
FROM docker/compose:latest

# Copy your project files into the image
COPY . /

# Copy the script into the image
COPY env_to_file.sh /env_to_file.sh

# Set the working directory
WORKDIR /

# Make the script executable
RUN chmod +x /env_to_file.sh

# Run the script to generate the .env file, then start docker-compose
ENTRYPOINT ["/bin/sh", "-c", "/env_to_file.sh && docker-compose up -d"]


# # OLD
# # Use an image that has Docker and Docker Compose installed
# FROM docker/compose:latest

# # Copy your project files into the image
# COPY . /

# # Set the working directory
# WORKDIR /

# # The command to run when the container starts
# CMD ["docker-compose", "up", "-d"]