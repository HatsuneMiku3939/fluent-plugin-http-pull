FROM quay.io/fluentd_elasticsearch/fluentd:v3.0.2 as builder

RUN apt-get update && apt-get install -y git build-essential autoconf automake libtool libsnappy-dev

RUN mkdir -p /opt/app/fluent-plugin-http-pull
WORKDIR /opt/app/fluent-plugin-http-pull
ADD . ./

RUN bundle config set without 'development' && bundler install && rake install

RUN gem install fluent-plugin-kafka --no-document -v 0.13.0 && \
    gem install snappy --no-document -v 0.0.17 && \
	gem install extlz4 --no-document -v 0.3.1

WORKDIR /	

RUN gem cleanup && \
    rm -rf /opt/app/fluent-plugin-http-pull && \
    apt-get remove --autoremove -y build-essential git autoconf automake && \
	apt-get autoclean