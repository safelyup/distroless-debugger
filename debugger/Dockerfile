FROM busybox:musl

WORKDIR /
COPY ./executables/ /usr/local/bin/
COPY ./tools/ /tools/
COPY ./run.sh /run.sh

CMD ["/run.sh"]
