#!/bin/sh

HOST_DEST="marvin.s.upf.edu"
DIR_DEST="/gpfs/robbyfs/HPCNOW/slurmdb01/backup"
DATE=`date +%Y%m%d`
TMP_DIR="/backup/slurmdb01-dump"
MAX_OLD_BACKUP=7 # en dies (7 es una setmana)

echo "***** INICI BACKUP (`date +"%T %D"`) *****"

# 1.- Llista de les BBDD (fem backup de TOTES), la de slurm i la del SIT
echo "- Obtenim la llista de les bases de dades:"
LLISTA_DB=`mysql -sN -h slurmdb01 -u root -pHPCN0w -se "show databases;"`
echo ${LLISTA_DB}

# 2.- Per cadascuna de les BBDD fem un dump comprimit
mkdir -p ${TMP_DIR}/${DATE}
for DATABASE in ${LLISTA_DB}
do
	echo "- Fem de dump de la DB ${DATABASE} ..."
	mysqldump -h slurmdb01 -u root -pHPCN0w ${DATABASE} | gzip > ${TMP_DIR}/${DATE}/${DATABASE}.sql.gz
	echo "... fet."
done

# 3.- Copiem els dumps al gpfs.
echo "- Copiem els dumps al gpfs de marvin."
ssh ${HOST_DEST} "mkdir -p ${DIR_DEST}/${DATE}"
scp ${TMP_DIR}/${DATE}/* root@marvin:${DIR_DEST}/${DATE}

echo "- Eliminem els fitxers temporals de backup de ${TMP_DIR}"
rm -rf ${TMP_DIR}

# eliminem els backups antics per fer nateja 
FILES_TO_PURGE=`ssh ${HOST_DEST} "find ${DIR_DEST} -type d -mtime +${MAX_OLD_BACKUP} -print"`
echo "- Eliminem els backups antics que son aquests fitxers:"
echo "${FILES_TO_PURGE}"
#ssh ${HOST_DEST} "rm -rf ${FILES_TO_PURGE}"

echo "***** FI BACKUP (`date +"%T %D"`) *****"
