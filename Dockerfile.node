FROM node:16

RUN mkdir -p /collector-api/node-api
WORKDIR /collector-api/node-api

COPY node-api/package*.json ./
RUN yarn install

COPY /node-api /collector-api/node-api/

EXPOSE 3002

CMD ["node", "server.js"]
