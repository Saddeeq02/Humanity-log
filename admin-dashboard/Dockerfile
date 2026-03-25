FROM node:22-alpine

WORKDIR /app

# Copy pre-installed local node_modules to bypass Docker network timeouts
COPY . .

# Expose Vite's default dev port
EXPOSE 5173

# Start Vite server, bound to all network interfaces
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
