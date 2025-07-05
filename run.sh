#!/usr/bin/env bash

#set -x #echo on

#############################################################################################
## This script is used for automating the process to monitor PostgreSQL database performances by collecting various statistics of DB operations. 
## This will make convenient to understand how tables data is working, vacuum processes, slow queries and other several performances paradigms.
## All results are produced in structured text format directly in the terminal.
##
## This script executes all commands on Bastion host/EC2 instance with the help of remote shell script. 
##
## This script performs following tasks:
## 1. Run SQL scripts via remote shell script to get the DB Statistical data
## 2. SQL scripts in databases generates output results in text files
## 3. These generated output text files are send back from Bastion host to local terminal
## 4. This Program then parses, processes output results and transforms into composite objects collection
## 5. These composite objects collection is further formatted into text output objects to display on terminal
##  
## !! This script is executed from local terminal. !!
## 
## PREREQUISITES for launching this script:
## 1. IAM User already exists (with full-admin priviligies) that is set in AWS Profile
## 2. AWS profile is already set in AWS CLI (aws configure) locally based on the environment (dev, beta, staging, prod)
## 3. jq exsits
## 
## ~~~~~~~~~~~~~~ USAGE ~~~~~~~~~~~~~~
## $ ./run.sh <env>
##
## Example: ./run.sh dev
## 
## Arguements:
## 1. env - The environment on AWS where the infrastructure will be created
##    Possible Values: dev (For Local Development Testing on AWS)
##                     beta (For Platform Environment on AWS)
##                     externalQA (For QA Testing on AWS)
##                     uat (For UAT Environment on AWS)
##                     staging (For Staging Environment on AWS)
##                     prod (For Production Environment on AWS)
## 
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##
#############################################################################################

curr_dir=
infra_config=
blackCol=`tput setaf 0`
errCol=`tput setaf 1`
succCol=`tput setaf 2`
noteCol=`tput setaf 3`
blueCol=`tput setaf 4`
whiteCol=`tput setaf 7`
greenBgCol=`tput setab 2`
yellowBgCol=`tput setab 3`
blueBgCol=`tput setab 4`
whiteBgCol=`tput setab 7`
ul=`tput smul`
high=`tput bold`
reset=`tput sgr0`

if [ "$#" -lt  "1" ]
then
    echo && echo -e "${errCol}Insufficient Arguements provided${errCol}${reset}" && echo
    echo "Usage:"
    echo "$ ./$(basename $0) <env>" && echo
    echo "env can be dev/beta/staging/prod/externalQA/uat" && echo
    exit 1
fi

# Determine the OS Type
osName="$(uname -s)"
case "${osName}" in
    Linux*)     curr_dir=$( dirname "$(readlink -f -- "$0")" );;
    Darwin*)    curr_dir=$(pwd);;
    *)          curr_dir=$( dirname "$(readlink -f -- "$0")" )
esac

getConfig() {
    echo | grep ^$1$2= $curr_dir/../../.conf | cut -d'=' -f2
}

getInfraEnvConfig() {
    echo | grep ^$1= $infra_config/.env.${env} | cut -d'=' -f2
}

getInfraDefaultEnvConfig(){
    echo | grep ^$1= $infra_config/.env | cut -d'=' -f2
}

getInfraAppConfig(){
    echo | grep ^$1= $infra_config/services/${env}/$2.config | cut -d'=' -f2
}

env=$1
env_upper=$(echo ${env} | tr [:lower:] [:upper:]) #Capitialize env
env_formatted=
infra_config=$curr_dir/../../../infraSetup/envs
isSuccessfull=true
appDbNameAndUserCons=
rdsInstanceNamesCons=
rdsHostSSMParamNamesCons=
rdsPortCons=
rdsMainPasswordSSMParamNameCons=
rdsHostCons=
rdsPasswordCons=
sqlResultsRemoteOutputFileCons=
sqlResultsRunOptimOptRemoteOutputFileCons=
selectedDBNameCons=
selectedDBUserCons=
resCtr=1
rdsCtr=1
dbReportsCtr=1
OP_NAME=
IS_SQLFILE=
RUN_OPTIM_OPT=false
PREQ_REQUIRED=false
selectedDatabase=
EC2_INSTANCE_ID=
EC2_IP=

#Constants
awsCommand=aws
ENV_TYPE_DEV=dev
ENV_TYPE_BETA=beta
ENV_TYPE_STAGING=staging
ENV_TYPE_PROD=prod
ENV_TYPE_CONF=externalQA
ENV_TYPE_CONF=uat
seperator=\|
array_rds_seperator=\^
EOR=EndOfRecords
SQL_RESULTS_REMOTE_OUTPUT_FILE_BASE=dbPerfMonitorResults.txt
SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_BASE=dbPerfMonitorRunOptimOptResults.txt

#Supported Files Location
sqlscript_base=$curr_dir/sqls
shellscript_runPerfMonitor=$curr_dir/remotePerformanceMonitor.sh

# Array Declarations
#Indexed Array for storing statistical data for all RDS Instances
declare -a dbStatsConsResultsArray=()

## Include Constants from Plain SQLs script
. $curr_dir/lib/plainSqls.sh

## Include Reporting functions from script
. $curr_dir/lib/reporting.sh

## Include Utility functions from script
. $curr_dir/lib/utils.sh


if [ "$env" != "$ENV_TYPE_DEV" ] && [ "$env" != "$ENV_TYPE_BETA" ] && [ "$env" != "$ENV_TYPE_STAGING" ] \
    && [ "$env" != "$ENV_TYPE_PROD" ] && [ "$env" != "$ENV_TYPE_CONF" ] && [ "$env" != "$ENV_TYPE_CONF" ]; then
    echo && echo -e "${errCol}Invalid Environment provided, please enter valid Environment: dev/beta/externalQA/uat/staging/prod${errCol}${reset}" && echo
    exit 1
fi

ENV_SHORT=$(echo $env_upper | cut -c 1-4)

if [ "$env" == "$ENV_TYPE_CONF" ] || [ "$env" == "$ENV_TYPE_CONF" ]; then
    env_formatted=${ENV_SHORT}
else
    env_formatted=${env_upper}
fi
env_lower=$(echo ${env_formatted} | tr [:upper:] [:lower:])


## Check if all prerequisties are setup

if [[ $(command -v aws) == "" ]]; then
    echo -e "\n${errCol}AWS CLI not found present in the system. Please install AWS CLI v2 https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html ${errCol}${reset}" && echo
    exit 1;
fi

if ! jq --version > /dev/null 2>&1 
then 
   echo "jq not found installed. Please install it first." && echo
   exit 1
fi


#Get Configured Properties
AWS_PROFILE=$(getConfig 'PROFILE_NAME_' $env_formatted)
PEM_KEY=$(getConfig 'PEM_KEY_LOC_' $env_formatted)
AWS_ACCOUNT_ID=$(getInfraEnvConfig 'AWS_ACCOUNT_ID')
AWS_REGION=$(getInfraEnvConfig 'AWS_REGION')

BASTION_EC2_NAME=$(getInfraEnvConfig 'BASTION_HOST_NAME')

serviceControlConfigPrefix=$(getConfig 'SERVICE_CONFIG_CONTROL_CONFIG')
serviceBackendConfigPrefix=$(getConfig 'SERVICE_CONFIG_CONTROL_CONFIG_BACKEND_PREFIX')
maxServicesCount=$(getInfraAppConfig ${serviceControlConfigPrefix}'.COUNT_MAX_SERVICES' '_control')
maxRDSInstancesCount=$(getInfraEnvConfig 'RDS_COUNT_MAX_INSTANCES')

RDS_MAIN_USER=postgres
BASTION_INSTANCE_USER=ec2-user


echo -e "\n============================================================================================"
echo "Collection of Performance Statistical Data and Running Optimization Operations Started..." 
echo "============================================================================================"

echo
echo "----------------------------------------------------"
echo "AWS Account ID:           $AWS_ACCOUNT_ID" 
echo "AWS Profile:              $AWS_PROFILE"            
echo "AWS Region:               $AWS_REGION"
echo "ENV:                      $env"
echo "----------------------------------------------------"
echo


# Check if .pem key file exists
if [ ! -f ${PEM_KEY} ] && [[ "${PEM_KEY}" != *.pem ]]; then
    echo -e "\n${errCol}ERROR: .pem key file not found or path provided is invalid.${errCol}${reset}"
    echo -e "${errCol}Please ensure that valid .pem key file exists and then try again.\n${errCol}${reset}"
    exit 1
fi


## Collect data for RDS Instances in collections

echo -e "${high}\n=> Collecting RDS Instances data from config files and SSM Params in object collections...\n${high}${reset}"

ctr=1
while [ $ctr -lt $maxServicesCount ] || [ $ctr -eq $maxServicesCount ]
do  
    prefix=$(getInfraAppConfig ${serviceControlConfigPrefix}'.'${serviceBackendConfigPrefix}${ctr} '_control')

    if [[ -n ${prefix} ]]; then
        file=$prefix
        prefix=$(echo ${prefix} | tr [:lower:] [:upper:])
        appDbName=$(getInfraAppConfig ${prefix}'.RDS_DBNAME' ${file})
        appDbUser=$(getInfraAppConfig ${prefix}'.RDS_USERNAME' ${file})
        appRdsInstance=$(getInfraAppConfig ${prefix}'.RDS_INSTANCE' ${file})

        if [[ -n ${appRdsInstance} ]] && ! echo $appDbNameAndUserCons | grep -q :${appDbName}: ; then
            appRdsInstanceSeq=${appRdsInstance: -1} #Extract RDS Count Seq

            appDbNameAndUserCons=${appDbNameAndUserCons}${seperator}${appRdsInstanceSeq}:${appDbName}:${appDbUser}
            resCtr=$(($resCtr+1))
        fi
    fi
    ctr=$(($ctr+1))
done

ctr=1
while [ $ctr -lt $maxRDSInstancesCount ] || [ $ctr -eq $maxRDSInstancesCount ]
do
    rdsInstanceName=$(getInfraEnvConfig 'RDS_INSTANCE_NAME_'${ctr})

    if [[ -n ${rdsInstanceName} ]]; then
        rdsHostSSMParamName=$(getInfraEnvConfig 'RDS_HOST_SSM_PARAM_NAME_'${ctr})
        rdsMainPasswordSSMParamName=$(getInfraEnvConfig 'RDS_PASSWORD_SSM_PARAM_NAME_'${ctr})
        rdsPort=$(getInfraEnvConfig 'RDS_DB_INSTANCE_PORT_'${ctr})

        rdsInstanceNamesCons=${rdsInstanceNamesCons}${seperator}${rdsInstanceName}
        rdsHostSSMParamNameCons=${rdsHostSSMParamNameCons}${seperator}${rdsHostSSMParamName}
        rdsMainPasswordSSMParamNameCons=${rdsMainPasswordSSMParamNameCons}${seperator}${rdsMainPasswordSSMParamName}
        rdsPortCons=${rdsPortCons}${seperator}${rdsPort}

        rdsCtr=$(($rdsCtr+1))
    else
        break;
    fi
    ctr=$(($ctr+1))
done

appDbNameAndUserCons=${appDbNameAndUserCons:${#seperator}}
rdsInstanceNamesCons=${rdsInstanceNamesCons:${#seperator}}
rdsHostSSMParamNameCons=${rdsHostSSMParamNameCons:${#seperator}}
rdsPortCons=${rdsPortCons:${#seperator}}
rdsMainPasswordSSMParamNameCons=${rdsMainPasswordSSMParamNameCons:${#seperator}}


## Retrieve RDS Host and RDS Passwords from SSM Params for all RDS Instances
ctr=1
while [ $ctr -lt $rdsCtr ]
do 
    # Fetch RDS Host Details
    rdsHostSSMParamName=$(echo $rdsHostSSMParamNameCons | cut -d "${seperator}" -f ${ctr})

    $awsCommand ssm get-parameter \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --name ${rdsHostSSMParamName} > temp.json 2>&1 || true

    if cat temp.json | grep -q "error occurred" 
    then
        echo -e "${errCol}ERROR${errCol}${reset} !! SSM Parameter '${rdsHostSSMParamName}' containing RDS Host not found in AWS, this parameter is created by InfraStack during Database creation time.\n"
        exit 1
    else
        rdsHost=$(jq --raw-output '.Parameter.Value' temp.json) || true
        rdsHostCons=${rdsHostCons}${seperator}${rdsHost}
    fi

    # Fetch RDS Password
    rdsMainPasswordSSMParamName=$(echo $rdsMainPasswordSSMParamNameCons | cut -d "${seperator}" -f ${ctr})

    $awsCommand ssm get-parameter \
        --region $AWS_REGION \
        --profile $AWS_PROFILE \
        --name ${rdsMainPasswordSSMParamName} \
        --with-decryption > temp.json 2>&1 || true

    if cat temp.json | grep -q "error occurred" 
    then
        echo -e "${errCol}ERROR${errCol}${reset} !! SSM Parameter '${rdsMainPasswordSSMParamName}' containing RDS Main Password not found in AWS, this parameter is created by InfraStack during Database creation time.\n"
        exit 1
    else
        rdsPassword=$(jq --raw-output '.Parameter.Value' temp.json) || true
        rdsPasswordCons=${rdsPasswordCons}${seperator}${rdsPassword}
    fi

    ctr=$(($ctr+1))
done

rdsHostCons=${rdsHostCons:${#seperator}}
rdsPasswordCons=${rdsPasswordCons:${#seperator}}


## Retrieve Bastion host EC2 details

echo -e "${high}\n=> Retrieving Bastion Host EC2 Details...\n${high}${reset}"

$awsCommand ec2 describe-instances \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --filters "Name=tag-value,Values=${BASTION_EC2_NAME}" > temp.json 2>&1 || true

if ! cat temp.json | grep -q "error occurred" 
then
    EC2_INSTANCE_ID=$(jq --raw-output '.Reservations[0].Instances[0].InstanceId' temp.json) || true
    EC2_IP=$(jq --raw-output '.Reservations[0].Instances[0].PublicIpAddress' temp.json) || true

    if [ "$EC2_INSTANCE_ID" != "" ] && [ "$EC2_INSTANCE_ID" != "null" ] && [ "$EC2_IP" != "" ] && [ "$EC2_IP" != "null" ]
    then
        echo -e "\n${high}EC2 Instance ID: ${EC2_INSTANCE_ID}          EC2 Public IP: ${EC2_IP} ${high}${reset}"
    else
        echo -e "\n${errCol}ERROR: Could not able to fetch Bastion EC2 instance details with the name${errCol}${reset} ${noteCol}${BASTION_EC2_NAME}${noteCol}${reset} ${errCol}, either instance does not exist or in Stop state.${errCol}${reset} \n"
        exit 1
    fi
else 
    echo -e "\n${errCol}ERROR: Bastion EC2 instance with the name${errCol}${reset} ${noteCol}${BASTION_EC2_NAME}${noteCol}${reset} ${errCol} not found existed.${errCol}${reset}\n"
    exit 1
fi
echo


## Menu 1: Generate Menu to for Database Instance Selection

#Configure Menu Options
menuOpt_all=1
menuCtr=0
rdsMenuStart=1
option=

while [ : ]
do 
    echo -e "${high}\n SELECT the Database Instance for which Performance Statistical Data needs to be collected or to run Optimization operations: ${high}${reset}\n";

    ctr=1
    while [ $ctr -lt $rdsCtr ]
    do
        rdsInstanceName=$(echo $rdsInstanceNamesCons | cut -d "${seperator}" -f ${ctr})

        menuCtr=$(($menuCtr+1)); echo "${menuCtr}. ${high}${rdsInstanceName}${high}${reset} RDS Instance"

        ctr=$(($ctr+1))
    done

    menuCtr=$(($menuCtr+1)); echo "${menuCtr}. Exit"

    echo -n -e "\nEnter your choice [1-${menuCtr}]: "

    read option

    echo

    case "${option}" in

        ${menuCtr})  echo -e "Program will be terminated as requested.\n"
            exit 1
            
            break
            ;;    

        *)  if [ -z "${option}" ] || [[ "$option" =~ [a-zA-Z] ]] || [ ${option} -gt ${menuCtr} ] || [ ${option} -eq 0 ]
            then
                echo "${errCol}You have selected invalid option. Please chose correct option again: ${errCol}${reset}"
                menuCtr=0
                continue
            else
                echo -e "Selected option: ${option}\n"
            fi

            break
            ;;
    esac
done

rdsInstanceOption=$(($option))


## Menu 2: Generate Menu for collecting desired statistical data and to run optmization operations

while [ : ]
do 

    echo -e "${high}SELECT THE desired option from the following menu to collect statistical data or to run optimization operation:${high}${reset}\n"
    echo "1.  Determine when the Vacuum/Auto-Vacuum process Last Executed"
    echo "2.  Determine when the Analyze/Auto-Analyze process Last Executed"
    echo "3.  Determine if the Vacuum process is still running"
    echo "4.  Get Autovacuum Daemon Configuration Details - Database Level"
    echo "5.  Get Autovacuum Daemon Configuration Details - Tables Level"
    echo "6.  Determine how many times Vacuum/Auto-Vacuum process ran"
    echo "7.  Determine how many times Analyze/Auto-Analyze process ran"
    echo "8.  Determine if Dead Tuples exists in database"
    echo "9.  Determine which tables are currently eligible for Vacuum"
    echo "10. Determine size of tables/objects in the database"
    echo "11. Find out 10 Largest tables NOT vacuumed in past 1 month"
    echo "12. Find out Blocked Sessions to retreive processes that create locks on tables"
    echo "13. Find out top 10 slowest queries"
    echo "14. Perform Manual Vacuum [Table basis]"
    echo "15. Perform Manual Analyze [Table basis]"
    echo "16. Perform Manual Analyze [Full]"
    echo "17. Perform Manual ReIndex [Table basis]"
    echo "18. Exit"
    echo -n -e "\nEnter your choice [1-18]: "

    read option

    echo

    case "${option}" in
        1)  echo -e "${noteCol}Determining when the Vacuum/Autovacuum process was last executed...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_LASTEXECUTED}
            SQL_SCRIPT=$(get_vacuum_lastExecuted)
            # SQL_SCRIPT=$sqlscript_base\${OP_NAME}.sql
            IS_SQLFILE=false
            break
            ;;

        2)  echo -e "${noteCol}Determining when the Analyze/Auto-Analyze process was last executed...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_ANALYZE_LASTEXECUTED}
            SQL_SCRIPT=$(get_analyze_lastExecuted)
            IS_SQLFILE=false
            break
            ;;

        3)  echo -e "${noteCol}Determining if the Vacuum process is still running...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_ISRUNNING}
            SQL_SCRIPT=$(get_vacuum_isRunning)
            IS_SQLFILE=false
            break
            ;;

        4)  echo -e "${noteCol}Getting Autovacuum Daemon Configuration Details at Database Level...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_SETTINGS}
            SQL_SCRIPT=$(get_vacuum_settings)
            IS_SQLFILE=false
            break
            ;;

        5)  echo -e "${noteCol}Getting Autovacuum Daemon Configuration Details at Tables Level...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_SETTINGS_TABLES}
            SQL_SCRIPT=$(get_vacuum_settings_tables)
            IS_SQLFILE=false
            break
            ;;

        6)  echo -e "${noteCol}Determining how many times Vacuum/Auto-Vacuum process ran...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_TOTALRUN}
            SQL_SCRIPT=$(get_vacuum_totalRun)
            IS_SQLFILE=false
            break
            ;;

        7)  echo -e "${noteCol}Determining how many times Analyze/Auto-Analyze process ran...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_ANALYZE_TOTALRUN}
            SQL_SCRIPT=$(get_analyze_totalRun)
            IS_SQLFILE=false
            break
            ;;

        8)  echo -e "${noteCol}Determining if Dead Tuples exists in database...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_DEAD_TUPLES_EXISTS}
            SQL_SCRIPT=$(get_deadTuples_exists)
            IS_SQLFILE=false
            break
            ;;

        9)  echo -e "${noteCol}Determining which tables are currently eligible for Vacuum...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_VACUUM_ELIGIBLE_TABLES}
            SQL_SCRIPT="$sqlscript_base/${OP_NAME}.sql"
            IS_SQLFILE=true
            break
            ;;

        10) echo -e "${noteCol}Determining size of tables/objects in the database...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_DB_OBJECTS_SIZE}
            SQL_SCRIPT=$(get_db_objects_size)
            IS_SQLFILE=false
            break
            ;;

        11) echo -e "${noteCol}Finding out 10 Largest tables NOT vacuumed in past 1 month...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_LARGE_TABLES_NOT_VACUUMED}
            SQL_SCRIPT=$(get_large_tables_not_vacuumed)
            IS_SQLFILE=false
            break
            ;;

        12) echo -e "${noteCol}Finding out Blocked Sessions to retreive processes that create locks on tables...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_BLOCKED_SESSIONS}
            SQL_SCRIPT="$sqlscript_base/${OP_NAME}.sql"
            IS_SQLFILE=true
            break
            ;;

        13) echo -e "${noteCol}Finding out top 10 slowest queries...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_TOP_SLOW_QUERIES}
            SQL_SCRIPT=$(get_top_slowest_queries)
            PREQ_REQUIRED=true
            SQL_SCRIPT_PRE=$(get_top_slowest_queries_preq)
            IS_SQLFILE=false
            break
            ;;

        14) echo -e "${noteCol}Performing Manual Vacuum [Table basis]...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_PERFORM_MANUAL_VACUUM_TABLE}
            selectedDatabase=$(menu_rds_db ${appDbNameAndUserCons} ${OP_NAME} ${rdsInstanceOption})

            if [ $? -eq 1  ]; then exit; fi;

            table_name=$(user_prompt_notEmpty "Enter the Table name to be Vacuumized: " "Table Name")

            SQL_SCRIPT=$(perform_manual_vacuum_table)
            SQL_SCRIPT=$(echo $SQL_SCRIPT | sed -e 's/\(PG_TABLENAME\)/'${table_name}'/')
            IS_SQLFILE=false
            RUN_OPTIM_OPT=true
            break
            ;;

        15) echo -e "${noteCol}Performing Manual Analyze [Table basis]...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_PERFORM_MANUAL_ANALYZE_TABLE}
            selectedDatabase=$(menu_rds_db ${appDbNameAndUserCons} ${OP_NAME} ${rdsInstanceOption})
            
            if [ $? -eq 1  ]; then exit; fi;

            table_name=$(user_prompt_notEmpty "Enter the Table name to be Analyzed: " "Table Name")

            SQL_SCRIPT=$(perform_manual_analyze_table)
            SQL_SCRIPT=$(echo $SQL_SCRIPT | sed -e 's/\(PG_TABLENAME\)/'${table_name}'/')
            IS_SQLFILE=false
            RUN_OPTIM_OPT=true
            break
            ;;

        16) echo -e "${noteCol}Performing Manual Analyze [Full]...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_PERFORM_MANUAL_ANALYZE_FULL}
            selectedDatabase=$(menu_rds_db ${appDbNameAndUserCons} ${OP_NAME} ${rdsInstanceOption})

            if [ $? -eq 1  ]; then exit; fi;

            echo -e "${noteCol}=> Be cautious! This operation could affect overall database and could take some time... \n${noteCol}${reset}"

            read -p "Please provide your consent to run this operation or press 'n' to abort this operation (y/n): " consent
            
            if [[ "$consent" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                echo -e "${high}\nBased on the user confirmation, Program will attempt to run this operation. This process can take some time...\n${high}${reset}"
            else 
                echo -e "\nProgram will be ${errCol}Aborted${errCol}${reset} as requested and will not try to run this operation.\n"
                exit 1
            fi

            SQL_SCRIPT=$(perform_manual_vacuum_full)
            IS_SQLFILE=false
            RUN_OPTIM_OPT=true
            break
            ;;

        17) echo -e "${noteCol}Performing Manual ReIndex [Table basis]...${noteCol}${reset}\n"
            OP_NAME=${OP_NAME_PERFORM_MANUAL_REINDEX_TABLE}
            selectedDatabase=$(menu_rds_db ${appDbNameAndUserCons} ${OP_NAME} ${rdsInstanceOption})

            if [ $? -eq 1  ]; then exit; fi;

            table_name=$(user_prompt_notEmpty "Enter the Table name to be ReIndexed: " "Table Name")

            SQL_SCRIPT=$(perform_manual_reindex_table)
            SQL_SCRIPT=$(echo $SQL_SCRIPT | sed -e 's/\(PG_TABLENAME\)/'${table_name}'/')
            IS_SQLFILE=false
            RUN_OPTIM_OPT=true
            break
            ;;

        18)  echo -e "Program will be terminated as requested.\n"
            exit 1
            ;;   

        *)  echo -e "You have selected invalid option. Please chose correct option again: \n"
            ;;

    esac

done


## Copy files to Remote Bastion Host

echo -e "${high}\n=> Sending files to Bastion Host Instance ...\n${high}${reset}"

chmod 400 ${PEM_KEY}

sqlScriptTempFile=
if [ ${IS_SQLFILE} = true ]; then
    sqlScriptTempFile=$(echo ${SQL_SCRIPT} | cut -d "." -f1)
    sqlScriptTempFile="$sqlScriptTempFile-temp.sql"

    cp ${SQL_SCRIPT} $sqlScriptTempFile

    scp -i ${PEM_KEY} -o StrictHostKeyChecking=no ${sqlScriptTempFile} ${BASTION_INSTANCE_USER}@${EC2_IP}:/home/${BASTION_INSTANCE_USER}/`basename ${SQL_SCRIPT}`
fi

scp -i ${PEM_KEY} -o StrictHostKeyChecking=no ${shellscript_runPerfMonitor} ${BASTION_INSTANCE_USER}@${EC2_IP}:/home/${BASTION_INSTANCE_USER}/`basename ${shellscript_runPerfMonitor}`
ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'chmod 777 /home/'${BASTION_INSTANCE_USER}'/'`basename ${shellscript_runPerfMonitor}`


## Run SQL & Shell scripts on Bastion Host

echo -e "${high}\n=> Executing Database Performance Monitoring & Optimization Operations on RDS DB Instance (for selected database(s) inside) via Bastion Host Instance...${high}${reset}\n"

#Run Loop for each database
#There could be more then one database on single RDS instance, so set for all databases individually
ctr=1
isRunOpt=true
while [ $ctr -lt $resCtr ]
do 
    # Ensure that DBname should corresponds to correct App's Database
    appDbNameAndUser=$(echo $appDbNameAndUserCons | cut -d "${seperator}" -f ${ctr})   #Format-> RDSInstanceSeq:dbname:dbUser

    rdsAppRDSInstanceSeq=$(echo $appDbNameAndUser | cut -d ":" -f 1)
    rdsAppDatabaseName=$(echo $appDbNameAndUser | cut -d ":" -f 2)
    rdsAppDatabaseUser=$(echo $appDbNameAndUser | cut -d ":" -f 3)

    if [ ${rdsAppRDSInstanceSeq} -eq ${rdsInstanceOption} ]; then

        if [ ${RUN_OPTIM_OPT} = true ]; then 
            if [ "${selectedDatabase}" == "${rdsAppDatabaseName}" ]; then isRunOpt=true; else isRunOpt=false; fi;
        fi

        if [ ${isRunOpt} = true ]; then 

            rdsInstanceName=$(echo $rdsInstanceNamesCons | cut -d "${seperator}" -f ${rdsInstanceOption})
            rdsHost=$(echo $rdsHostCons | cut -d "${seperator}" -f ${rdsInstanceOption})
            rdsPort=$(echo $rdsPortCons | cut -d "${seperator}" -f ${rdsInstanceOption})
            rdsPassword=$(echo $rdsPasswordCons | cut -d "${seperator}" -f ${rdsInstanceOption})

            SQL_RESULTS_REMOTE_OUTPUT_FILE_GENERATED=$(echo ${SQL_RESULTS_REMOTE_OUTPUT_FILE_BASE} | cut -d "." -f1)
            SQL_RESULTS_REMOTE_OUTPUT_FILE_GENERATED="$SQL_RESULTS_REMOTE_OUTPUT_FILE_GENERATED-${rdsInstanceName}-${rdsAppDatabaseName}-${OP_NAME}.txt"
            SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_GENERATED=$(echo ${SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_BASE} | cut -d "." -f1)
            SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_GENERATED="$SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_GENERATED-${rdsInstanceName}-${rdsAppDatabaseName}-${OP_NAME}.txt"

            SQL_COMMANDS=
            if [ ${IS_SQLFILE} = true ]; then
                SQL_COMMANDS=/home/${BASTION_INSTANCE_USER}/`basename ${SQL_SCRIPT}`
            else
                SQL_COMMANDS="${SQL_SCRIPT}"
            fi

            ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} \
                AWS_REGION=${AWS_REGION} \
                RDS_DB_INSTANCE=${rdsInstanceName} RDS_HOST=${rdsHost} RDS_PORT=${rdsPort} \
                RDS_PASSWORD=${rdsPassword} RDS_MAIN_USER=${RDS_MAIN_USER} \
                RDS_DATABASE_NAME=${rdsAppDatabaseName} RDS_DATABASE_APP_USER=${rdsAppDatabaseUser} \
                SQL_COMMANDS=\"${SQL_COMMANDS}\" IS_SQLFILE=${IS_SQLFILE} OP_NAME=${OP_NAME} \
                PREQ_REQUIRED=${PREQ_REQUIRED} SQL_SCRIPT_PRE=\"${SQL_SCRIPT_PRE}\" RUN_OPTIM_OPT=${RUN_OPTIM_OPT} \
                REMOTE_OUTPUT_FILE=/home/${BASTION_INSTANCE_USER}/`basename ${SQL_RESULTS_REMOTE_OUTPUT_FILE_GENERATED}` \
                RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE=/home/${BASTION_INSTANCE_USER}/`basename ${SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_GENERATED}` \
                'sh -s' < ${shellscript_runPerfMonitor}

            if [ $? -gt 0  ]; then
                echo -e "\n${errCol}   ERROR: Command issued to Remote Bastion Host to Execute DB Performance/Optimization Operations on RDS DB Instance '${rdsInstanceName}' failed, please check the logs above.${errCol}${reset}\n"
                exit 1
            else
                sqlResultsRemoteOutputFileCons=${sqlResultsRemoteOutputFileCons}${seperator}${SQL_RESULTS_REMOTE_OUTPUT_FILE_GENERATED}
                sqlResultsRunOptimOptRemoteOutputFileCons=${sqlResultsRunOptimOptRemoteOutputFileCons}${seperator}${SQL_RESULTS_RUN_OPTIM_OPT_REMOTE_OUTPUT_FILE_GENERATED}
                selectedDBNameCons=${selectedDBNameCons}${seperator}${rdsAppDatabaseName}
                selectedDBUserCons=${selectedDBUserCons}${seperator}${rdsAppDatabaseUser}
                dbReportsCtr=$(($dbReportsCtr+1))
            fi
            echo
        fi
    fi

    ctr=$(($ctr+1))
done

sqlResultsRemoteOutputFileCons=${sqlResultsRemoteOutputFileCons:${#seperator}}
sqlResultsRunOptimOptRemoteOutputFileCons=${sqlResultsRunOptimOptRemoteOutputFileCons:${#seperator}}
selectedDBNameCons=${selectedDBNameCons:${#seperator}}
selectedDBUserCons=${selectedDBUserCons:${#seperator}}


## Parse & Process the fetched results generated by the SQL scripts and collect them into composite objects

echo -e "${high}\n=> Parsing and Processing the fetched results generated by the SQL scripts from Bastion host and collecting them into composite objects...${high}${reset}"
echo -e "   This step can take some time, please wait...\n"

dbStatsConsResultsArrayLength=-1
dbOptimOptResults=NA
dbOptimOptScriptLog=NA
selectedRdsInstance=

if [ ${RUN_OPTIM_OPT} = true ]; then
    sqlResultsRemoteOutputFile=$sqlResultsRemoteOutputFileCons
    sqlResultsRunOptimOptRemoteOutputFile=$sqlResultsRunOptimOptRemoteOutputFileCons
    dbName=$selectedDBNameCons

    # Get the text output files from Bastion Host
    scp -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP}:/home/${BASTION_INSTANCE_USER}/`basename ${sqlResultsRemoteOutputFile}` $curr_dir/${sqlResultsRemoteOutputFile}
    scp -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP}:/home/${BASTION_INSTANCE_USER}/`basename ${sqlResultsRunOptimOptRemoteOutputFile}` $curr_dir/${sqlResultsRunOptimOptRemoteOutputFile}

    # Check if Results file is generated and exists in local system and is not empty
    if [ ! -s $curr_dir/${sqlResultsRemoteOutputFile} ]; then
        echo -e "${errCol}   ERROR: Not able to find (or is empty) DB Performance Statistics/Optimization Operations Results output file '${sqlResultsRemoteOutputFile}' in local system for RDS instance '${rdsInstanceName}'. Cannot parse the results. Seems DB Script is failed. ${errCol}${reset}\n"
        exit 1
    fi

    dbOptimOptResults=$(< "$curr_dir/$sqlResultsRemoteOutputFile")
    dbOptimOptResults=${dbName}${array_rds_seperator}${dbOptimOptResults}
    dbOptimOptScriptLog=$(< "$curr_dir/$sqlResultsRunOptimOptRemoteOutputFile")

    selectedRdsInstance=$rdsInstanceName
    rm -rf $curr_dir/${sqlResultsRemoteOutputFile}
    rm -rf $curr_dir/${sqlResultsRunOptimOptRemoteOutputFile}
    if  [ -n "${sqlResultsRemoteOutputFile}" ]; then
        ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'rm -rf /home/'${BASTION_INSTANCE_USER}'/'`basename ${sqlResultsRemoteOutputFile}`
    fi
    if  [ -n "${sqlResultsRunOptimOptRemoteOutputFile}" ]; then
        ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'rm -rf /home/'${BASTION_INSTANCE_USER}'/'`basename ${sqlResultsRunOptimOptRemoteOutputFile}`
    fi

else
    ctr=1
    dbPerfDataArrayCtr=0
    recordsCount=0
    while [ $ctr -lt $dbReportsCtr ]
    do 

        sqlResultsRemoteOutputFile=$(echo $sqlResultsRemoteOutputFileCons | cut -d "${seperator}" -f ${ctr})
        dbName=$(echo $selectedDBNameCons | cut -d "${seperator}" -f ${ctr})
        dbUser=$(echo $selectedDBUserCons | cut -d "${seperator}" -f ${ctr})

        rdsInstanceName=$(echo $rdsInstanceNamesCons | cut -d "${seperator}" -f ${rdsInstanceOption})

        rdsInstanceMarkerInArray=${dbPerfDataArrayCtr}    #Uses as a header element in array records to diffrentiate with other records
        ((dbPerfDataArrayCtr++))

        # Get the text output files from Bastion Host
        scp -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP}:/home/${BASTION_INSTANCE_USER}/`basename ${sqlResultsRemoteOutputFile}` $curr_dir/${sqlResultsRemoteOutputFile}

        # Check if Results file is generated and exists in local system and is not empty
        if [ ! -s $curr_dir/${sqlResultsRemoteOutputFile} ]; then
            echo -e "${errCol}   ERROR: Not able to find (or is empty) DB Performance Statistics/Optimization Operations Results output file '${sqlResultsRemoteOutputFile}' in local system for RDS instance '${rdsInstanceName}'. Cannot parse the results. Seems DB Script is failed. ${errCol}${reset}\n"
            exit 1
        fi

        # Process the results into composite objects
        # Call child script and get the results in array
        eval declare -a dbStatsConsResultsTempArray="$(process_results $curr_dir ${sqlResultsRemoteOutputFile} ${OP_NAME} ${dbPerfDataArrayCtr} ${recordsCount} ${RUN_OPTIM_OPT})"
        dataRecordsCount=$(< "$curr_dir/.dataRecordsCount")
        dbPerfDataArrayCtr=$(< "$curr_dir/.dbPerfDataArrayCtr")

        dbStatsConsResultsArray[$rdsInstanceMarkerInArray]=${dbName}${array_rds_seperator}${dataRecordsCount}
        dbStatsConsResultsArray+=("${dbStatsConsResultsTempArray[@]}")
        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]=${EOR}

        rm -rf $curr_dir/${sqlResultsRemoteOutputFile}
        rm -rf $curr_dir/.dataRecordsCount
        rm -rf $curr_dir/.dbPerfDataArrayCtr
        if  [ -n "${sqlResultsRemoteOutputFile}" ]; then
            ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'rm -rf /home/'${BASTION_INSTANCE_USER}'/'`basename ${sqlResultsRemoteOutputFile}`
        fi

        selectedRdsInstance=$rdsInstanceName
        ctr=$(($ctr+1))
        dbPerfDataArrayCtr=$(($dbPerfDataArrayCtr+1))
        # echo
    done

    # For debugging purpose
    # printf '%s\n' "${dbStatsConsResultsArray[@]}"
    # echo "${dbStatsConsResultsArray[*]}"

    dbStatsConsResultsArrayLength=${#dbStatsConsResultsArray[@]}
    echo -e "\n-> Total Records of Database Performance Operations Results found : ${high}$(($dbStatsConsResultsArrayLength-(($dbReportsCtr-1)*2)))${high}${reset}\n"

fi


## Generate Text output results on console

echo -e "${high}\n=> Generating Text output results...${high}${reset}\n"

if [ ${dbStatsConsResultsArrayLength} -gt 0 ] || [[ -n ${dbOptimOptResults} ]]; then

    echo -e "${blackCol}${whiteBgCol}\n\n Database Performance Statistics/Optimization Operations Results Text Report\n${whiteBgCol}${reset}"

    echo -e "${ul}${high}\n Env:${high}${reset}${ul} ${env}            ${high}AWS Account ID:${high}${reset}${ul} ${AWS_ACCOUNT_ID}            ${high}RDS Instance:${high}${reset}${ul} ${selectedRdsInstance}            ${high}Op Name:${high}${reset}${ul} ${OP_NAME}\n${reset}"

    # Call child script to generate the results in formatted output
    # Send the array to function
    arrayToVar="$( declare -p dbStatsConsResultsArray )"
    # Preserve whitspaces in array fields 
    IFS=$'\v'
    generate_output_report $( echo "${arrayToVar#*=}" ) ${dbOptimOptResults} ${OP_NAME} ${RUN_OPTIM_OPT} ${dbOptimOptScriptLog}
    # Restore IFS its default value: <space><tab><newline>
    IFS=' '$'\t'$'\n'

    isSuccessfull=true

    echo -e "${blackCol}${whiteBgCol}\n End Of Report${whiteBgCol}${reset}"

else
    echo -e "\n\n${errCol}ERROR: No Records are found for DB Performance Statistics/Optimization Operations Results for any database on RDS DB Instance '${selectedRdsInstance}', some problem should have been occured."
    echo -e "No data can be displayed on the screen from any database ${errCol}${reset}"
    isSuccessfull=false
fi


## Clean up files

echo -e "${high}\n\n=> Cleaning up files generated during execution from Bastion Host and Local system...${high}${reset}"

if [ ${IS_SQLFILE} = true ] && [ -n "${SQL_SCRIPT}" ]; then
    ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'rm -rf /home/'${BASTION_INSTANCE_USER}'/'`basename ${SQL_SCRIPT}`
fi
if  [ -n "${shellscript_runPerfMonitor}" ]; then
    ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no ${BASTION_INSTANCE_USER}@${EC2_IP} 'rm -rf /home/'${BASTION_INSTANCE_USER}'/'`basename ${shellscript_runPerfMonitor}`
fi
rm -rf $sqlScriptTempFile
rm -rf temp.json


if [ $? -eq 0  ] && [ ${isSuccessfull} = true ]; then
    echo -e "\n\n=================================================================================================="
    echo -e "Collection of Performance Statistical Data and Running Optimization Operations Finished ${succCol}SUCCESSFULLY${succCol}${reset}. " 
    echo "=================================================================================================="
else
    echo -e "\n!! Collection of Performance Statistical Data and Running Optimization Operations ${errCol}FAILED${errCol}${reset}. !!"
fi

echo
