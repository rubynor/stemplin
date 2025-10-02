FROM ruby:3.2.2

# Install Node.js 21.5.0
ENV NODE_VERSION=21.5.0
RUN curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz -o node.tar.xz && \
    tar -xJf node.tar.xz -C /usr/local --strip-components=1 && \
    rm node.tar.xz && \
    npm install -g yarn

RUN apt-get update -qq && apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy package.json and install node modules
COPY package.json yarn.lock ./
RUN yarn install

# Copy the application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port 3000
EXPOSE 3000

# Start Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
