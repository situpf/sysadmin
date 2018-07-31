#!/bin/bash

# backup de snow (sistema gestio cluster)

echo "*** INICI DEL BACKUP (`date +"%T %D"`) ***"

# 0.- carreguem la congui de l'snow, pq sino via crontab no rulen alguns comandes
source /etc/profile.d/snow.sh
export PATH=$PATH:/sbin

# 1.- configuracio del node /etc i llista de paquets instalats
DATA=`date +%Y%m%d`
EXCLUDE_SNOW_DIR="--exclude=oldbackup --exclude=OS --exclude=common/slurm/etc/hdf5"
mkdir -p /backup/$DATA
TMPDIR=/backup/$DATA
DESTDIR=/gpfs/robbyfs/HPCNOW/snow01/backup
MAXOLDBACKUP=30   # en dies (ej, 30 es 1 mes)

echo "- Fem un tgz amb la configuracio de snow01 (/etc) i la llista de paques instalÂlats."
cd /etc && tar zcvf  $TMPDIR/etc.tgz .
dpkg --get-selections | awk ' {print $1 }' | xargs > $TMPDIR/package-list.txt

# sNow filesystem
echo "- Fem un tgz amb el contingut del directori /sNow (exclude dirs: $EXCLUDE_SNOW_DIR)."
cd /sNow && tar $EXCLUDE_SNOW_DIR -zcvf $TMPDIR/sNow.tgz .

# snow VMs
# creem una llista de les vm
LLISTA_VM=`snow list domains | grep -v Domain| awk '{print $1}'`
echo "- Fem el snapshots de les VM: ${LLISTA_VM}"
# fem els snapshots
for domini in $LLISTA_VM
do
        lvcreate -s -L 30G -n $domini-snap snow_vg/$domini-disk
done

# llistem els snapshots
echo "- Dels snapshots fem els .img, un per cada VM."
LLISTA_LV=`lvs | grep snap | awk '{print $1}'`
# fem el backup
for i in $LLISTA_LV
do
        dd if=/dev/snow_vg/$i of=$TMPDIR/$i.vm.img
done

# podem eliminar els snapshots
echo "- Eliminem els snapshots."
for i in $LLISTA_LV
do
        lvremove -f snow_vg/$i
done

# copiem el backup elsewhere
echo "- Copiem els fitxers del backup que hi son a $TMPDIR a $DESTDIR/$DATA".
ssh marvin "mkdir -p $DESTDIR/$DATA"
cd $TMPDIR
scp * root@marvin:$DESTDIR/$DATA
cd /backup
echo "- Eliminem els fitxers de temporals de backup: $TMPDIR"
rm -rf $TMPDIR

# eliminem els backups antics per fer nateja 
FILES_TO_PURGE=`ssh marvin "find $DESTDIR -type d -mtime +$MAXOLDBACKUP -print"`
echo "- Eliminem els backups antics que son aquests fitxers:"
echo "$FILES_TO_PURGE"
#ssh marvin "rm -rf $FILES_TO_PURGE"

echo "*** FI DEL BACKUP (`date +"%T %D"`) ***"
echo ""
