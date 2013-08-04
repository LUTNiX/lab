#! /bin/bash

# Colors constants
NONE="$(tput sgr0)"
RED="\n$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="\n$(tput setaf 3)"
BLUE="\n$(tput setaf 4)"

# File constants
LUTNIX_DIR=${HOME}/backgrounds_lutnix
IMAGE_169=${LUTNIX_DIR}/Wall-LUTNiX2_v2-16:9.png
IMAGE_43=${LUTNIX_DIR}/Wall-LUTNiX2_v2-4:3.png
NEW_IMAGE_FILE=Wall-LUTNiX2_v2_auto.png
LOGFILE="${PWD}/convert.log"

# Config constants
SOURCE_IMAGE=${IMAGE_169}
horizontal_max=530
vertical=+164
font_const=Liberation-Mono-Regular
xdpyinfo_cmd=$(which xdpyinfo)
label=$(whoami | awk '{print $1}')'@'$(uname -n)':/#'
font_pix_length=12
gravity='South'

if [ -e ./lab.cfg ]
then 
    . ./lab.cfg
fi

# Set some other config constants after sourcing config file.
NEW_IMAGE=${LUTNIX_DIR}/${NEW_IMAGE_FILE}
let label_length=${#label}*${font_pix_length}
let horizontal=${horizontal_max}-${label_length}

function message {
    # $1 : Message
    # $2 : Color
    # return : Message colorized

    echo -e "${2}${1}${NONE}"
}

########################################
#-- INICIO CONFIGURACIÓN DE ARCHIVOS --#
########################################
function configure_files {
    if ! [ -d ${LUTNIX_DIR} ]
    then
        if mkdir -p ${LUTNIX_DIR}
        then
            message "Se crea directorio: ${LUTNIX_DIR}" ${BLUE}
        else
            message "ERROR! No se pudo crear ${LUTNIX_DIR}" ${RED}
            return 4
        fi
    fi
    if ! [ -e ${IMAGE_169} ]
    then
        if cp ./Wall-LUTNiX2_v2-16:9.png ${IMAGE_169}
        then
            message "Se copia plantilla: ${IMAGE_169}" ${BLUE}
        else 
            message "ERROR! No se pudo crear plantilla: ${IMAGE_169}" ${RED}
            return 5
        fi
    fi
    if ! [ -e $IMAGE_43 ]
    then
        if cp ./Wall-LUTNiX2_v2-16:9.png ${IMAGE_43}
        then
            message "Se copia plantilla: ${IMAGE_43}" ${BLUE}
        else 
            message "ERROR! No se pudo crear plantilla: ${IMAGE_43}" ${RED}
            return 5
        fi
    fi
}

#####################################
#-- OBTENGO ENTORNO DE ESCRITORIO --#
#####################################
function get_de {
    case $(pgrep -u ${USER} -xl "gnome-session|ksmserver|lxsession|mate-session|xfce4-session" | awk /[0-9]/'{print $2}') in
        'gnome-session')
	        gnome_version=$(gnome-session --version|grep -Eo '[0-9]{1}'|head -1)
    	    if [ ${gnome_version} -ge 3 ]
	        then
                if [ `gsettings get org.gnome.desktop.background picture-options` != "'stretched'" ]
                then
                    gsettings set org.gnome.desktop.background picture-options "stretched"
                fi
	            DE_COMMAND="gsettings set org.gnome.desktop.background picture-uri file:///${NEW_IMAGE}"
                DE_INFO="GNOME3: se selecciona 'gsettings'"
                return 0
    	    else
	        	DE_COMMAND="gconftool --type str --set /desktop/gnome/background/picture_image ${NEW_IMAGE}"
                DE_INFO="GNOME2: se selecciona 'gconftool'"
                return 0
    	    fi
        ;;
        'ksmserver')
            message "Nada para hacer en KDE4. Abortando..." ${RED}
            exit 2 
        ;;
        'lxsession')
            pcmanfm --wallpaper-mode=stretch
            DE_COMMAND="pcmanfm -w $NEW_IMAGE"
            DE_INFO="LXDE: se selecciona 'pcmanfm'"
            return 0
        ;;
        'mate-session')
            DE_COMMAND="mateconftool-2 -t string -s /desktop/mate/background/picture_filename ${NEW_IMAGE}"
            DE_INFO="MATE2: se selecciona 'mateconftool-2'"
            return 0
        ;;
        'xfce4-session')
            if [ `xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show` != 'true' ]
            then
                xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -s true
            fi
            DE_COMMAND="xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s ${NEW_IMAGE}"
            DE_INFO="XFCE 4.10: se selecciona 'xfconf-query'"
            return 0
        ;;
    esac
}

#########################################
#-- ESTABLEZCO RESOLUCIÓN DE PANTALLA --#
#########################################
function resolution_config {
    if [ -n "${xdpyinfo_cmd}" ];
    then
        current_resolution=$(${xdpyinfo_cmd}|awk --posix '/dimensions:[[:space:]]+[0-9]{2,4}x[0-9]{2,4}/''{print $2}')
    fi

    case ${current_resolution} in
        '1024x768'|'800x600'|'640x480') 
            vertical=+187
            SOURCE_IMAGE=${IMAGE_43}
            ;;
    esac

    if [ ${horizontal} -ge 0 ]; #si el numero es >= 0 pongo un '+' como prefijo. 
    then
        horizontal=+${horizontal}   
    fi

    message "El entorno de escritorio actual es ${DE_INFO}." ${YELLOW}
    message "La resolución actual es: ${current_resolution}." ${YELLOW}
    message "Tomando imagen de plantilla: ${SOURCE_IMAGE}." ${YELLOW}
    message "Tamaño de etiqueta (en px): ${label_length}." ${YELLOW}
    message "Posición horizontal (en px): ${horizontal}." ${YELLOW}
    message "Posición vertical (en px): ${vertical}." ${YELLOW}
}

########################
#-- CREO FONDO NUEVO --#
########################
function create_new_image {
    local convert_path=$(which convert)
    if [ -x "${convert_path}" ]
    then
        if convert -size 10000x42 xc:none -pointsize 40 -gravity center -font ${font_const} \
            -stroke black -strokewidth 2 -annotate 0 ${label} \
            -background none -shadow 100x3+0+0 +repage \
            -stroke none -fill white -annotate 0 ${label} \
            ${SOURCE_IMAGE} +swap -gravity ${gravity} \
            -geometry ${horizontal}${vertical}\
            -composite ${NEW_IMAGE} >> ${LOGFILE} 2>&1
        then
            return 0
        else
            message -e "ERROR! Hubo problemas al crear la imagen nueva.\nVer ${LOGFILE} para mas informacion." ${RED}
            exit 3
        fi
    else 
        message "Falta paquete ImageMagick o por los menos no existe comando convert. Abortando..." ${RED}
        exit 1
    fi
}

echo -e "\nCreando directorio y archivos de plantilla..."
configure_files
echo -e "\nConfigurando..."
get_de
resolution_config
create_new_image

if [ 0 -eq 0 ]
then
    echo -e "\nEstableciendo Wallpaper, un segundo..."
    ${DE_COMMAND} >> ${LOGFILE}
    cmd_ret=$?
    if [ "${cmd_ret}" -eq 0 ]
    then 
        rm ${LOGFILE}
        message "${NEW_IMAGE} es tu fondo ahora!\n" ${GREEN}
    fi
else
    message "No pudimos establecer tu fondo" ${RED}
    message "Contactate con el grupo informandonos del error a: lutnix@googlegroups.com." ${RED}
    message "O buscanos por la facu!" ${RED}
fi

exit 0
