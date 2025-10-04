FROM node:18-alpine

WORKDIR /app
ENV NODE_ENV=production

# Install dependencies first for better layer caching
COPY package*.json ./
RUN npm ci --only=production

# Copy the rest of the application code
COPY . .

# Adjust if the app listens on another port
EXPOSE 8080

# Start via package.json
CMD ["npm", "start"]
