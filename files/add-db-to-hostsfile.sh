#!/bin/bash
#
# GENERATED WITH PUPPET using /modules/hostname/files/add-db-to-hostsfile.sh 

HOSTSFILE="/etc/hosts"
AWSHOSTS="/etc/aws/hosts"

# Controlla se siamo su un ruolo db -> esce
if [[ "${HOSTNAME}" =~ ^.*db[\-].*$ ]]; then
        exit 1
fi

# Controlla se ha gia' l'hostname corretto
if [[ "${HOSTNAME}" =~ ^.*ec2-.*$ ]]; then
	exit 1
fi

# Effettua un backup temporaneo del file /etc/hosts
cp ${HOSTSFILE} ${HOSTSFILE}.tmp

# Calcola il nome del server MySQL
DBHOST="$(echo ${HOSTNAME} | sed -e 's/[0-9]*$//')db"
# Calcola l'IP del server MySQL
DBIP="$(ls ${AWSHOSTS}/${DBHOST})"

# Compone la nuova riga per il file /etc/hosts
LINE="${DBIP} ${DBHOST} int-${DBHOST} int-${DBHOST}-master int-${DBHOST}-slave"

# Modifica - se necessario - la riga del file /etc/hosts
if ! grep -q "${LINE}" ${HOSTSFILE}.tmp; then 
	# Rimuove la vecchia riga..
	grep -v ${DBHOST} ${HOSTSFILE}.tmp > ${HOSTSFILE}
	if [ $? != 0 ]; then
		exit 1
	fi
	# ..e inserisce quella nuova
	echo "${LINE}" >> ${HOSTSFILE}
	if [ $? != 0 ]; then
                exit 1
        fi
fi

rm -f "${HOSTSFILE}.tmp" 2>/dev/null

exit 0

