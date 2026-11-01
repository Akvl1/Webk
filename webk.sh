#!/bin/bash
#center-echo() {
#  text=$1
#  printf "%*s\n" $(((${#text}+$COLUMNS)/2)) "$text"
#}

highlight='\033[1m'
bluetext='\033[0;34m'
purpletext='\033[0;35m'
resetColor='\033[0m'
illegalchar=[""]

menu_item() {
  if [ $1 -eq $2 ]; then
    echo -e "${highlight}$3 ${resetColor}"
  else
    echo -e "$3"
    fi
}

quit() {
    tput cnorm
    clear
    fastfetch
    exit 0
}

if [ $# -eq 0 ]
  then
    echo "running webk..."
    input=""
    selection=0
    trap quit EXIT INT TERM
    tput civis
    menu=0
    searching=0
    search=""
    search_result=""
    selectionLimit=1
    clear
    running=1
    while [ running ]
    do
        echo "Webk"
        echo "----------------"
        if [ $menu -eq 0 ]; then
          menu_item $selection 0 "Search"
          menu_item $selection 1 "History"
          menu_item $selection 2 "Settings"
          read -rsn1 input

          if [ "$input" == "A" ]; then
            ((selection-=1))
            if [ $selection -eq -1 ]; then
              selection=2
            fi
          elif [ "$input" == "B" ]; then
            ((selection+=1))
            if [ $selection -eq 3 ]; then
              selection=0
            fi
          elif [ "$input" == "C" ]; then
            menu=$((selection+1))
            selection=0
          fi
        elif [ $menu -eq 1 ]; then
          if [ $searching -eq 1 ]; then
            if [ "$search" == "" ]; then
              echo -e "${highlight}Search... $resetColor"
            else
              echo -e "${highlight}$search $resetColor"
            fi
          elif [ "$search" == "" ]; then
            menu_item $selection 0 "Search..."
          else
            menu_item $selection 0 "$search"
          fi

          search_result_ID=1
          echo "$search_result" | jq -c '.[]' | while read -r result; do
            result_title=$(jq --raw-output '.title' <<< "$result")
            result_url=$(jq --raw-output '.url' <<< "$result")
            echo
            if [ $selection -eq $search_result_ID ]; then
              echo -e "${bluetext}${highlight}$result_title $resetColor"
              echo -e "${purpletext}${highlight}$result_url $resetColor"
            else
              echo -e "${bluetext}$result_title $resetColor"
              echo -e "${purpletext}$result_url $resetColor"
            fi
            ((search_result_ID+=1))
          done

          read -rsn1 -N1 input
          if [ $searching -eq 1 ]; then
            if [ "$input" = $'\n' ]; then #new line
              searching=0
              search_result=$(ddgr --np --json $search | jq '.')
              ((selectionLimit=$(echo $search_result | jq 'length')+1))
            elif [[ "$input" = $'\x7f' && "$search" != "" ]]; then #backspace
              search="${search::-1}"
              echo
            elif [[ "$input" != $'\e' ]]; then #escape characthers
              search="${search}${input}"
            fi
          elif [ "$input" == "C" ]; then
            if [ $selection -eq 0 ]; then
              searching=1
            else
              ((selected_item=$selection-1))
              item_selection=$(echo "$search_result" | jq ".[$selected_item]")
              url=$(jq --raw-output '.url' <<< "$item_selection")
              cage -s -- firefox -no-remote --kiosk $url
            fi
          elif [ "$input" == "A" ]; then
            ((selection-=1))
            if [ $selection -eq -1 ]; then
              ((selection=$selectionLimit-1))
            fi
          elif [ "$input" == "B" ]; then
            ((selection+=1))
            if [ $selection -eq $selectionLimit ]; then
              ((selection=0))
            fi
          elif [ "$input" == "D" ]; then
            menu=0
            selection=0
          fi
        fi
        clear
    done
fi
