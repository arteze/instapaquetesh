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

for archivo in "$@"; do
	instalar_paquete $archivo
done
