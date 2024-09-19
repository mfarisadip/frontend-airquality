FROM oven/bun:latest

WORKDIR /app

COPY package.json ./
RUN bun install
COPY . ./
RUN bun run build

WORKDIR /app

ENV HOST=0.0.0.0
EXPOSE 4173
CMD ["bun","run", "preview","--", "--host", "0.0.0.0"]
