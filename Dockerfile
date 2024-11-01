FROM node:16-alpine

# Set the environment variable
ARG NODE_ENV=development
ENV NODE_ENV $NODE_ENV

# Set the working directory
WORKDIR /app

# Copy package.json and yarn.lock files
COPY package.json yarn.lock ./

# Clean cache and install dependencies with increased timeout and verbose output
RUN yarn cache clean && \
    yarn install --pure-lockfile --cache-folder .yarn_cache --network-timeout 600000 --verbose

# Copy the rest of your application files
COPY . .

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["yarn", "run", "docker:start"]
