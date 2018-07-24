#!/bin/bash

#-------------CopyRight-------------  
#   Name: pydl
#   Version Number: 1.0
#   Type: download assistance
#   Language: bash shell  
#   Date: 2018-7-24
#   Author: Alopex
#   Email: alopex4@163.com
#------------Environment------------  
#   operating system Ubuntu 16.04 xenial
#   Linux 4.15.0-24-generic
#   GNU Bash 4.3
#-----------------------------------  

# Error code
readonly MISS_ARG=-1
readonly OVER_RANGE=-2
readonly UNKNOWN=-3
readonly PORT_ERROR=-4
readonly NETWORK_ERROR=-5
readonly OK=0

# Color code
readonly RED="\e[31m"
readonly GREEN='\e[32m'
readonly BLUE='\e[34m'
readonly DEFAULT="\e[0m"
readonly BOLD="\e[1m"

# Argument
readonly IP="${1}"
readonly t_port="${2}"
readonly PORT="${t_port:-"8000"}"

# Global var
readonly re_ip='^([1-2]?[0-9]{1,2}\.){3}[1-2]?[0-9]{1,2}$'
readonly source_index="http://${IP}:${PORT}/"
readonly temp_dir="/tmp/"
readonly index_page="/tmp/index.html"

# Mutable var
index="http://${IP}:${PORT}/"

Usage(){
    local t_key=${1}
    local key="${t_key:-""}"
    if [ "${key}" == "key_usage" ]
    then
        echo -e " +-------${BLUE}<Key mapping usage>${DEFAULT}-------+ "
        echo -e " ${BOLD}Interactive by follow keys: ${DEFAULT}"
        echo -e " ${BOLD}${GREEN}Q${DEFAULT}(uit): Exit the script."
        echo -e " ${BOLD}${GREEN}P${DEFAULT}(revious) Go to previous directory."
        echo " +---------------------------------+ "
    else
        echo "Usage : $0 <IP> [port]"
        echo -e "port:${RED}8000${DEFAULT}"
        exit ${MISS_ARG}
    fi
}

IP_validity(){
   echo ${IP} | egrep -x ${re_ip} &> /dev/null
   if [ "$?" -ne "0" ]
   then
       echo "IP invalid (Invalid IP: 192.168.1.1)"
       exit ${UNKNOWN}
   fi

   local space_ip=`echo ${IP} | tr '.' ' '` 
   for num in ${space_ip}
   do
        if [ "${num}" -gt "255" ]
        then
            echo "IP invalid (over range)"
            exit ${OVER_RANGE}
        fi
   done
}

PORT_validity(){
   expr ${PORT} + 1 &>/dev/null
   if [  "$?" -ne "0" ]
   then
        echo -e "${RED}Port${DEFAULT} not integer"
        exit ${PORT_ERROR}
   fi

   if [  "${PORT}" -le "1024" -o "${PORT}" -gt 65536 ]
   then
        echo -e "${RED}Port${DEFAULT} out of range"
        exit ${PORT_ERROR}
   fi
}

network_staus(){
    local try_time=3
    while [ "${try_time}" -ne 0 ]
    do
        curl -s -o /dev/null -w "${http_code}" --connect-timeout 2 ${source_index}
        if [ "$?" -eq "0" ]
        then
            break
        else
            sleep 0.7 
            let try_time--
            echo -e "Can't reach the web page."
            exit ${NETWORK_ERROR}
        fi
    done
}

# --------------------------------------
# management function
prepare(){
    IP_validity
    PORT_validity
    network_staus
}
# --------------------------------------

get_contains(){
    local utf_index="${temp_dir}utf.index.html"
    wget -qc ${index} -P ${temp_dir}
    cat ${index_page} | iconv -t UTF-8 > "${utf_index}"
    local contains=`sed -e 's/<[^>]*>//g' ${utf_index} | grep -v "^$" | uniq`
    echo "${contains}"
    :> ${index_page}
    :> ${utf_index}
    rm ${index_page} ${utf_index}
}

show_title(){
    local contains=${1}
    local dir_title=`echo ${contains} | cut -d ' ' -f1-4`
    echo -e "${BOLD}${GREEN}${dir_title} ${DEFAULT}"
}

func_key(){
    local REPLY=${1}
    local REPLY=`echo ${REPLY} | tr [A-Z] [a-z]`
    if [ "${REPLY}" == "q" ]
    then
        exit
    elif [ "${REPLY}" == "p" ]
    then
        if [ "${index}" == "${source_index}" ]
        then
            echo -e "${BOLD}${BLUE}This is root directory.${DEFAULT}"
        else
            local suffix=`echo "${index}" | awk -F '/' '{print $(NF-1)}'`
            local suffix="${suffix}/"
            index="${index%${suffix}}"
            list_choice
        fi
    else
        local key="key_usage"
        Usage ${key}
    fi
}

file_or_dir(){
    local object=${1}
    echo ${object} | grep "/" &> /dev/null
    if [ "$?" -eq '0' ]
    then
        echo "dir"
    else
        echo "file"
    fi
}

download_file(){
    local directory=${1}
    local file=${2}
    local download_dir=`pwd`
    echo -e "Current work directory (${BLUE}${download_dir}${DEFAULT})"
    echo -e "Confirm to download (${BOLD}${BLUE}${file}${DEFAULT}) \c"
    read -p '[Y/n]? ' YN
    local YN=`echo ${YN} | tr '[A-Z]' '[a-z]'`
    if [ "${YN}" == "y" -o "${YN}" == "yes" ]
    then
        echo "Downloading .. "
        wget -qc ${directory}${file} -P ${download_dir}
    else
        echo "Canceling .. "
    fi
    sleep 0.8
    list_choice
}

enter_dir(){
    local directory=${1}
    local sub_dir=${2}
    sleep 0.2
    clear
    index="${directory}${sub_dir}"
    list_choice
}

is_empty_dir(){
    local file_list_amount="${1}"
    if [ "$file_list_amount" -eq "0" ]
    then
        echo -e " This is an ${RED}empty${DEFAULT} directory."
        echo -e " Use ${BOLD}${GREEN}P${DEFAULT} to leave."
        echo 
        local key="key_usage"
        Usage ${key}
    fi
}

list_choice(){
    local contains=`get_contains`
    local file_list=`echo ${contains} | cut -d ' ' -f5-`
    local file_list=(${file_list})
    local file_list_amount=${#file_list[@]}
    local cur_dir=${index}
    local string="Select file/directory [num] "
    local prefix=">>> "
    local PS3="${string} ${prefix}"

    show_title "${contains}"
    is_empty_dir "${file_list_amount}"
    select item in "${file_list[@]}"
    do
        expr ${REPLY} + 1 &>/dev/null
        if [ "$?" -ne "0" ]
        then
            func_key ${REPLY}
        elif [ "${REPLY}" -le "0"  -o "${REPLY}" -gt "${file_list_amount}" ]
        then
            echo "Out of range."
            continue
        else
            item_is=`file_or_dir ${item}`
            if [ "${item_is}" == "file" ]
            then
                download_file ${cur_dir} ${item}
            else
                enter_dir  ${cur_dir} ${item}
            fi
        fi
    done
}

main(){
    local arg_num=$#
    if [ "${arg_num}" -eq "0" ]
    then
        Usage
    else
        prepare
        list_choice
        exit ${OK}
    fi
}

main $*
