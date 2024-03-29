FROM ruby:2.6.6-alpine
RUN apk add --no-cache --update build-base linux-headers git

LABEL com.github.actions.name="Rankmi's Rubocop Code Checks"
LABEL com.github.actions.description="Lint your Ruby code in parallel to your builds"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="red"

LABEL maintainer="Felipe Alvarado <felipe.alvarado+rubcolintern@rankmi.com>"

COPY lib /action/lib
COPY lib/Gemfile ./Gemfile
COPY lib/Gemfile.lock ./Gemfile.lock
RUN gem install bundler 
RUN bundle install

ENTRYPOINT ["/action/lib/entrypoint.sh"]
