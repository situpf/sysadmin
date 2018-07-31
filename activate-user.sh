#!/bin/sh
# script per activar els usuaris d'un lab

# el primer argument es el nom del lab:
if [ $# -lt 1 ]
then
        echo " Us: $0 nom_lab"
	echo " Exemple: $0 lab_boliva"
        exit 
fi
LDAP_HOST=sit-ldap.s.upf.edu
LLISTA_USUARIS=`mysql -sN -h sit-mysql.s.upf.edu -P 3306 -u sitadmin -pM,esmSdS.4 sitadmin -e "select u.username from usuari u, lab l where u.id_lab=l.id and l.nickname='$1' and NOT u.baixa"`
for usuari in $LLISTA_USUARIS
do
	echo -e "AFEGINT $usuari AL GRUP MARVIN\n"
	cat << EOF | ldapmodify -x -h ${LDAP_HOST} -D "cn=admin,dc=upf,dc=edu" -w O,esmLdS.4
	dn: cn=marvin,ou=Machines,dc=upf,dc=edu
	changetype: modify
	add: memberUid
	memberUid:  uid=${usuari},ou=Users,dc=upf,dc=edu
EOF
done

