ARG BASE_IMAGE_TAG=latest

FROM dtrinf/sortinghat:${BASE_IMAGE_TAG}

LABEL maintainer="David Trigo <david.trigochavez@axa.com>"

USER root

COPY ./worker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/worker-entrypoint.sh

USER sortinghat

ENTRYPOINT ["worker-entrypoint.sh"]
