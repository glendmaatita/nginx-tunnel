FROM docker.io/debian:12.9-slim as base

WORKDIR /app

ENV DNS_RESOLVER="8.8.8.8 8.8.8.4"
ENV ENABLE_IPV6="off"
ENV EXPIRE_TIME="360"

RUN apt update -y && apt install -y nginx nginx-extras lua5.1 liblua5.1-dev wget gnupg ca-certificates zip build-essential gettext git
RUN wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg && \
    codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release` && \
    echo "deb http://openresty.org/package/debian $codename openresty" \
    | tee /etc/apt/sources.list.d/openresty.list

RUN apt update -y && apt install -y openresty

# install luarocks
RUN wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz && \
    tar zxpf luarocks-3.11.1.tar.gz && \
    cd luarocks-3.11.1 && ./configure && make && make install

    # cleanup
RUN rm luarocks-3.11.1.tar.gz && rm -rf luarocks-3.11.1 && \
    apt remove -y wget gnupg build-essential && apt autoremove -y && apt clean -y && rm -rf /var/lib/apt/lists/*

FROM base as baseclient
COPY ./client/scripts/start.sh /app/start.sh
RUN luarocks install lua-resty-websocket && luarocks install lua-resty-http && luarocks install lua-resty-string
RUN chmod +x /app/start.sh

FROM baseclient as runnerclient
COPY ./client/nginx/nginx.conf /tmp/nginx.conf
COPY ./client/nginx/default.conf /tmp/default.conf
COPY ./client/scripts/tunnel_client.lua /etc/nginx/conf.d/lua/tunnel_client.lua
ENTRYPOINT [ "/app/start.sh" ]

FROM base as baseserver
COPY ./server/scripts/start.sh /app/start.sh
RUN luarocks install lua-resty-websocket
RUN chmod +x /app/start.sh

FROM baseserver as runnerserver
COPY ./server/nginx/nginx.conf /tmp/nginx.conf
COPY ./server/nginx/default.conf /tmp/default.conf
COPY ./server/scripts/tunnel_server.lua /etc/nginx/conf.d/lua/tunnel_server.lua
COPY ./server/scripts/ws_server.lua /etc/nginx/conf.d/lua/ws_server.lua
ENTRYPOINT [ "/app/start.sh" ]