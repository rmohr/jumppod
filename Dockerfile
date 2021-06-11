FROM alpine

RUN apk add openssh
EXPOSE 2222

RUN adduser -D -h /home/nonroot -u 6372 nonroot

USER nonroot
WORKDIR /home/nonroot

RUN mkdir -p /home/nonroot/etc/ssh/
RUN mkdir -p /home/nonroot/authorized_keys/ && chmod 700 /home/nonroot/authorized_keys/

COPY sshd_config /home/nonroot/.ssh/
COPY entrypoint.sh /home/nonroot/entrypoint.sh

CMD sh -c "ssh-keygen -A -f /home/nonroot && /usr/sbin/sshd -f ~/.ssh/sshd_config -D -e"
