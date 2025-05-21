# Stage 1: Build
FROM node:20-alpine as builder

# Fix OpenSSL dependency issue (if applicable, ensure compatibility)
RUN ln -s /usr/lib/libssl.so.3 /lib/libssl.so.3

WORKDIR /app
ENV NODE_ENV=dev

# Accept the .env file from build arguments
ARG ENV_FILE
RUN echo $ENV_FILE | base64 -d > .env

# Copy package.json and yarn.lock first to leverage Docker cache
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application files
COPY . .

# Build the application
RUN yarn build:${NODE_ENV}

# Stage 2: Serve with Nginx
FROM nginx:alpine


# Copy the built files from the builder stage to the Nginx image
COPY --from=builder /app/dist/ .
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

# Start Nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]
