# Use Node.js 22.16.0 Alpine as base image
FROM node:22.16.0-alpine

# Set working directory
WORKDIR /app

# Accept the URL as a build argument
ARG NEXT_PUBLIC_OAUTH2_PROXY_URL
# Set it as an environment variable
ENV NEXT_PUBLIC_OAUTH2_PROXY_URL=$NEXT_PUBLIC_OAUTH2_PROXY_URL


# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production=false

# Copy application code
COPY . .

# Expose port 3000
EXPOSE 3000

# Set environment to development
ENV NODE_ENV=development

# Start the development server
CMD ["npm", "run", "dev"]
