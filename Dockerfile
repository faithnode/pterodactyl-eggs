# Toolbox image used to build/test/index this repository without requiring
# anything installed on the host except Docker itself.
#
# Contains: bash, jq, yq (mikefarah/yq, Go binary), docker-cli (for
# Docker-outside-of-Docker install tests in bin/test.sh).
FROM alpine:3.20

RUN apk add --no-cache bash jq curl docker-cli coreutils findutils grep

ARG YQ_VERSION=v4.44.3
RUN curl -sfL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

WORKDIR /repo

ENTRYPOINT ["bash"]
