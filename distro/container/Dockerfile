FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends qemu-system-x86 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --create-home --uid 10001 zdos

COPY distro/build/vmlinuz /opt/zdos/vmlinuz
COPY distro/build/initramfs.cpio.gz /opt/zdos/initramfs.cpio.gz
COPY distro/container/zdos-entrypoint /usr/local/bin/zdos-entrypoint
RUN chmod 0755 /usr/local/bin/zdos-entrypoint \
 && chown -R zdos:zdos /opt/zdos

USER zdos
WORKDIR /home/zdos
EXPOSE 2222
ENTRYPOINT ["/usr/local/bin/zdos-entrypoint"]
