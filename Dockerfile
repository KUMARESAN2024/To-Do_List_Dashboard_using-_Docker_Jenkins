
# ==========================================
# STAGE 1: BUILD STAGE
# ==========================================

FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# ==========================================
# STAGE 2: SECURE PRODUCTION STAGE
# ==========================================

FROM nginxinc/nginx-unprivileged:alpine

WORKDIR /usr/share/nginx/html

# Copy only production build files
COPY --from=build /app/dist /usr/share/nginx/html

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Application port
EXPOSE 8080

# Explicitly run as non-root user
USER 101:101

# Health check
HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
            CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

# Start application
CMD ["nginx", "-g", "daemon off;"]
