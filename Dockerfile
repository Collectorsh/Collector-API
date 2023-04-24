FROM ruby:3.0.2

RUN apt-get update && apt-get install -y libsodium-dev libimlib2 libimlib2-dev

RUN mkdir /collector-api
WORKDIR /collector-api
COPY . /collector-api
RUN gem install bundler
RUN bundle install
RUN curl -f -L https://github.com/samuelvanderwaal/metaboss/releases/download/v0.11.1/metaboss-ubuntu-latest --output /usr/bin/metaboss
RUN chmod +x /usr/bin/metaboss

ENV RAILS_ENV production

EXPOSE 3001

# Start the main process.
CMD ["bundle", "exec", "foreman", "start"]
