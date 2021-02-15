#!/bin/sh

function mostrar_instalado_xm(){
	gxmessage -center "Paquetes instalados." -title "instalado"
}
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
	gxmessage -title "Pausa" -center "Pausado: $1"
}
function mostrar_y_correr_comando(){
	echo $1
	resultado="$($1 2>&1)"
	if [[ "$(echo $resultado | grep "command not found")" != "" ||
      "$(echo $resultado | grep "orden no encontrada")" != ""
	]]; then
		gxmessage -center "$resultado
Para solucionarlo, instalar binutils, binutils-multiarch y bash" -title "Error"
		exit
	fi
}
function crear_desmontador(){
	echo "#!/bin/sh

gxmessage -title \"Desmontar\" -center \"

rm -rfv ./ram/*
\$(rm -rfv ./ram/*)

umount -v ./ram
\$(umount -v ./ram)

rm -rvf ./ram
\$(rm -rfv ./ram)

if [[ ! -d ./ram ]];then
	rm -rfv ./desmontar.sh
fi
\$(
	if [[ ! -d ./ram ]];then
		rm -rfv ./desmontar.sh
	fi
)

\"" > ./desmontar.sh
	chmod +x "./desmontar.sh"
}
function borrar_desmontador(){
	if [[ ! -d ./ram ]];then
		rm -rfv ./desmontar.sh
	fi
}
function borrar_lib(){
	cdlib="$(ls $1)"
	if [[ "$cdlib" == "" ]];then
		rm -rfv "$1"
	fi
}
function instalar_paquete(){
	cd "$(dirname $1)"
	if [[ -d ./debs ]]; then
		mv -v ./*.deb ./debs
		cd ./debs
	fi
	ruta_original=$(pwd)
	basename_comando="$(basename 2>&1)"
	if [[ "$(echo $basename_comando | grep dpkg)" != "" ]]; then
		gxmessage -center "$basename_comando
Error al ejecutar basename: Para solucionarlo, reinstalar coreutils" -title "Error"
		exit
	fi
	archivo="$(basename $1 2>&1)"
	if [[ "$(echo $archivo | grep invalid)" != "" ]]; then
		cp -vf "/bin/basename-FULL" "/bin/basename"
		archivo="$(basename $1 2>&1)"
	fi
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
	mount_comando="$(mount 2>&1)"
	if [[ "$(echo $mount_comando | grep dpkg)" != "" ]]; then
		gxmessage -center "$mount_comando
Error al ejecutar mount: Para solucionarlo, reinstalar busybox o mount" -title "Error"
		exit
	fi
	if [[ "$(mount)" == "mount" ]]; then
		cp -vf "/bin/mount-FULL" "/bin/mount"
	fi
	mount -t ramfs none "./ram"
	crear_desmontador
	cd "./ram"
	mostrar_y_correr_comando "ln -sv ../../../$archivo ./$archivo"
	mostrar_y_correr_comando "dpkg-deb -X ./$archivo ./"
	rm -fv "./$archivo"
	mostrar_y_correr_comando "ln -sv ../../$archivo ../$archivo"
	ls "./" | grep tar | while read comprimido; do
		carpeta=$(tener_carpeta "$comprimido")
		mkdir -v "./$carpeta"
		cd "./$carpeta"
		mv -fv "../$comprimido" "./"
		mostrar_y_correr_comando "tar -xvf ./$comprimido"
		rm -fv "./$comprimido"
		cd "../"
		mv -fv "./$carpeta" "../"
		
	done
	mv "./"* "../"
	cd "../"
	umount "./ram"
	rm -r "./ram"
	borrar_desmontador
	echo "Compienzo copia"
	cd "./data"
	mkdir -pv "./lib64"
	mkdir -pv "./usr/lib64"
	mv -vf "./lib/x86_64-linux-gnu/"* "./lib64"
	mv -vf "./usr/lib/x86_64-linux-gnu/"* "./usr/lib64"
	rm -rfv "./lib/x86_64-linux-gnu"
	rm -rfv "./usr/lib/x86_64-linux-gnu"
	borrar_lib "./lib"
	borrar_lib "./usr/lib"
	ls "./"
	cp -rv "./"* "/"
	echo "Fin copia"
	cd "$ruta_original"
	ls -Rho "./desempacado/$carpeta"
	echo Archivo: $archivo; echo Carpeta: $carpeta
}

function instalar_todo(){
	if [[ "$#" == 0 ]];then
		echo "
$(basename $0) .............. Muestra la ayuda
$(basename $0) t ............ Para instalar todo
$(basename $0) archivo.deb .. Para instalar un deb
"
	elif [[ "$#" == 1 && "$1" == "t" ]];then
		ls "./" | grep "\.deb$" | while read archivo; do
			instalar_paquete $archivo
		done
		mostrar_instalado_xm
	else
		for archivo in "$@";do
			instalar_paquete $archivo
		done
		mostrar_instalado_xm
	fi
}

instalar_todo "$@"
