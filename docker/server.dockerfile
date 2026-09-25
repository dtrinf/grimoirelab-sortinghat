# FROM python:3.12-slim-bookworm
FROM dhi.io/python:3.14-debian-dev
LABEL maintainer="David Trigo <david.trigochavez@axa.com>"

ENV TERM=xterm-256color


# Install base packages
RUN apt-get update && \
    apt-get install -qy \
    --no-install-recommends \
    bash locales-all sudo \
    tree ccze psmisc \
    unzip passwd \
    ssh ca-certificates \
    dirmngr gnupg \
    curl \
    gcc \
    pkg-config \
    libmariadbclient-dev-compat && \
    apt-get purge && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# Configure locales
RUN echo 'LANG="en_US.UTF-8"'>/etc/default/locale

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a user an a group
RUN groupadd -r sortinghat && useradd -r -m -g sortinghat sortinghat

# Install SortingHat and dependencies
#
# We use a virtual environment because it makes easier
# to find the exact location of the packages installed
# and where the static files are available.
ENV \
    # Disable some unused uWSGI features, saving dependencies
    # Thanks to https://stackoverflow.com/a/25260588/90297
    UWSGI_PROFILE_OVERRIDE=ssl=false;xml=false;routing=false

COPY ./dist/*.whl /tmp/dist/
RUN python3 -m venv /opt/venv/ && \
    . /opt/venv/bin/activate && \
    pip install pip --upgrade && \
    pip install /tmp/dist/*.whl && \
    pip check && \
    rm -rf /tmp/dist

# Configure UI and define a volume so it can be
# accessed by other containers (e.g. nginx).
# As the secret key is not necessary to run the admin tool
# we set it to a basic one
RUN . /opt/venv/bin/activate && \
    export SORTINGHAT_CONFIG=sortinghat.config.settings && \
    export SORTINGHAT_SECRET_KEY='abcdef' && \
    UI=`sortinghat-admin setup --only-ui | sed -n "s/^.*files copied to '\(.\+\)'.*$/\1/p"` && \
    ln -s $UI /ui

RUN chown -R sortinghat:sortinghat /opt/venv

# Add entrypoint
COPY ./docker/server-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/server-entrypoint.sh

USER sortinghat

ENTRYPOINT ["server-entrypoint.sh"]

# Expose SortingHat service port and volumes
EXPOSE 9314
VOLUME /ui
