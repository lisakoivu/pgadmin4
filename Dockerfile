########################################################################
#
# pgAdmin 4 - PostgreSQL Tools
#
# Copyright (C) 2013 - 2018, The pgAdmin Development Team
# This software is released under the PostgreSQL Licence
#
#########################################################################

# Create the /pgadmin4 directory and copy the source into it. Explicitly
# remove the node_modules directory as we'll recreate a clean version, as well
# as various other files we don't want
FROM alpine:3.13
# FROM debian
# FROM ubuntu:focal

COPY web /pgadmin4/web

#########################################################################
# Next, create the base environment for Python
#########################################################################

# Install dependencies
COPY requirements.txt /pgadmin4
RUN rm -rf /pgadmin4/web/*.log \
           /pgadmin4/web/config_*.py \
           /pgadmin4/web/node_modules \
           /pgadmin4/web/regression \
           `find /pgadmin4/web -type d -name tests` \
           `find /pgadmin4/web -type f -name .DS_Store`

WORKDIR /pgadmin4

RUN apk add --no-cache \
        make \
        bash \
        python3 \
        py3-pip && \
    apk add --no-cache --virtual build-deps \
        build-base \
        openssl-dev \
        libffi-dev \
        postgresql-dev \
        krb5-dev \
        rust \
        cargo \
        python3-dev && \
    python3 -m venv --system-site-packages --without-pip /venv && \
    /venv/bin/python3 -m pip install --no-cache-dir -r requirements.txt && \
    apk del --no-cache build-deps

#########################################################################
# Assemble everything into the final container.
#########################################################################

ENV PYTHONPATH=/pgadmin4

# License files
COPY LICENSE /pgadmin4/LICENSE
COPY DEPENDENCIES /pgadmin4/DEPENDENCIES

# Install runtime dependencies and configure everything in one RUN step
RUN apk add \
        python3 \
        py3-pip \
        bash \
        postfix \
        postgresql-libs \
        krb5-libs \
        shadow \
        sudo \
        libedit \
        libcap && \
    /venv/bin/python3 -m pip install --no-cache-dir gunicorn && \
    find / -type d -name '__pycache__' -exec rm -rf {} + && \
    groupadd -g 5050 pgadmin && \
    useradd -r -u 5050 -g pgadmin pgadmin && \
    mkdir -p /var/lib/pgadmin && \
    chown pgadmin:pgadmin /var/lib/pgadmin && \
    mkdir -p /var/log/pgadmin && \
    chown pgadmin:pgadmin /var/log/pgadmin && \
    touch /pgadmin4/config_distro.py && \
    chown pgadmin:pgadmin /pgadmin4/config_distro.py && \
    setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.8 && \
    # echo "pgadmin ALL = NOPASSWD: /usr/sbin/postfix start" > /etc/sudoers.d/postfix
    echo 'pgadmin ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/pgadmin
USER pgadmin
WORKDIR /pgadmin4/web
COPY web/cli.py /pgadmin4/web



## Needs -u to not buffer progress messages(on stderr)
# ENTRYPOINT ["/venv/bin/python3", "-u", "cli.py"]
# ENTRYPOINT ["/bin/sh"]
