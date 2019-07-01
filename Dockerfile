FROM ruby:2.5

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock rack-rj_schema.gemspec ./
RUN bundle install

COPY . .

CMD bundle exec rake spec
