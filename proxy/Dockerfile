FROM centos:latest                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                                                                                                                                   
RUN mkdir /tmp/scripts \
    && curl -L -o /tmp/scripts/v2ray_installer.sh https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh \
    && chmod +x /tmp/scripts/v2ray_installer.sh \
    && /tmp/scripts/v2ray_installer.sh \
    && curl -L -o /tmp/scripts/v2ray_data_installer.sh https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh \
    && chmod +x /tmp/scripts/v2ray_data_installer.sh \
    && /tmp/scripts/v2ray_data_installer.sh \
    && curl -L -o /tmp/scripts/goproxy_installer.sh https://raw.githubusercontent.com/snail007/goproxy/master/install_auto.sh \
    && chmod +x /tmp/scripts/goproxy_installer.sh \
    && /tmp/scripts/goproxy_installer.sh \
    && dnf clean all \
    && rm -rf /tmp/scripts

COPY goproxy_config.txt /etc/proxy/configfile.txt
COPY entrypoint.sh /usr/bin/entrypoint 

RUN chmod +x /usr/bin/entrypoint

VOLUME /usr/local/etc/v2ray /usr/local/share/v2ray /etc/proxy/

ENTRYPOINT ["entrypoint"]
CMD ["v2ray", "-config=/etc/v2ray/config.json"]