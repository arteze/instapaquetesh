#!/bin/sh

function tener_extension(){
	archivo_tener_extension="$1"
	extension_cortada="$(echo $archivo_tener_extension | rev | grep -Po "[^.]+" | head -n -1)"
	echo "$extension_cortada" | while read fila; do
		encuentra=$(echo "$fila" | grep -v "[-_]" | tail -n1)
		if [[ "$encuentra" != "" ]]; then
			echo $encuentra
		else
			break
		fi
	done | rev | echo "$(paste -sd "." | rev )" | while read fila; do
		encuentra=$(echo "$fila" | grep -v "[-_]" | tail -n1)
		if [[ "$encuentra" != "" ]]; then
			echo $encuentra
		else
			break
		fi
	done | echo "$(paste -sd "." | rev )"
}
function tener_carpeta(){
	archivo_tener_carpeta="$1"
	extension="$(tener_extension $archivo_tener_carpeta)"
	echo $archivo_tener_carpeta | rev | cut -c$(($(echo $extension|wc -m)+1))- | rev
}
function pausar(){
	gxmessage -center "Pausado: $1" -title "Pausa"
}
function mostrar_y_correr_comando(){
	echo $1 && $1
}
function instalar_paquete(){
	ruta_original=$(pwd)
	archivo="$(basename $1)"
	extension="$(tener_extension $archivo)"
	carpeta="$(tener_carpeta $archivo)"
	echo "Ruta: $ruta_original"
	echo "Archivo: $archivo"
	echo "Carpeta: $carpeta"
	echo "Extension: $extension"
	umount -v "./desempacado/$carpeta/ram"
	rm -rfv "./desempacado/$carpeta"
	#comando="7z -r -o$carpeta x $archivo"
	#comando="file-roller --service --force -e $carpeta $archivo"
	mkdir "./desempacado"; cd "./desempacado"
	mkdir "./$carpeta"; cd "./$carpeta"
	mkdir "./ram"
	mount -t ramfs "./ram"
	cd "./ram"
	echo "-- Preparando creacion de enlace simbolico --"
	mostrar_y_correr_comando "ln -sv ../../../$archivo ./$archivo"
	echo "-- Enlace simbolico creado --"
	mostrar_y_correr_comando "ar xv ./$archivo"
	ls "./" | grep tar | while read comprimido; do
		carpeta=$(tener_carpeta "$comprimido")
		mkdir "./$carpeta" ; cd "./$carpeta"
		mv -fv "../$comprimido" "./"
		mostrar_y_correr_comando "tar -xvf ./$comprimido"
		rm -fv "./$comprimido"
		cd "../"
	done
	rm -fv "./$archivo"
	mostrar_y_correr_comando "ln -sv ../../$archivo ./$archivo"
	cp -rv "./" "../"
	cd "../"
	umount "./ram"
	rm -r "./ram"
	cd "$ruta_original"
	ls -ro "./"
	echo Archivo: $archivo; echo Carpeta: $carpeta
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
cd $(dirname $archivo)

if [[ $archivo == "" ]];then
	ls "./" | grep "\.deb$" | while read archivo; do
		instalar_paquete $archivo
	done
else
	for archivo in "$@";do
		instalar_paquete $archivo
	done
fi

gxmessage -center "Paquetes instalados." -title "instalado"
