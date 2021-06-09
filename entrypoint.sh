#!/bin/bash

ZMCONF=/etc/zm/conf.d/03-custom.conf
EVENTSINI=/etc/zm/zmeventnotification.ini
SECRETSINI=/etc/zm/secrets.ini

cleanup () {
    /usr/sbin/apache2 -k stop
    sleep 5
    exit 0
}

trap cleanup SIGTERM

# https://zoneminder.readthedocs.io/en/stable/userguide/configfiles.html
# https://github.com/ZoneMinder/zoneminder/blob/master/zm.conf.in
cat > "${ZMCONF}" << EOF
ZM_DB_HOST=${ZM_DB_HOST:-mariadb}
ZM_DB_USER=${ZM_DB_USER:-zmuser}
ZM_DB_PASS=${ZM_DB_PASS:-zmpass}
ZM_DB_NAME=${ZM_DB_NAME:-zm}
EOF

# https://github.com/pliablepixels/zmeventnotification/blob/master/secrets.ini
[ -n "${ZM_USER}" ]                         && crudini --verbose --set --inplace "${SECRETSINI}" secrets ZM_USER "${ZM_USER}"
[ -n "${ZM_PASSWORD}" ]                     && crudini --verbose --set --inplace "${SECRETSINI}" secrets ZM_PASSWORD "${ZM_PASSWORD}"
[ -n "${ZM_PORTAL}" ]                       && crudini --verbose --set --inplace "${SECRETSINI}" secrets ZM_PORTAL "${ZM_PORTAL}"
[ -n "${ZM_API_PORTAL}" ]                   && crudini --verbose --set --inplace "${SECRETSINI}" secrets ZM_API_PORTAL "${ZM_API_PORTAL}"
[ -n "${ZMES_PICTURE_URL}" ]                && crudini --verbose --set --inplace "${SECRETSINI}" secrets ZMES_PICTURE_URL "${ZMES_PICTURE_URL}"
[ -n "${ES_ADMIN_INTERFACE_PASSWORD}" ]     && crudini --verbose --set --inplace "${SECRETSINI}" secrets ES_ADMIN_INTERFACE_PASSWORD "${ES_ADMIN_INTERFACE_PASSWORD}"
[ -n "${ES_CERT_FILE}" ]                    && crudini --verbose --set --inplace "${SECRETSINI}" secrets ES_CERT_FILE "${ES_CERT_FILE}"
[ -n "${ES_KEY_FILE}" ]                     && crudini --verbose --set --inplace "${SECRETSINI}" secrets ES_KEY_FILE "${ES_KEY_FILE}"
[ -n "${ML_USER}" ]                         && crudini --verbose --set --inplace "${SECRETSINI}" secrets ML_USER "${ML_USER}"
[ -n "${ML_PASSWORD}" ]                     && crudini --verbose --set --inplace "${SECRETSINI}" secrets ML_PASSWORD "${ML_PASSWORD}"
[ -n "${PLATEREC_ALPR_KEY}" ]               && crudini --verbose --set --inplace "${SECRETSINI}" secrets PLATEREC_ALPR_KEY "${PLATEREC_ALPR_KEY}"
[ -n "${OPENALPR_ALPR_KEY}" ]               && crudini --verbose --set --inplace "${SECRETSINI}" secrets OPENALPR_ALPR_KEY "${OPENALPR_ALPR_KEY}"
[ -n "${ESCONTROL_INTERFACE_PASSWORD}" ]    && crudini --verbose --set --inplace "${SECRETSINI}" secrets ESCONTROL_INTERFACE_PASSWORD "${ESCONTROL_INTERFACE_PASSWORD}"
[ -n "${MQTT_USERNAME}" ]                   && crudini --verbose --set --inplace "${SECRETSINI}" secrets MQTT_USERNAME "${MQTT_USERNAME}"
[ -n "${MQTT_PASSWORD}" ]                   && crudini --verbose --set --inplace "${SECRETSINI}" secrets MQTT_PASSWORD "${MQTT_PASSWORD}"
[ -n "${PUSHOVER_APP_TOKEN}" ]              && crudini --verbose --set --inplace "${SECRETSINI}" secrets PUSHOVER_APP_TOKEN "${PUSHOVER_APP_TOKEN}"
[ -n "${PUSHOVER_USER_KEY}" ]               && crudini --verbose --set --inplace "${SECRETSINI}" secrets PUSHOVER_USER_KEY "${PUSHOVER_USER_KEY}"

# https://github.com/pliablepixels/zmeventnotification/blob/master/zmeventnotification.ini
crudini --verbose --set --inplace "${EVENTSINI}" mqtt enable "${MQTT_ENABLE:-no}"
crudini --verbose --set --inplace "${EVENTSINI}" mqtt server "${MQTT_SERVER}"
crudini --verbose --set --inplace "${EVENTSINI}" mqtt username "!MQTT_USERNAME"
crudini --verbose --set --inplace "${EVENTSINI}" mqtt password "!MQTT_PASSWORD"
crudini --verbose --set --inplace "${EVENTSINI}" mqtt retain "${MQTT_RETAIN:-no}"
crudini --verbose --set --inplace "${EVENTSINI}" ssl enable "${SSL_ENABLE:-no}"
crudini --verbose --set --inplace "${EVENTSINI}" ssl cert "!ES_CERT_FILE"
crudini --verbose --set --inplace "${EVENTSINI}" ssl key "!ES_KEY_FILE"

echo "date.timezone = ${TZ:-UTC}" >> /etc/php/7.2/apache2/php.ini
ln -sf "/usr/share/zoneinfo/${TZ:-UTC}" /etc/localtime
echo "${TZ:-UTC}" > /etc/timezone

umount -v /dev/shm
mount -v -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size="${SHMEM:-"50%"}" tmpfs /dev/shm

for uuid in $(blkid -sUUID -ovalue /dev/sd??)
do
    mkdir -v /media/"${uuid}" 2>/dev/null
    mount -v UUID="${uuid}" /media/"${uuid}"
    chown -v www-data:www-data /media/"${uuid}"
done

if ! /usr/bin/mysqlshow -u"${ZM_DB_USER}" -p"${ZM_DB_PASS}" -h"${ZM_DB_HOST}" "${ZM_DB_NAME}" 1>/dev/null
then
    /usr/bin/mysql -u"${ZM_DB_USER}" -p"${ZM_DB_PASS}" -h"${ZM_DB_HOST}" < /usr/share/zoneminder/db/zm_create.sql
fi

/usr/bin/zmupdate.pl -nointeractive
/usr/bin/zmupdate.pl -f

source /etc/apache2/envvars
/usr/sbin/apache2 -k start

/usr/bin/zmpkg.pl start

tail -f /dev/null
