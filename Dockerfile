FROM ubuntu:26.04

# Per WP Engine Security guidelines, all WPE images must have the following labels
LABEL com.wpengine.owner="sec-mario"
LABEL com.wpengine.repo="site-deploy"
LABEL com.wpengine.jira="MARIO"
LABEL com.wpengine.slack="pe-mario-public"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
            rsync \
            openssh-client sshpass \
            gettext-base \
            ca-certificates tzdata \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*
# Add entrypoint and utils
COPY utils /utils
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
