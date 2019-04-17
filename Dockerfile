FROM alpine:3.9.3 as unbound-builder
MAINTAINER FOUCHARD Tony <t.fouchard@qwant.com>
ENV unbound_version 1.9.1
ENV build_root_fs /builtrootfs
RUN apk add --update alpine-sdk openssl-dev expat-dev libevent-dev curl
RUN mkdir -p ${build_root_fs}/opt
WORKDIR /root
RUN curl -Ls  http://unbound.nlnetlabs.nl/downloads/unbound-${unbound_version}.tar.gz | tar --transform='s,-[0-9.]*/,/,' -xzv && \
cd unbound && \
./configure --with-libevent --prefix / && \
make alltargets && \
make install DESTDIR=${build_root_fs}
RUN rm -rf ${build_root_fs}/etc/unbound/unbound.conf.d

FROM alpine:3.9.3
COPY --from=unbound-builder /builtrootfs /
RUN apk add --update bind-tools libevent expat libcap
RUN addgroup -g 1000 unbound && adduser -D -u 1000 -G unbound -s /bin/sh unbound
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/* || true
RUN mkdir -p /var/lib/unbound
RUN setcap CAP_NET_BIND_SERVICE=+eip /sbin/unbound
USER unbound
WORKDIR /home/unbound
CMD ["/sbin/unbound", "-p", "-d"]
