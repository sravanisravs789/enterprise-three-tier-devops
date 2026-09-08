FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 4000

# Regularly check if our Node.js app is responding on port 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/health || exit 1

CMD ["node", "server.js"]
