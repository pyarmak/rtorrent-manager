FROM golang:alpine AS build
LABEL org.opencontainers.image.authors="Pavel Yarmak"
WORKDIR /go/src/github.com/adnanh/webhook
ENV WEBHOOK_VERSION 2.8.1
RUN apk add --update -t build-deps curl libc-dev gcc libgcc
RUN curl -L --silent -o webhook.tar.gz https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz && \
    tar -xzf webhook.tar.gz --strip 1
RUN go get -d -v
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /usr/local/bin/webhook

FROM python:3-alpine
COPY --from=build /usr/local/bin/webhook /usr/local/bin/webhook
ENV PYRO_CONF /etc/pyrosimple/config.toml

# Install pip and pyrosimple
RUN apk add --no-cache py3-pip \
    && pip3 install pyrosimple

WORKDIR /etc/webhook
VOLUME /etc/webhook /etc/pyrosimple
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/webhook"]
CMD ["-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]
