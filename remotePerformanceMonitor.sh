#!/usr/bin/env bash

#set -x #echo on

###################################################################################################
## This script is used to retrieve Performance Statistical data and to run optimization operations.
## Results are saved into local file in bastion host to be parsed later.
##
## !! This script is executed inside bastion host by the parent script . !!
##
###################################################################################################

echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~[Remote Execution]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
echo "Determining Performance Statistical data and Running optimization operations for DB '${RDS_DATABASE_NAME}' from Database Instance '${RDS_DB_INSTANCE}' started inside Bastion Host..."

echo
echo "-------------------------------------"
echo "AWS Region:          ${AWS_REGION}"
echo "RDS DB Instance:     ${RDS_DB_INSTANCE}"
echo "RDS Host:            ${RDS_HOST}"
echo "RDS PORT:            ${RDS_PORT}"
echo "Database Name:       ${RDS_DATABASE_NAME}"
echo "Operation Name:      ${OP_NAME}"
echo "Prerequisites Req.:  ${PREQ_REQUIRED}"
echo "-------------------------------------"
echo


## Update Place Holders in SQL Script
if [ ${IS_SQLFILE} = true ]; then
    sqlScriptTempFile=$(echo ${SQL_COMMANDS} | cut -d "." -f1)
    sqlScriptTempFile="$sqlScriptTempFile-${RDS_DB_INSTANCE}-${RDS_DATABASE_NAME}.sql"

    cp ${SQL_COMMANDS} $sqlScriptTempFile
else
    # Replace escape sequenced '*' chars in SQL commands 
    SQL_COMMANDS="$(echo "$SQL_COMMANDS" | sed -e 's/\\\*/*/g')"
fi

## Execute SQL Script on RDS

export PGPASSWORD=${RDS_PASSWORD}

if [ ${PREQ_REQUIRED} = true ]; then
    psql --host=${RDS_HOST} \
        --port=${RDS_PORT} \
        --username=${RDS_MAIN_USER} \
        --dbname=${RDS_DATABASE_NAME} \
        -a -c "${SQL_SCRIPT_PRE}" > temp.json 2>&1 || true

    sleep 3

    if cat temp.json | grep -q "ERROR"; then
        echo -e " Script Execution Output: "
        echo -e " ------------------------\n "
        cat temp.json && echo
    fi
fi

if [ ${IS_SQLFILE} = true ]; then
    psql --host=${RDS_HOST} \
        --port=${RDS_PORT} \
        --username=${RDS_MAIN_USER} \
        --dbname=${RDS_DATABASE_NAME} \
        -a -f ${sqlScriptTempFile} -A -o ${REMOTE_OUTPUT_FILE} > temp.json 2>&1 || true
else
    psql --host=${RDS_HOST} \
        --port=${RDS_PORT} \
        --username=${RDS_MAIN_USER} \
        --dbname=${RDS_DATABASE_NAME} \
        -a -c "${SQL_COMMANDS}" -A -o ${REMOTE_OUTPUT_FILE} > temp.json 2>&1 || true
fi

sleep 3

if cat temp.json | grep -q "ERROR" || cat temp.json | grep -q "error"; then
    echo -e " Script Execution Output: "
    echo -e " ------------------------\n "
    cat temp.json
fi

if [ -s ${REMOTE_OUTPUT_FILE} ]; then
    sed -i -e 's/ \* / \\\\* /' $REMOTE_OUTPUT_FILE
fi

if [ ${RUN_OPTIM_OPT} = true ]; then
    cp temp.json ${RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE}
fi

if cat temp.json | grep -q "Name or service not known" || cat temp.json | grep -q "could not connect to server"; then
    echo -e "\n=> ERROR !! Failed to run Performance Statistical data and optimization operations for '${RDS_DB_INSTANCE}'"
    echo -e "   It seems Database server is not UP or database Connection details provided are invalid.\n"
elif ! cat temp.json | grep -q "ERROR" && [ -s ${REMOTE_OUTPUT_FILE} ]; then
    echo -e "\n=> Performance Statistical data and optimization operations are executed SUCCESSFULLY for Database Instance '${RDS_DB_INSTANCE}' and output is generated in text file.\n"
else
    echo -e "\n=> ERROR !! Failed to run Performance Statistical data and optimization operations for '${RDS_DB_INSTANCE}'"
    echo -e "   There could be some problem. Please check the SQL Script execution results above.\n"
fi

echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~[END]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"

rm -rf ${sqlScriptTempFile}
rm -rf temp.json

echo
