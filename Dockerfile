FROM instrumentisto/rsync-ssh:alpine3.20
# Install dependencies
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
            bash \
            php \
 && rm -rf /var/cache/apk/*
# Add entrypoint and utils
COPY utils /utils
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
