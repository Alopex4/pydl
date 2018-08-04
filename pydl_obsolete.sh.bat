#!/bin/bash

# Notice: This shell script should be use under the the python http service open
# Python2 http service : $ python SimpleHTTPServer
# Python3 http service : $ python http.server

IP=$1
INDEX_DIR=/tmp
INDEX_FILE="$INDEX_DIR/index.html"
BASE_URL="http://$IP"
PORT="8000"
PS3="Select number[?] > "

usage(){
    echo "Usage: sh $0 IP"
    exit 1
}

url_error_msg(){
    if [ $? -ne 0 ]
    then
        echo "Oops, Something went Wrong, please check your network and PORT nuber(default:8000)"
        exit 2
    fi
}

get_index(){
    sub_dir=$1
    if [ "${#sub_dir}" -eq 0 ]
    then
        if [ "${#new_base_index}" -eq 0 ]
        then
            return_flag='F'
            base_index="$BASE_URL:$PORT/"
            wget  -qc "$base_index" -P $INDEX_DIR
            url_error_msg
        else
            extend_index="$new_base_index"
            index_info_process
        fi
    else
        if [ -z $record_extend_index ]
        then
            extend_index="${base_index}${sub_dir}"
        else
            extend_index="${record_extend_index}${sub_dir}"
        fi
        index_info_process
    fi
}

index_info_process(){
    wget  -qc "$extend_index" -P $INDEX_DIR
    echo "Current browse dir: $extend_index"
    url_error_msg
    #new_base_index=""
    record_extend_index=$extend_index
    get_index_contains
    assign_return_flag
    detect_contains
    select_file
}


assign_return_flag(){
    dir_count=`echo "${dir_title}" | grep -o '/' | grep -c '/' `
    if [ "$dir_count" == '1' ]
    then
        return_flag='F'
    else
        return_flag='T'
    fi
}

get_index_contains(){
    contains=`sed -e 's/<[^>]*>//g' $INDEX_FILE | grep -v "^$" | uniq`
    dir_title=`echo $contains | cut -d ' ' -f1-4`
    download_list=`echo $contains | cut -d ' ' -f5-`
    rm -rf $INDEX_FILE
}

download_list_process(){
    if [ "${#download_list}" -eq 0 ]
    then
        download_list="."
    else 
        if [ "$return_flag" == 'T' ]
        then
            download_list="$download_list ."
            lists_item=`echo ${download_list} | wc -w`
        else
            download_list="$download_list"
            lists_item=`echo ${download_list} | wc -w`
        fi
    fi
}

select_file(){
    download_list_process
    select item in $download_list
    do
       if [ "$REPLY" == 'q' ]
       then 
           echo "Exit the menu."
           exit 0
       elif [[ $REPLY -le 0 || $REPLY -gt ${lists_item} ]]
       then
           echo "Bad option !"
       elif [[ $REPLY =~ [0-9]{1,} ]]
       then
           file_or_dir $item
       fi

    done
}

jump_back_parent(){
    if [ -z $new_base_index ]
    then
        new_base_index="${extend_index%%$sub_dir}"
        base_index="$new_base_index"
        process_index="${new_base_index%/}"
        sub_dir_x=${process_index##h*/}
        sub_dir_x="${sub_dir_x}/"
    else
        echo "sub_dir $sub_dir"
        echo "new_base_index $new_base_index"
        new_base_index="${new_base_index%%$sub_dir_x}"
        echo "x sub_dir $sub_dir_x"
        echo "x new_base_index $new_base_index"
        base_index="$new_base_index"
        process_index="${new_base_index%/}"
        sub_dir_x=${process_index##h*/}
        sub_dir_x="${sub_dir_x}/"
        
    fi
    record_extend_index=""
    get_index
}

detect_contains(){
    if [ -z "$download_list" ]
    then
        echo "This directory is empty."
        echo "Went back to the parent directory."
    fi
}

file_or_dir(){
    item=$1
    echo "$1" | grep -q '/'
    if [ $? -eq 0 ]
    then
        new_base_index=""
        get_index $item
    else
       if [ "$item" == '.' ] 
       then
           jump_back_parent
       else
           new_base_index=""
           download_file $item
       fi
    fi
}

download_info(){
    echo ""
    cat <<EOF
   Y -> Input new dir
   N -> Use current dir
   Q -> Quit download

EOF
    echo "Prepare download: <$pre_download_file>"
    echo "Agree use this direcoty? "
    read -p "(default `pwd`) Y/N/Q:" agree_or_not
    agree_or_not=${agree_or_not:=y}
    agree_or_not=`echo "$agree_or_not" | tr [A-Z] [a-z]`
    if [ "$agree_or_not" == 'n' ]
    then
        agree=T
        read -p "Input the directory: " download_dir
    elif [ "$agree_or_not" == 'q' ]
    then
        agree=F
        return
    else
        agree=T
        download_dir=`pwd`
    fi
}

downloading(){
    confirme=$1
    if [ "$confirme" == 'T' ]
    then
        if [ -n "$extend_index" ]
        then
            wget -qc "${extend_index}${pre_download_file}" -P "$download_dir"
        else
            wget  -qc "${base_index}${pre_download_file}" -P $INDEX_DIR
       fi
    echo
    fi
}

download_file(){
    pre_download_file=$1 
    download_info
    downloading $agree
    if [ "$agree" == 'T' -a $? -eq 0 ]
    then
        echo "$pre_download_file Download Success"
    elif [ "$agree" == 'T' -a $? -ne 0 ]
    then
        echo "$pre_download_file Download Error"
    else
        echo "Cancel download $pre_download_file"
    fi
}

main(){
    if [ $# -ne 1 ]
    then
       usage
    fi
    get_index
    get_index_contains
    select_file 
}

main $*
