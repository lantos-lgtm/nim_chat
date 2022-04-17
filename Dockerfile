FROM alpine:edge as build

ARG USER_ID=developer
ARG GROUP_ID=users
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
RUN adduser -D ${USER_ID} -G ${GROUP_ID}

RUN apk update
RUN apk add git curl 

# install gcc
# RUN apk add linx-headers
RUN apk add gcc musl-dev

# install nim
RUN apk add nim nimble

# clean alpine apk cache
RUN rm -rf /var/cache/apk/*
# build the nim program
WORKDIR /nim_chat
ADD src /nim_chat/src
ADD nim_chat.nimble /nim_chat/nim_chat.nimble
ADD config.nims /nim_chat/config.nims

RUN nimble build --y --verbose

FROM alpine:latest as deploy

WORKDIR /data
COPY --from=build /nim_chat/bin/nim_chat /usr/local/bin
RUN chmod +x /usr/local/bin/nim_chat
EXPOSE 1234
VOLUME /data
# ENTRYPOINT [ "/bin/sh" ]
ENTRYPOINT ["nim_chat"]