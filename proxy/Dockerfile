FROM centos:latest                                                                                                                                                                                     

RUN dnf makecache \
    && dnf install -y wget \
    && curl -L -o /tmp/goproxy_installer.sh https://raw.githubusercontent.com/snail007/goproxy/master/install_auto.sh \
    && chmod +x /tmp/goproxy_installer.sh \
    && /tmp/goproxy_installer.sh \
    && dnf remove -y wget \
    && dnf clean all 

COPY ./entrypoint.sh /usr/bin/entrypoint.sh

RUN chmod +x /usr/bin/entrypoint.sh

VOLUME /etc/proxy/

# SOCKS5_ADDR ==> SPS_ADDR
ENV SOCKS5_ADDR=v2ray:1080
ENV SPS_ADDR=:1081
ENV MAX_CONNECTIONS=100

ENTRYPOINT ["entrypoint.sh"]