FROM alpine:latest

ARG UID=1000
ARG GID=1000
ARG USER=booktree
ARG GROUPNAME=booktree
ENV USER=${USER}
ENV GROUPNAME=${GROUPNAME}
ENV UID=${UID}
ENV GID=${GID}

COPY . /booktree/
WORKDIR /booktree 
RUN echo "**** installing system packages ****" \
    && apk update \
    && apk add --update --no-cache python3 py3-pip inotify-tools ffmpeg \
    && ln -sf python3 /usr/bin/python \   
    && mkdir -p /venv \
    && python -m venv /venv \
    && source /venv/bin/activate \ 
    && pip install --no-cache-dir --requirement requirements.txt \ 
    && pip install --upgrade pip \
    && if getent passwd "${UID}" >/dev/null; then deluser $(getent passwd "${UID}" | cut -d: -f1); fi \
    && if getent group "${GID}" >/dev/null; then delgroup $(getent group "${GID}" | cut -d: -f1); fi \
    && addgroup -S -g ${GID} ${GROUPNAME} \
    && adduser -S -u ${UID} -G ${GROUPNAME} -H -D ${USER} \
    && chown -R ${UID}:${GID} /booktree \
    && chmod +x /booktree/watcher.sh

USER ${USER}
VOLUME /config
VOLUME /logs
VOLUME /data

CMD ["/booktree/watcher.sh"]
