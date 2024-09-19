FROM oven/bun:latest

WORKDIR /app

COPY package.json ./
RUN bun install
COPY . ./
RUN bun run build


FROM node:19-alpine3.16

WORKDIR /app
COPY --from=build /app .


ENV HOST=0.0.0.0
EXPOSE 4173
CMD ["npm","run", "preview","--", "--host", "0.0.0.0"]
