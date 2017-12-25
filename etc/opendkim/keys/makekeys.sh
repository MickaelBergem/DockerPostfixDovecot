# Make sure we are in the current folder (/etc/opendkim/keys)
cd "$(dirname $0)/"

echo "Generating keys for domain $MAIL_DOMAIN..."
mkdir $MAIL_DOMAIN
# Will create two files: mail.private (secret key) and mail.txt (public key)
opendkim-genkey -s mail -d $MAIL_DOMAIN
chown opendkim:opendkim mail.private
