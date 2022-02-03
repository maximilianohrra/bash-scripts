#!/bin/bash

## Variables ##
NOMBREPIPE=${1}
FILE=$NOMBREPIPE'.conf'
DIRCONF="/etc/logstash/conf.d"
DIRLOG="/etc/logstash"
RANGOLIM=4000
ULTIMOPUERTOENUSO=$(netstat -ntlp | awk -F":::" '{print $2}'|sort -nr |grep -i "^50"| tail -1)
PUERTOLIBRE=$(($ULTIMOPUERTOENUSO-1))

#Agrega lineas al final del pipe#
cd $DIRLOG
echo "- pipeline.id:" $NOMBREPIPE >>pipelines.yml
echo "  path.config:" $DIRCONF/$FILE >>pipelines.yml

#copia el template y modifica el nombre del archivo de salida#
cp -a $DIRCONF/template.conf $DIRCONF/$FILE

#ingresa al directorio
cd $DIRCONF
chmod 400 $FILE

#valida que el puerto no sea 4000
if [ "$ULTIMOPUERTOENUSO" -eq "$RANGOLIM" ] ; then
	echo "rango limite de puertos utilizados, puerto $ULTIMOPUERTOENUSO actualmente en uso"
	exit 1
else

#modifica el puerto por puerto libre 
    sed -i "s%template%$NOMBREPIPE%g" $FILE
    sed -i "s%9999%$NOMBREPIPE%g" $FILE
	

	#awk '{gsub(/9999/,'$(($PUERTOLIBRE))')}1' $FILE
fi
exit 0
service logstash restart


