FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 4000

CMD ["node", "server.js"]
