#!/bin/sh

function tener_extension(){
	archivo="$1"
	ruta="$(echo $archivo | rev | grep -Po "[^.]+")"
	echo "$ruta" | while read fila; do
		encuentra=$(echo "$fila" | grep -v "[-_]")
		if [[ "$encuentra" != "" ]]; then
			echo $encuentra
		else
			break
		fi
	done | echo "$(cat | paste -sd "." | rev )"
}
function instalar_paquete(){
	archivo="$1"
	extension="$(tener_extension $archivo)"
	carpeta=$(echo $archivo | rev | cut -c$(($(echo $extension|wc -m)+1))- | rev) 
	echo Carpeta: $carpeta && echo Extension: $extension
	rm -rfv "$carpeta"
	#comando="file-roller --service --force -e $carpeta $archivo"
	comando="7z -r -o$carpeta x $archivo"
	echo $comando && $comando
	ls $carpeta/
	#cp -vr $carpeta /
	echo Archivo: $archivo && echo Carpeta: $carpeta
}
function mensajes(){
	buscar=$1
	echo "$(
		ps -fe |\
		grep sleep |\
		grep -v grep |\
		sed "s/.*00:00:00 sleep inf //" |\
		grep $buscar
	)"
}

archivo="$1"

buscar_abierto="abierto_instalador"
buscar_instalar="instalar"

aleatorio=$(echo "scale=5; $RANDOM/32768*30" | bc )
echo $aleatorio
sleep $(printf '%s\n' $aleatorio)

esta_abierto="$(echo "$(mensajes $buscar_abierto)")"

if [[ "$esta_abierto" != "" ]]; then
	nohup sleep inf $buscar_instalar $archivo &
	sleep 2
else
	pkill sleep
	sleep inf $buscar_abierto &

	for archivo in "$@"; do
		instalar_paquete $archivo
	done

	tiempo=5 && echo "Esperando $tiempo segundos" && sleep $tiempo
	faltan_instalar="$(echo "$(mensajes $buscar_instalar)")"
	echo "$faltan_instalar"
	echo "$faltan_instalar" >> /initrd/mnt/dev_save/descargas/debs/.faltan.log

	echo "$faltan_instalar" | while read fila; do
		paquete=$(echo $fila | cut -d " " -f 2)
		instalar_paquete $paquete
	done
fi

pkill sleep
