FROM instrumentisto/rsync-ssh:alpine3.13-r4
# Intsall dependencies
RUN apk add bash php
# Add entrypoint and excludes
ADD entrypoint.sh /entrypoint.sh
ADD exclude.txt /exclude.txt
ENTRYPOINT ["/entrypoint.sh"]
