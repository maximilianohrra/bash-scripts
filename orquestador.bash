#!/bin/bash 
## Variables de trabajo ##
LOG="/tmp/orquestador.log"
DIRORQUESTADOR="/docker/imagenes/scripts"


### Ingreso de variables. Se validan abajo.
NOMBRESERVICIO=""
JAR=""
CONFIGYML=""
DEPENDENCIAS=""
IMAGENSELECCION=""
RUN=""

## Variables de ejecucion ##
NUEVO=""
SERVICIO=""
SALIDA=0
DIRTRABAJO="/docker/servicios"
DIREXISTE="NO"



#########################
### FUNCION VERIFICAR ###
#########################

function verificar {
	## Esta funcion verifica si el servicio es nuevo. Verifica directorio y servicio.
	## Si el servicio existe, pone nuevo en true
	echo "Realizando validaciones..." | tee -a $LOG

	SERVICIODOCKER=`/usr/bin/docker service ls | awk '{print $2}' |grep -w "^$NOMBRESERVICIO$"`

	if [ "$NOMBRESERVICIO" = "$SERVICIODOCKER" ] ;
	then
		echo "Servicio existente $NOMBRESERVICIO" |tee -a $LOG
		NUEVO="NO"
		SERVICIO=$SERVICIODOCKER
		SALIDA=0
	else
		echo "Se va a levantar un nuevo servicio $NOMBRESERVICIO" |tee -a $LOG
		## Verifico si existe el archivo startHA.bash ##
		# Copio los archivos de template para la ejecucion y modificarlos.Si el directorio existe, no copia el startHA.bash #
		if [ -f $DIRSERVICIO/startHA.bash ] ; then
			echo "Existe el archivo $DIRSERVICIO/startHA.bash" |tee -a $LOG
			DIREXISTE="YES" 
		else
			mkdir $DIRSERVICIO
			## Depende de la imagen, es la configuracion ##
			case "$IMAGENSELECCION" in
				Java-8)
				cp -a $DIRORQUESTADOR/templates/startHA-java.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
			        ;;
				Java-11)
				cp -a $DIRORQUESTADOR/templates/startHA-java.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
			        ;;
			        NGINX)
				cp -a $DIRORQUESTADOR/templates/startHA-nginx.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
			        ;;
				Python-3.6)
				cp -a $DIRORQUESTADOR/templates/startHA-python.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
				;;
				Ansible|Angular)
				cp -a $DIRORQUESTADOR/templates/startHA-nginx.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
				;;
				NET-CORE-2.2) 
				cp -a $DIRORQUESTADOR/templates/startHA-sdk.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
				;;
				Python-Flask) 
				cp -a $DIRORQUESTADOR/templates/startHA-python-flask.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
				;;
				Redis)
				cp -a $DIRORQUESTADOR/templates/startHA-redis.bash $DIRSERVICIO/startHA.bash |tee -a $LOG
			       	;;
			esac
		fi

		NUEVO="SI"
		SERVICIO=$NOMBRESERVICIO
		SALIDA=0
	fi

}

#####################
### FIN VERIFICAR ###
#####################




#######################
# FUNCION CREARIMAGEN #
#######################
function crearimagen {
	## Se realiza de case por imagen ##

    case "$IMAGENSELECCION" in
    Java-8)
        construirjava
        ;;
    Java-11)
        construirjava11
        ;;
    NGINX)
        construirnginx
        ;;
    Python-3.6)
        construirpython
        ;;
    Ansible|Angular)
        construiransible
        ;;
    NET-CORE-2.2)
	construirsdk22
	;;
    Python-Flask)
	construirpythonflask
	;;
    Redis)
	construirredis
	;;
    Java11-Quarkus)
	construirquarkus
	;;
    esac

}

## Construir imagen JAVA ##
function construirjava {
	echo "CONFIG STEP: Crear Imagen -- construirjava"

	cp -a $DIRORQUESTADOR/templates/Dockerfile-java $DIRSERVICIO/Dockerfile |tee -a $LOG 

	DATE=`date +"%Y%m%d%H%M"`
	REGISTRYLOCAL="lal075:8088"
	IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE


	echo "Dir de servicio: $DIRSERVICIO"
	echo "Jar file: $JAR"
	echo "Config file: $CONFIGYML"
	echo "Start del servicio: $RUN"

	## No se puede pasar esto por ARG en Dockerfile ##
	echo "nohup /etc/init.d/filebeat start &" >  $DIRSERVICIO/startapi
	echo $RUN >> $DIRSERVICIO/startapi
	chmod +x $DIRSERVICIO/startapi


	# Build
	cd $DIRSERVICIO
	docker build --build-arg jarfile=$JAR --build-arg configfile=$CONFIGYML --build-arg dependencias=$DEPENDENCIAS -t $IMAGENDOCKER $DIRSERVICIO/. >> $LOG 2>&1
	VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

	if [ $VALIDABUILD -gt 0 ] ;  then
		# Si las salida dio ok, voy a pushear la imagen #
		# Pusheo a Experta #
		echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
		docker push $IMAGENDOCKER >> $LOG 2>&1

		SALIDA=1
	else
		SALIDA=0
	fi
}


## Construir imagen JAVA 11 ##
function construirjava11 {
	echo "CONFIG STEP: Crear Imagen -- construirjava 11"

	cp -a $DIRORQUESTADOR/templates/Dockerfile-java11 $DIRSERVICIO/Dockerfile |tee -a $LOG 

	DATE=`date +"%Y%m%d%H%M"`
	REGISTRYLOCAL="lal075:8088"
	IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE


	echo "Dir de servicio: $DIRSERVICIO"
	echo "Jar file: $JAR"
	echo "Config file: $CONFIGYML"
	echo "Start del servicio: $RUN"

	## No se puede pasar esto por ARG en Dockerfile ##
	echo "nohup /etc/init.d/filebeat start &" >  $DIRSERVICIO/startapi
	echo $RUN >> $DIRSERVICIO/startapi
	chmod +x $DIRSERVICIO/startapi


	# Build
	cd $DIRSERVICIO
	docker build --build-arg jarfile=$JAR --build-arg configfile=$CONFIGYML --build-arg dependencias=$DEPENDENCIAS -t $IMAGENDOCKER $DIRSERVICIO/. >> $LOG 2>&1
	VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

	if [ $VALIDABUILD -gt 0 ] ;  then
		# Si las salida dio ok, voy a pushear la imagen #
		# Pusheo a Experta #
		echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
		docker push $IMAGENDOCKER >> $LOG 2>&1

		SALIDA=1
	else
		SALIDA=0
	fi
}


function construirnginx {

	echo "CONFIG STEP: Crear Imagen -- construirnginx"

	cp -a $DIRORQUESTADOR/templates/Dockerfile-nginx $DIRSERVICIO/Dockerfile |tee -a $LOG 

	DATE=`date +"%Y%m%d%H%M"`
	REGISTRYLOCAL="lal075:8088"
	IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

	# Build
	cd $DIRSERVICIO
	docker build --build-arg site=$SITIO -t $IMAGENDOCKER $DIRSERVICIO/. >> $LOG 2>&1
	VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

	if [ $VALIDABUILD -gt 0 ] ;  then
		# Si las salida dio ok, voy a pushear la imagen #
		# Pusheo a Experta #
		echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
		docker push $IMAGENDOCKER >> $LOG 2>&1

		SALIDA=1
	else
		SALIDA=0
	fi

}



function construiransible {

	echo "CONFIG STEP: Crear Imagen -- construiransible"

	cp -a $DIRORQUESTADOR/templates/Dockerfile-ansible $DIRSERVICIO/Dockerfile |tee -a $LOG 

	DATE=`date +"%Y%m%d%H%M"`
	REGISTRYLOCAL="lal075:8088"
	IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

	# Build
	cd $DIRSERVICIO
	docker build --build-arg site=$SITIO -t $IMAGENDOCKER $DIRSERVICIO/. >> $LOG 2>&1
	VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

	if [ $VALIDABUILD -gt 0 ] ;  then
		# Si las salida dio ok, voy a pushear la imagen #
		# Pusheo a Experta #
		echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
		docker push $IMAGENDOCKER >> $LOG 2>&1

		SALIDA=1
	else
		SALIDA=0
	fi

}


function construirpython {
        echo "CONFIG STEP: Crear Imagen -- construirpython"

	## Se utiliza el dockerfile provisto en el repo ##

        DATE=`date +"%Y%m%d%H%M"`
        REGISTRYLOCAL="lal075:8088"
        IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

        # Build
        cd $DIRSERVICIO
        docker build -t $IMAGENDOCKER $DIRSERVICIO/$SITIO/.
        VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

        if [ $VALIDABUILD -gt 0 ] ;  then
                # Si las salida dio ok, voy a pushear la imagen #
                # Pusheo a Experta #
                echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
                docker push $IMAGENDOCKER >> $LOG 2>&1

                SALIDA=1
        else
                SALIDA=0
        fi


}



function construirpythonflask {
        echo "CONFIG STEP: Crear Imagen -- construirpythonflask"

	## Se utiliza el dockerfile provisto en el repo ##

        DATE=`date +"%Y%m%d%H%M"`
        REGISTRYLOCAL="lal075:8088"
        IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

        # Build
        cd $DIRSERVICIO
        docker build --build-arg site=$SITIO -t $IMAGENDOCKER $DIRSERVICIO/. #>> $LOG 2>&1
        VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

        if [ $VALIDABUILD -gt 0 ] ;  then
                # Si las salida dio ok, voy a pushear la imagen #
                # Pusheo a Experta #
                echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
                docker push $IMAGENDOCKER >> $LOG 2>&1

                SALIDA=1
        else
                SALIDA=0
        fi


}
function construirquarkus {
        echo "CONFIG STEP: Crear Imagen -- construir quarkus"

	## Se utiliza el dockerfile provisto en el repo ##

	cp -a $DIRORQUESTADOR/templates/Dockerfile-java11-quarkus $DIRSERVICIO/Dockerfile |tee -a $LOG

        DATE=`date +"%Y%m%d%H%M"`
        REGISTRYLOCAL="lal075:8088"
        IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

        # Build
        cd $DIRSERVICIO
        docker build -t $IMAGENDOCKER $DIRSERVICIO/. #>> $LOG 2>&1
        VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

        if [ $VALIDABUILD -gt 0 ] ;  then
                # Si las salida dio ok, voy a pushear la imagen #
                # Pusheo a Experta #
                echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
                docker push $IMAGENDOCKER >> $LOG 2>&1

                SALIDA=1
        else
                SALIDA=0
        fi


}



function construirredis {
        echo "CONFIG STEP: Crear Imagen -- construirredis"

	## Se utiliza el dockerfile provisto en el repo ##

        DATE=`date +"%Y%m%d%H%M"`
        REGISTRYLOCAL="lal075:8088"
        IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

        # Build
        cd $DIRSERVICIO
        docker build -t $IMAGENDOCKER $DIRSERVICIO/.
        VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

        if [ $VALIDABUILD -gt 0 ] ;  then
                # Si las salida dio ok, voy a pushear la imagen #
                # Pusheo a Experta #
                echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
                docker push $IMAGENDOCKER >> $LOG 2>&1

                SALIDA=1
        else
                SALIDA=0
        fi


}



function construirsdk22 {
	echo "CONFIG STEP: Crear Imagen -- .NET construirsdk22 "

	cp -a $DIRORQUESTADOR/templates/Dockerfile-construirsdk22 $DIRSERVICIO/Dockerfile |tee -a $LOG 
	# Reemplazar KEY-NOMBRES en el Dockerfile #
        ## Tengo que limpiar el caracter de retorno \r o ^M  "CTRL-V" + "CTRL-M" ##
        sed -i s/KEY-APPNAME/$PROYECTONOMBRE/g $DIRSERVICIO/Dockerfile


	DATE=`date +"%Y%m%d%H%M"`
	REGISTRYLOCAL="lal075:8088"
	IMAGENDOCKER=$REGISTRYLOCAL/$SERVICIO:$DATE

	# Build
	cd $DIRSERVICIO
	###docker build --no-cache --build-arg csproj=$SITIO/$CSPROJ --build-arg directorio=$SITIO -t $IMAGENDOCKER $DIRSERVICIO/. | tee -a $LOG
	docker build --no-cache --build-arg csproj=$CSPROJ --build-arg directorio=$SITIO -t $IMAGENDOCKER $DIRSERVICIO/. | tee -a $LOG
	VALIDABUILD=`grep "Successfully built" $LOG |wc -l`

	if [ $VALIDABUILD -gt 0 ] ;  then
		# Si las salida dio ok, voy a pushear la imagen #
		# Pusheo a Experta #
		echo "Subiendo imagen a la registry $IMAGENDOCKER " |tee -a $LOG
		docker push $IMAGENDOCKER >> $LOG 2>&1

		SALIDA=1
	else
		SALIDA=0
	fi

}





#######################
### FIN CREARIMAGEN ###
#######################
	



#####################################
### FUNCION CONFIGURAR CONFIG.YML ###
#####################################
function crearconfig {

###############
## VARIABLES ##
###############
## Se debe agregan patrones con pipes ##
BUSQUEDA="datasource.password|password|Password|MYSQL_PASSWORD|DB_PASSWORD"
ARCHIVO=$DIRSERVICIO/$CONFIGYML
ARCHIVOTMP=$ARCHIVO.temp
NROLINEA=0
FLAGMODIFICACION=0

## echo "Archivo de configuracion: $ARCHIVO"
## echo "Archivo temporal: $ARCHIVOTMP"
## Copio el archivo a un temporal, para leer uno y escribir en el otro ##
cp -a $ARCHIVO $ARCHIVOTMP 

## Configuracion restore de las imagenes ##
while read linea ; do
	((NROLINEA++))
	LINEA=`echo ${linea}`

	## Verifico si la linea esta vacia ##
	if [ ! -z "$LINEA" ] ; then
		DSKEY=`echo $LINEA | egrep -w "$BUSQUEDA"`
		## Verifico si hay una key a buscar ##
		if [ ! -z "$DSKEY" ] ; then
			# SI LA IMAGEN ES .NET CAMBIO como busco la variables #
			#
			if [[ $IMAGENSELECCION == *"NET-CORE"* ]]; then
				VARIABLE=`echo $DSKEY |awk -F";" '{print $2}'| awk -F"=" '{print $2}'| sed 's/^[[:space:]]*//'`
			else
				VARIABLE=`echo $DSKEY | awk -F'[:=]' '{print $2}' | sed 's/^[[:space:]]*//'`
			fi

			echo "Key de busqueda ---> $VARIABLE"
			CLAVE=`/docker/imagenes/scripts/configyml.bash $VARIABLE | sed 's/^[[:space:]]*//'`
			## Consulto si se encontraron coincidencias para modificar el archivo ##
			if [ "$CLAVE" == "66" ] ; then
				echo "CONFIG STEP: No se encontraron coincidencias"
			else
                                ## Sustituyo ##
                                ## Tengo que limpiar el caracter de retorno \r o ^M  "CTRL-V" + "CTRL-M" ##
                                sed -i s/$VARIABLE/$CLAVE/g $ARCHIVO
                                sed -i 's/^M$//' $ARCHIVO
			fi

			# Actualizo el FLAGMODIFICACION porque entro a intentar modificar el YML
			FLAGMODIFICACION=1
		fi
	fi
done <<< "`cat $ARCHIVO.temp`"

	## Si no entro a intentar a modificar em YML, lo informo ##
	if [ $FLAGMODIFICACION -eq 0 ] ; then
		echo "CONFIG STEP: no se encontraron parametros de DataSource"
	fi

	SALIDA=0
}



#########################################
### FIN FUNCION CONFIGURAR CONFIG.YML ###
#########################################




#################################
### FUNCION LEVANTAR SERVICIO ###
#################################
function levantarservicio {
	if [ $NUEVO = "SI" ] ; then
	# Si es nuevo, busco puerto y modifica el startHA.bash. Pero si el dir existe hago otra cosa #
		if [ $DIREXISTE = "YES" ] ; then
			PUERTO=`grep publish $DIRSERVICIO/startHA.bash | sed s/"--publish"//g |awk -F":" '{print $1}' |head -1`
			PHC=`grep publish $DIRSERVICIO/startHA.bash | sed s/"--publish"//g |awk -F":" '{print $1}' |tail -1`
			echo "Puerto del startHA.bash: $PUERTO" |tee -a $LOG

			## Verificar si los puertos fueron tomados anteriormente, mucha mala suerte ##
			VALIDAPUERTOUSO=`netstat -natd |egrep "LISTEN" |grep -i $PUERTO`
			if [ ! -z "$VALIDAPUERTOUSO" ] ; then # Si no esta en uso
				echo "Puertos utilizados anteriormente, reemplazando puertos" |tee -a $LOG
				# Si el puerto esta en uso, sale buscapuerto #
				PUERTONUEVO=`$DIRORQUESTADOR/busca-puerto.bash`
				PHCNUEVO=$(($PUERTO + 1000))
				sed -i s/$PUERTO/$PUERTONUEVO/g $DIRSERVICIO/startHA.bash 
				sed -i s/$PHC/$PHCNUEVO/g $DIRSERVICIO/startHA.bash 
				PUERTO=$PUERTONUEVO
				PHC=$PHCNUEVO
			fi
		else
			echo "Se va a levantar un nuevo servicio $SERVICIO..."
			PUERTO=`$DIRORQUESTADOR/busca-puerto.bash`
			PHC=$(($PUERTO + 1000))
			echo "puerto: $PUERTO"
			sed -i s/PUERTOSERV/$PUERTO/g $DIRSERVICIO/startHA.bash 
			sed -i s/PUERTOHC/$PHC/g $DIRSERVICIO/startHA.bash 
		fi

	else
		## Si el servicio esta en ejecucion, lo tengo que matar y levantar el los puertos actuales de configuracion
		echo "Deteniendo el servicio actual..." | tee -a $LOG
		docker service rm $SERVICIO | tee -a $LOG
		sleep 1
		sed -i s/PUERTOSERV/$PUERTO/g $DIRSERVICIO/startHA.bash 
		PUERTO=`grep publish $DIRSERVICIO/startHA.bash | sed s/"--publish"//g |awk -F":" '{print $1}' |head -1`
		PHC=`grep publish $DIRSERVICIO/startHA.bash | sed s/"--publish"//g |awk -F":" '{print $1}' |tail -1`
	fi		

	## Si la imagen es Python, tengo que modificar ademas otros parametros de startHA ##
	if [ $IMAGENSELECCION = "Python-3.6" ] ; then
		sed -i "s%DIRECTORIO%$SITIO%g" $DIRSERVICIO/startHA.bash
		## TEMPENV=̣`$CONFIGYML"  ## Le tengo que quitar el directorio de SITIO
		sed -i "s%ENVDIR%$CONFIGYML%g" $DIRSERVICIO/startHA.bash
	fi
	
	## Si la imagen es Python, tengo que modificar ademas otros parametros de startHA ##
	if [ $IMAGENSELECCION = "Python-Flask" ] ; then
		sed -i "s%DIRECTORIO%$SITIO%g" $DIRSERVICIO/startHA.bash
	fi

	## Si la imagen es Python, tengo que modificar ademas otros parametros de startHA ##
	if [ $IMAGENSELECCION = "Redis" ] ; then
		sed -i "s%DIRECTORIO%$SITIO%g" $DIRSERVICIO/startHA.bash
	fi
	sleep 2
	# Levanto el servicio
	echo "$DIRSERVICIO/startHA.bash $SERVICIO $IMAGENDOCKER"
	$DIRSERVICIO/startHA.bash $SERVICIO $IMAGENDOCKER | tee -a $LOG

	PLIMP=`echo $PUERTO | sed 's/^[[:space:]]*//'`
	PHCLIMP=`echo $PHC | sed 's/^[[:space:]]*//'`
		
	echo ""
	echo "#---------------------------------------------------------#"
	echo "Servicio levantado en :   	   			" 
	echo "+ `docker service ps $SERVICIO | awk '{print $4 "      " $6}'`"
	echo ""
	echo "+ Servicio: http://cluster-test.art.com:$PLIMP"
	echo "+ Health Check: http://cluster-test.art.com:$PHCLIMP	"
	echo "#---------------------------------------------------------#"

}

#########################
# FIN LEVANTAR SERVICIO #
#########################






## MAIN ##

# Mientras el número de argumentos NO SEA 0
while [ $# -ne 0 ]
do
    case "$1" in
    --servicio)
        NOMBRESERVICIO="$2"
        ;;
    --jar)
        JAR="$2"
        ;;
    --config)
        CONFIGYML="$2"
        ;;
    --dependencias)
        DEPENDENCIAS="$2"
        ;;
    --imagen)
        IMAGENSELECCION="$2"
        ;;
    --ejecucion)
	RUN="$2"
	;;
    --sitio)
	SITIO="$2"
	;;
    --csproj)
	CSPROJ="$2"
	;;
    --proyecto-nombre)
	PROYECTONOMBRE="$2"
	;;	
    esac
    shift
done

DIRSERVICIO=$DIRTRABAJO/$NOMBRESERVICIO

#echo "nombre del servicio: $NOMBRESERVICIO"
#echo "jar $JAR"
#echo "config $CONFIGYML"
#echo "Imagen seleccion $IMAGENSELECCION"
#echo "ejecucion $RUN"
#echo "dependencias $DEPENDENCIAS"



## Depurando logs ##
echo "Depuracion `date`" > $LOG


## Verificar ##
verificar
if [ ! $SALIDA ] ;
then
	echo "Error en verificacion"
	exit 10
fi

## Si recibo un archivo de configuracion, entro a configurarlo ##
if [ -z "$CONFIGYML" ]
then
	echo "ATENCION! -- Proyecto sin archivo de configuracion --" |tee -a $LOG
else
	crearconfig	
	if [ ! $SALIDA ] ;
	then
		echo "Error al crear la configuracion"
		exit 12
	fi
fi

# Crear Imagen #
crearimagen
if [ ! $SALIDA ] ;
then
	echo "Error al crear imagen"
	exit 13
fi


# Levantar Servicio #
levantarservicio
exit 0
