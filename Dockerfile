FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        openssh-sftp-server \
        sudo \
        curl \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd

EXPOSE 22

CMD ["bash", "/usr/local/bin/entrypoint.sh"]
