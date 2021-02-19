FROM ubuntu:18.04
WORKDIR /app

RUN apt-get update && \
    apt-get install -y  \
        mongodb-server \
        ruby-full \
        ruby-bundler \
        ruby-dev  \
        build-essential \
        git \
    && mkdir -p /data/db

COPY . .
# RUN gem install bundler -v '< 2.0'

RUN rm Gemfile.lock \
    && bundle install \
    && chmod 0777 start.sh

EXPOSE 9292
CMD ["/app/start.sh"]
