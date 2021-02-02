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
	gxmessage -title "Pausa" -center "Pausado: $1"
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
	mount -t ramfs none "./ram"
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
	cd "./ram"
	mostrar_y_correr_comando "ln -sv ../../../$archivo ./$archivo"
	mostrar_y_correr_comando "ar xv ./$archivo"
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
	if [[ ! -d ./ram ]];then
		rm -rfv ./desmontar.sh
	fi
	cd "$ruta_original"
	echo "Compienzo copia"
	cp -rv "./desempacado/$carpeta/data/"* "/"
	echo "Fin copia"
	ls -Rho "./desempacado/$carpeta"
	echo Archivo: $archivo; echo Carpeta: $carpeta
}

function instalar_todo(){
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
}

instalar_todo "$@"
