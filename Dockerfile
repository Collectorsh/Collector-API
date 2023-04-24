FROM ruby:3.0.2

RUN apt-get update && apt-get install -y libsodium-dev libimlib2 libimlib2-dev

RUN mkdir /solsta-api
WORKDIR /solsta-api
COPY . /solsta-api
RUN gem install bundler
RUN bundle install

ENV RAILS_ENV production

EXPOSE 3001

# Start the main process.
CMD ["bundle", "exec", "foreman", "start"]
