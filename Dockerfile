FROM ubuntu:16.04

RUN apt-get update && apt-get -qq --no-install-recommends install git curl openssl golang ca-certificates vim
RUN mkdir /etc/cracklord /var/cracklord /var/cracklord/www /var/logs /var/logs/cracklord
ENV GOPATH=/root/
RUN git clone https://github.com/jmmcatee/cracklord /root/src/github.com/jmmcatee/
RUN go get -v github.com/jmmcatee/cracklord/cmd/queued ;exit 0
RUN go get -v github.com/jmmcatee/cracklord/cmd/queued
RUN go get -v github.com/jmmcatee/cracklord/cmd/resourced
WORKDIR "/root/src/github.com/jmmcatee/cracklord/cmd/queued"
RUN go build -o /usr/bin/cracklord-queued
WORKDIR "/root/src/github.com/jmmcatee/cracklord/cmd/resourced" 
RUN go build -o /usr/bin/cracklord-resourced 
RUN cp -r $GOPATH/src/github.com/jmmcatee/cracklord/build/queued/conf/* /etc/cracklord/
RUN cp -r $GOPATH/src/github.com/jmmcatee/cracklord/web/* /var/cracklord/www/
RUN cp -r $GOPATH/src/github.com/jmmcatee/cracklord/build/queued/cracklord-queued.conf /etc/init
RUN initctl reload-configuration
RUN openssl genrsa -out /etc/cracklord/ssl/cracklord_ca.key 4096
RUN openssl req -x509 -new -nodes -key /etc/cracklord/ssl/cracklord_ca.key -days 1024 -out /etc/cracklord/ssl/cracklord_ca.pem -config /etc/cracklord/ssl/cracklord_ca_ssl.conf -batch
RUN openssl genrsa -out /etc/cracklord/ssl/queued.key 4096
RUN openssl req -new -key /etc/cracklord/ssl/queued.key -out /etc/cracklord/ssl/queued.csr -config /etc/cracklord/ssl/cracklord_queued_ssl.conf -batch
RUN openssl x509 -req -extensions client_server_ssl -extfile /etc/cracklord/ssl/cracklord_queued_ext.conf -in /etc/cracklord/ssl/queued.csr -CA /etc/cracklord/ssl/cracklord_ca.pem -CAkey /etc/cracklord/ssl/cracklord_ca.key  -CAcreateserial -out /etc/cracklord/ssl/queued.crt -days 500
RUN rm -r /etc/cracklord/ssl/*.csr
RUN echo "aws=/etc/cracklord/resourcemanagers/aws.conf" >> /etc/cracklord/queued.conf
WORKDIR "/root/" 
ENTRYPOINT ["/usr/bin/cracklord-queued", "--conf=/etc/cracklord/queued.conf"]

