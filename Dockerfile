FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y postfix postfix-mysql dovecot-core dovecot-imapd openssl dovecot-mysql dovecot-sieve dovecot-managesieved
ADD postfix /etc/postfix
ADD dovecot /etc/dovecot
RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 vmail -d /home/vmail -m && \
    chgrp postfix /etc/postfix/mysql-*.cf && \
    chgrp vmail /etc/dovecot/dovecot.conf && \
    chmod g+r /etc/dovecot/dovecot.conf

RUN postconf -e virtual_gid_maps=static:5000 && \
    postconf -e virtual_gid_maps=static:5000 && \
    postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf && \
    postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf && \
    postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-email2email.cf && \
    postconf -e virtual_transport=dovecot && \
    postconf -e dovecot_destination_recipient_limit=1 && \
    postconf -e smtpd_tls_cert_file=/etc/ssl/certs/postfix-cert.pem && \
    postconf -e smtpd_tls_key_file=/etc/ssl/private/postfix-cert.key && \
    postconf -e smtpd_tls_loglevel=1 && \
    postconf -e smtpd_tls_received_header=yes && \
    postconf -e smtpd_tls_security_level=may && \
    postconf -e smtpd_tls_protocols=!SSLv2,!SSLv3,TLSv1,TLSv1.1,TLSv1.2 && \
    postconf -e smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3,TLSv1,TLSv1.1,TLSv1.2 && \
    postconf -e smtpd_tls_mandatory_exclude_ciphers=aNULL,MD5,RC4 && \
    postconf -e smtpd_tls_mandatory_ciphers=high && \
    postconf -e smtp_tls_security_level=may && \
    postconf -e smtp_tls_loglevel=1 && \
    postconf -e smtp_tls_mandatory_protocols=!SSLv2,!SSLv3,TLSv1,TLSv1.1,TLSv1.2 && \
    postconf -e smtp_tls_protocols=!SSLv2,!SSLv3,TLSv1,TLSv1.1,TLSv1.2 && \
    postconf -e smtp_tls_mandatory_exclude_ciphers=aNULL,MD5,RC4 && \
    # specially for docker
    postconf -F '*/*/chroot = n'

RUN echo "dovecot   unix  -       n       n       -       -       pipe"  >> /etc/postfix/master.cf && \
    echo '    flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/deliver -f ${sender} -d ${user}@${nexthop} -a ${recipient}' >> /etc/postfix/master.cf

RUN echo "submission inet n       -       -       -       -       smtpd"  >> /etc/postfix/master.cf && \
    echo "  -o smtpd_tls_security_level=encrypt"  >> /etc/postfix/master.cf && \
    echo "  -o smtpd_sasl_auth_enable=yes"  >> /etc/postfix/master.cf && \
    echo "  -o smtpd_client_restrictions=permit_sasl_authenticated,reject" >> /etc/postfix/master.cf

ADD start.sh /start.sh

# default config
ENV DB_HOST localhost
ENV DB_USER root

# SMTP ports
EXPOSE 25
EXPOSE 587
# POP and IMAP ports
EXPOSE 110
EXPOSE 143
EXPOSE 995
EXPOSE 993
# Manage Sieve
EXPOSE 2093

CMD sh start.sh
