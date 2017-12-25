#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

# default
echo "Running Dovecot + Postfix + Rspamd + OpenDKIM"
echo "Host: ${bold}$APP_HOST${normal} (should be set)"
echo "Database: ${bold}$DB_NAME${normal} (should be set)"
echo "Email domain: ${bold}$MAIL_DOMAIN${normal} (should be set)"
echo "Available environment vars:"
echo "MAIL_DOMAIN *required*, APP_HOST *required*, DB_NAME *required*, DB_USER, DB_PASSWORD"

# Configuring OpenDKIM
if [ -f /etc/opendkim/keys/mail.txt ]; then
   echo "Found existing DKIM keys, public key is:"
else
    /etc/opendkim/keys/makekeys.sh
    echo "Generated DKIM keys, public key is:"
fi
cat /etc/opendkim/keys/mail.txt

# adding IP of a host to /etc/hosts
export HOST_IP=$(/sbin/ip route|awk '/default/ { print $3 }')
echo "$HOST_IP dockerhost" >> /etc/hosts

# defining mail name
echo $APP_HOST > /etc/mailname

postconf -e myhostname=$APP_HOST

# update config templates
sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/postfix/mysql-email2email.cf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/postfix/mysql-email2email.cf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/postfix/mysql-email2email.cf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/postfix/mysql-email2email.cf

sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/postfix/mysql-users.cf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/postfix/mysql-users.cf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/postfix/mysql-users.cf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/postfix/mysql-users.cf

sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/postfix/mysql-virtual-alias-maps.cf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/postfix/mysql-virtual-alias-maps.cf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/postfix/mysql-virtual-alias-maps.cf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/postfix/mysql-virtual-alias-maps.cf

sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/postfix/mysql-virtual-mailbox-maps.cf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/postfix/mysql-virtual-mailbox-maps.cf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/postfix/mysql-virtual-mailbox-maps.cf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/postfix/mysql-virtual-mailbox-maps.cf

sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/postfix/mysql-virtual-mailbox-domains.cf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/postfix/mysql-virtual-mailbox-domains.cf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/postfix/mysql-virtual-mailbox-domains.cf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/postfix/mysql-virtual-mailbox-domains.cf

sed -i "s/{{DB_USER}}/$DB_USER/g" /etc/dovecot/dovecot-sql.conf
sed -i "s/{{DB_HOST}}/$DB_HOST/g" /etc/dovecot/dovecot-sql.conf
sed -i "s/{{DB_NAME}}/$DB_NAME/g" /etc/dovecot/dovecot-sql.conf
sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" /etc/dovecot/dovecot-sql.conf

sed -i "s/{{APP_HOST}}/$APP_HOST/g" /etc/dovecot/local.conf

mkdir /run/dovecot
chmod -R +r /run/dovecot
chmod -R +w /run/dovecot
chmod -R 777 /home/vmail
# start logger
rsyslogd

# start rspamd
/etc/init.d/rspamd start

# start OpenDKIM
opendkim

# run Postfix and Dovecot
postfix start
dovecot -F
