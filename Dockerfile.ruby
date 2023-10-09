FROM ruby:3.0.2

RUN apt-get update && apt-get install -y libsodium-dev libimlib2 libimlib2-dev

RUN mkdir -p /collector-api/ruby-api
WORKDIR /collector-api/ruby-api
COPY /ruby-api /collector-api/ruby-api/

RUN gem install bundler
RUN bundle install

ENV RAILS_ENV production

EXPOSE 3001

# Start the main process.
CMD ["bundle", "exec", "puma", "-p", "3001", "-w", "0", "-t", "5:15"]