# Use the official Node.js image as base
FROM node:22.23.2-alpine

# Dependencies go in /node_modules, which Node searches from the source compose bind-mounts
# at /app, so they always come from this image
WORKDIR /
COPY package*.json ./
RUN npm ci --include=dev

WORKDIR /app

# Expose the port the app runs on
EXPOSE 3000

USER node

# No file watching: a crash must exit the container so `restart: always` brings it back.
# Source is bind-mounted, so `docker compose restart auth-zoo` picks up edits.
CMD ["npm", "start"]
