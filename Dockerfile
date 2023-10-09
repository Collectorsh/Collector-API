# Use an image that has Docker and Docker Compose installed
FROM docker/compose:latest

# Copy your project files into the image
COPY . /collector-api

# Set the working directory
WORKDIR /collector-api

# The command to run when the container starts
CMD ["docker","compose", "up", "--build", "-d"]