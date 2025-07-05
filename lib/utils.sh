#!/usr/bin/env bash

#set -x #echo on

## Declare Constants

seperator=\|

menu_rds_db(){
    appDbNameAndUserCons=$1
    OP_NAME=$2
    rdsInstanceOption=$3

    menuCtr=0
    option=
    rdsAppDatabaseNameCons=

    while [ : ]
    do 
        echo -e "${high}\nSELECT the Database Name for which '${OP_NAME}' operation has to be performed: ${high}${reset}\n" >&2

        ctr=1
        while [ $ctr -lt $resCtr ]
        do 
            # Ensure that DBname should corresponds to correct App's Database
            appDbNameAndUser=$(echo $appDbNameAndUserCons | cut -d "${seperator}" -f ${ctr})   #Format-> RDSInstanceSeq:dbname:dbUser
            rdsAppRDSInstanceSeq=$(echo $appDbNameAndUser | cut -d ":" -f 1)
            rdsAppDatabaseName=$(echo $appDbNameAndUser | cut -d ":" -f 2)

            if [ ${rdsAppRDSInstanceSeq} -eq ${rdsInstanceOption} ]; then

                menuCtr=$(($menuCtr+1)); echo "${menuCtr}. ${high}${rdsAppDatabaseName}${high}${reset} Database" >&2
                rdsAppDatabaseNameCons=${rdsAppDatabaseNameCons}${seperator}${rdsAppDatabaseName}
            fi

            ctr=$(($ctr+1))
        done

        menuCtr=$(($menuCtr+1)); echo "${menuCtr}. Exit" >&2

        echo -n -e "\nEnter your choice [1-${menuCtr}]: " >&2

        read option

        echo >&2

        case "${option}" in

            ${menuCtr})  echo -e "\nProgram will be terminated as requested.\n" >&2
                exit 1;
                
                break
                ;;    

            *)  if [ -z "${option}" ] || [[ "$option" =~ [a-zA-Z] ]] || [ ${option} -gt ${menuCtr} ] || [ ${option} -eq 0 ]
                then
                    echo -e "${errCol}You have selected invalid option. Please chose correct option again: ${errCol}${reset}" >&2
                    menuCtr=0
                    continue
                else
                    echo -e "Selected option: ${option}\n" >&2
                fi

                break
                ;;
        esac
    done

    rdsAppDatabaseNameCons=${rdsAppDatabaseNameCons:${#seperator}}
    selDatabase=$(($option))
    selDatabase=$(echo $rdsAppDatabaseNameCons | cut -d "${seperator}" -f ${selDatabase})

    echo "$selDatabase"
}

user_prompt_notEmpty() {
    input_text=$1
    field_name=$2

    while [ : ]
    do
        read -p "${input_text}" input

        if [ -z "${input}" ] ; then
            echo -e "\n${errCol}${field_name} cannot be empty. Please try again.\n${errCol}${reset}" >&2
            continue
        fi

        break
    done

    echo $input
}