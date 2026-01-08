ARG ALPINE_VERSION=3.22

FROM docker.io/gautada/alpine:$ALPINE_VERSION as CONTAINER

ARG IMAGE_NAME=plik
ARG IMAGE_VERSION=1.3.8

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A ${IMAGE_NAME} pastebin"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/gautada/${IMAGE_NAME}"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=cloudflared
RUN /usr/sbin/usermod -l $USER alpine \
&& /usr/sbin/usermod -d /home/$USER -m $USER \ 
&& /usr/sbin/groupmod -n $USER alpine \
&& /bin/echo "$USER:$USER" | /usr/sbin/chpasswd 

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯

WORKDIR /opt
RUN git clone --branch ${IMAGE_VERSION} https://github.com/root-gg/plik.git ${IMAGE_NAME}
WORKDIR /opt/${IMAGE_NAME}
RUN apk add --no-cache bash go make npm
ENV CGO_ENABLED="0 go build"
RUN make
WORKDIR /opt/${IMAGE_NAME}/server
RUN ls -al

