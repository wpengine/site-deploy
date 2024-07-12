FROM instrumentisto/rsync-ssh:alpine3.20
# Intsall dependencies
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
            bash \
            php \
 && rm -rf /var/cache/apk/*
# Add entrypoint and excludes
ADD entrypoint.sh /entrypoint.sh
ADD exclude.txt /exclude.txt
ENTRYPOINT ["/entrypoint.sh"]
