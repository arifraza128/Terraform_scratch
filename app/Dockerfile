# Stage 1: Build the React frontend
FROM node:22-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Stage 2: Build the Node.js backend & run the application
FROM node:22-alpine
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm install --only=production
COPY backend/ ./

# Copy built frontend assets to the backend's static file hosting folder
COPY --from=frontend-builder /app/frontend/dist ./public

EXPOSE 5000
ENV PORT=5000

CMD ["node", "server.js"]
