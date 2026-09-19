# Use the official Node.js image as base
FROM node:22-alpine

# Install curl and build tools
RUN apk add --no-cache \
    curl \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install all dependencies (including devDependencies for development)
RUN npm ci --include=dev

# Expose the port the app runs on
EXPOSE 3000

USER node

# No file watching: a crash must exit the container so `restart: always` brings it back.
# Source is bind-mounted, so `docker compose restart auth-zoo` picks up edits.
CMD ["npm", "start"]
