FROM ubuntu:noble AS base

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl git openjdk-21-jdk zsh && \
    apt-get clean

FROM base AS build

ARG COMMIT

ARG NODE_VERSION=23.6.0

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential zip && \
    apt-get clean

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

RUN git clone https://github.com/ThePansmith/Monifactory /git

WORKDIR /git/build

RUN git fetch --depth=1 origin $COMMIT

RUN git checkout $COMMIT

RUN bash -c "source /root/.nvm/nvm.sh && npm install && node index.ts build-server"

FROM base

ENV MINECRAFT_VERSION=1.20.1

ENV FORGE_VERSION=47.4.0

RUN curl -sLo /opt/forge-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/$MINECRAFT_VERSION-$FORGE_VERSION/forge-$MINECRAFT_VERSION-$FORGE_VERSION-installer.jar

RUN useradd -m minecraft

USER minecraft

WORKDIR /home/minecraft

RUN java -jar /opt/forge-installer.jar --installServer server

RUN sed -i 's/^java/exec java/' server/run.sh

COPY --from=build --chown=minecraft /git/dist/server server

ENV PATH="$PATH:/home/minecraft/.local/bin"

COPY ./bin/ .local/bin/

WORKDIR server

CMD exec start ./run.sh
