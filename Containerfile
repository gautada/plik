ARG ALPINE_VERSION=3.22

FROM docker.io/gautada/alpine:$ALPINE_VERSION as plik-frontend-builder

ARG IMAGE_NAME=plik
ARG IMAGE_VERSION=1.3.8

WORKDIR /opt
RUN git clone --branch ${IMAGE_VERSION} https://github.com/root-gg/plik.git ${IMAGE_NAME}
WORKDIR /opt/${IMAGE_NAME}
RUN apk add --no-cache bash go make npm
# ENV CGO_ENABLED="0 go build"
# RUN export CGO_CFLAGS="-DSQLITE_DISABLE_LFS" \
#  && export CGO_LDFLAGS="-DSQLITE_DISABLE_LFS"
RUN make clean-frontend frontend
WORKDIR /opt/${IMAGE_NAME}/server

##################################################################################
FROM --platform=$BUILDPLATFORM golang:1-bullseye AS plik-builder

ARG IMAGE_NAME=plik
ARG IMAGE_VERSION=1.3.8

# Install needed binaries
RUN apt-get update && apt-get install -y build-essential crossbuild-essential-armhf crossbuild-essential-armel crossbuild-essential-arm64 crossbuild-essential-i386

# Prepare the source location
RUN mkdir -p /go/src/github.com/root-gg
WORKDIR /go/src/github.com/root-gg
RUN git clone --branch ${IMAGE_VERSION} https://github.com/root-gg/plik.git ${IMAGE_NAME}
WORKDIR /go/src/github.com/root-gg/plik

# Copy webapp build from previous stage
COPY --from=plik-frontend-builder /opt/plik/webapp/dist webapp/dist

ARG CLIENT_TARGETS=""
ENV CLIENT_TARGETS=$CLIENT_TARGETS

ARG TARGETOS TARGETARCH TARGETVARIANT CC
ENV TARGETOS=$TARGETOS
ENV TARGETARCH=$TARGETARCH
ENV TARGETVARIANT=$TARGETVARIANT
ENV CC=$CC

# Add the source code ( see .dockerignore )
# COPY . .

RUN releaser/releaser.sh



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
ARG USER=plik
RUN /usr/sbin/usermod -l $USER alpine \
&& /usr/sbin/usermod -d /home/$USER -m $USER \ 
&& /usr/sbin/groupmod -n $USER alpine \
&& /bin/echo "$USER:$USER" | /usr/sbin/chpasswd 

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
COPY --from=plik-builder --chown $USER:$USER /go/src/github.com/root-gg/plik/release /home/plik/
COPY plik.s6 /etc/services.d/plik/run
