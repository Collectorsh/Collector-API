FROM node:16

ENV TZ=America/Los_Angeles

# RUN mkdir -p /collector-api/node-api
# WORKDIR /collector-api/node-api

RUN mkdir /node-api
WORKDIR /node-api

COPY node-api/package*.json ./
RUN yarn install

COPY /node-api /node-api

EXPOSE 3002

CMD ["node", "server.js"]
