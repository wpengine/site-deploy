FROM alpine:3.23

RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
            rsync \
            openssh-client-default sshpass \
            gettext-envsubst \
            ca-certificates tzdata \
            bash \
            php \
 && update-ca-certificates \
 && rm -rf /var/cache/apk/*
# Add entrypoint and utils
COPY utils /utils
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
