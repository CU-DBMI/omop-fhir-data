# https://www.baeldung.com/ops/running-docker-containers-indefinitely
FROM python:3.8.17-bullseye
ARG USER_UID
ARG USER_GID
ARG UID_GID

WORKDIR /workdir

RUN set -x; getent group ${USER_GID} || groupadd -g ${USER_GID} extract
RUN set -x; getent passwd ${USER_UID} ||  useradd extract -u ${USER_UID}  -g ${USER_GID} -m -s /bin/bash
#RUN set -x; usermod  -m -d /workdir/omop-json  $(getent passwd ${USER_UID} | cut -d':' -f1)

RUN apt-get update; apt-get -y install postgresql-client

COPY requirements.txt ./
RUN pip install --upgrade pip; \
    pip install --no-cache-dir -r requirements.txt
RUN mkdir -p /workdir/omop-tools /workdir/omop_json

COPY . .
RUN chown -R ${UID_GID} .


# CMD ["/workdir/Extract_OMOP_json.sh"]