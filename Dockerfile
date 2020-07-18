FROM golang:alpine3.11

ARG AWSWEEPER_VERSION
ARG AWSCLI_VERSION 

WORKDIR /app

RUN apk add --update \
    bash \
    python \
    python-dev \
    py-pip \
    build-base \
    curl \
    && pip install awscli==$AWSCLI_VERSION --upgrade \
    && apk --purge -v del py-pip \
    && rm -rf /var/cache/apk/*

RUN addgroup -S appuser \
  && adduser -S -G appuser appuser \
  && chown -R appuser:appuser /app

USER appuser

COPY --chown=appuser:appuser install.sh /app/
RUN sh /app/install.sh $AWSWEEPER_VERSION

COPY --chown=appuser:appuser src/env /app/src/
COPY --chown=appuser:appuser src/awsweeper.sh /app/src/
COPY --chown=appuser:appuser config/ /app/config/
COPY --chown=appuser:appuser install.sh /app/

CMD ["./src/awsweeper.sh"]
