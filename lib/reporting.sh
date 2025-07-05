#!/usr/bin/env bash

#set -x #echo on

#####################################################################################
## Reporting composition and objects processing is handled by this script
## All Reporting structures are parsed and formatted by this script

#####################################################################################

## Declare Constants

seperator=\|
seperator_query_rep_doublePipes=__

#Operations Names
OP_NAME_VACUUM_LASTEXECUTED=vacuum_lastExecuted
OP_NAME_ANALYZE_LASTEXECUTED=analyze_lastExecuted
OP_NAME_VACUUM_ISRUNNING=vacuum_isRunning
OP_NAME_VACUUM_SETTINGS=vacuum_settings
OP_NAME_VACUUM_SETTINGS_TABLES=vacuum_settings_tables
OP_NAME_VACUUM_TOTALRUN=vacuum_total_run
OP_NAME_ANALYZE_TOTALRUN=analyze_total_run
OP_NAME_DEAD_TUPLES_EXISTS=dead_tuple_exists
OP_NAME_VACUUM_ELIGIBLE_TABLES=vacuum_eligible_tables
OP_NAME_DB_OBJECTS_SIZE=db_objects_size
OP_NAME_LARGE_TABLES_NOT_VACUUMED=large_tables_not_vacuumed
OP_NAME_PERFORM_MANUAL_VACUUM_TABLE=vacuum_manual_table
OP_NAME_PERFORM_MANUAL_ANALYZE_TABLE=analyze_manual_table
OP_NAME_PERFORM_MANUAL_ANALYZE_FULL=analyze_manual_full
OP_NAME_PERFORM_MANUAL_REINDEX_TABLE=reindex_manual_table
OP_NAME_BLOCKED_SESSIONS=blocked_sessions
OP_NAME_TOP_SLOW_QUERIES=top_slowest_queries

#SQL Results Header columns
TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_TABLE=relname
TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_LASTRUN=last_vacuum
TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_LASTRUN_AUTO=last_autovacuum
TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_TABLE=relname
TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_LASTRUN=last_analyze
TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_LASTRUN_AUTO=last_autoanalyze
TUPLE_HEAD_COL_VACUUM_ISRUNNING_TABLE=table
TUPLE_HEAD_COL_VACUUM_ISRUNNING_DBNAME=dbname
TUPLE_HEAD_COL_VACUUM_ISRUNNING_PID=pid
TUPLE_HEAD_COL_VACUUM_ISRUNNING_STATE=state
TUPLE_HEAD_COL_VACUUM_ISRUNNING_WAITEVENT=wait_event
TUPLE_HEAD_COL_VACUUM_ISRUNNING_RUNNINGSINCE=running_since
TUPLE_HEAD_COL_VACUUM_ISRUNNING_QUERY=query
TUPLE_HEAD_COL_VACUUM_SETTINGS_NAME=name
TUPLE_HEAD_COL_VACUUM_SETTINGS_SETTING=setting
TUPLE_HEAD_COL_VACUUM_SETTINGS_UNIT=unit
TUPLE_HEAD_COL_VACUUM_SETTINGS_CATEGORY=category
TUPLE_HEAD_COL_VACUUM_SETTINGS_SHORTDESC=short_desc
TUPLE_HEAD_COL_VACUUM_SETTINGS_VARTYPE=vartype
TUPLE_HEAD_COL_VACUUM_SETTINGS_MINVAL=min_val
TUPLE_HEAD_COL_VACUUM_SETTINGS_MAXVAL=max_val
TUPLE_HEAD_COL_VACUUM_SETTINGS_TABLES_TABLE=relname
TUPLE_HEAD_COL_VACUUM_SETTINGS_TABLES_OPTIONS=reloptions
TUPLE_HEAD_COL_VACUUM_TOTALRUN_TABLE=relname
TUPLE_HEAD_COL_VACUUM_TOTALRUN_COUNT=vacuum_count
TUPLE_HEAD_COL_VACUUM_TOTALRUN_COUNT_AUTO=autovacuum_count
TUPLE_HEAD_COL_ANALYZE_TOTALRUN_TABLE=relname
TUPLE_HEAD_COL_ANALYZE_TOTALRUN_COUNT=analyze_count
TUPLE_HEAD_COL_ANALYZE_TOTALRUN_COUNT_AUTO=autoanalyze_count
TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_TABLE=relname
TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_DEADCOUNT=n_dead_tup
TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_THRESHOLD=vacuum_threshold
TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_LIVERECORDS=reltuples
TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_ISVACUUMREQ=is_vacuum_req
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TABLE=relation
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TABLESIZE=table_size
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TXNIDAGE=xid_age
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_FREEZE_MAXAGE=autovacuum_freeze_max_age
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_THRESHOLD=autovacuum_vacuum_tuples
TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_DEADCOUNT=dead_tuples
TUPLE_HEAD_COL_DB_OBJ_SIZES_TABLE=relname
TUPLE_HEAD_COL_DB_OBJ_SIZES_TOTALSIZE=total_size
TUPLE_HEAD_COL_DB_OBJ_SIZES_OBJSIZE=obj_size
TUPLE_HEAD_COL_DB_OBJ_SIZES_EXTSIZE=external_size
TUPLE_HEAD_COL_DB_OBJ_SIZES_OBJTYPE=obj_type
TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_TABLE=relname
TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_SIZE=size
TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_LASTRUN=last_vacuum
TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_LASTRUNAUTO=last_autovacuum
TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_CURRTIME=curr_time
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_PID=blocked_pid
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_USER=blocked_user
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_DURATION=blocked_duration
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_STMT=blocked_statement
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_PID=blocking_pid
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_USER=blocking_user
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_DURATION=blocking_duration
TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_STMT=blocking_statement
TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_QUERY=query
TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_TOTAL_EXECTIME=exec_duration
TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_ROWS=rows

#Header Columns Seqs
vacuum_tableNameIdx=
vacuum_lastrunIdx=
vacuum_lastrunAutoIdx=
analyze_tableNameIdx=
analyze_lastrunIdx=
analyze_lastrunAutoIdx=
vacuum_dbNameIdx=
vacuum_pidIdx=
vacuum_stateIdx=
vacuum_waitEventIdx=
vacuum_runningSinceIdx=
vacuum_queryIdx=
vacuum_setting_nameIdx=
vacuum_setting_settingIdx=
vacuum_setting_unitIdx=
vacuum_setting_categoryIdx=
vacuum_setting_short_descIdx=
vacuum_setting_vartypeIdx=
vacuum_setting_min_valIdx=
vacuum_setting_max_valIdx=
vacuum_setting_tables_relnameIdx=
vacuum_setting_tables_reloptionsIdx=
vacuum_totalRunIdx=
vacuum_totalRunAutoIdx=
analyze_totalRunIdx=
analyze_totalRunAutoIdx=
dead_tuples_tableNameIdx=
dead_tuples_deadCountIdx=
dead_tuples_thresholdIdx=
dead_tuples_liveTuplesIdx=
dead_tuples_isVacuumReqIdx=
vacuum_eligible_tables_tableNameIdx=
vacuum_eligible_tables_tableSizeIdx=
vacuum_eligible_tables_txnIdAgeIdx=
vacuum_eligible_tables_freezeMaxAgeIdx=
vacuum_eligible_tables_thresholdIdx=
vacuum_eligible_tables_deadCountIdx=
db_objects_size_tableNameIdx=
db_objects_size_totalSizeIdx=
db_objects_size_objSizeIdx=
db_objects_size_extSizeIdx=
db_objects_size_objTypeIdx=
large_tables_not_vacuumed_tableNameIdx=
large_tables_not_vacuumed_tableSizeIdx=
large_tables_not_vacuumed_lastrunIdx=
large_tables_not_vacuumed_lastrunAutoIdx=
large_tables_not_vacuumed_currTimeIdx=
blocked_sessions_blockedPidIdx=
blocked_sessions_blockedUserIdx=
blocked_sessions_blockedDurationIdx=
blocked_sessions_blockedStmtIdx=
blocked_sessions_blockingPidIdx=
blocked_sessions_blockingUserIdx=
blocked_sessions_blockingDurationIdx=
blocked_sessions_blockingStmtIdx=
top_slowest_queries_queryIdx=
top_slowest_queries_totalExecTimeIdx=
top_slowest_queries_rowsIdx=

# Array Declarations
#Indexed Array for storing statistical data for all RDS Instances
declare -a dbStatsConsResultsArray=()


## Process the results into composite objects
process_results(){
    currDir=$1
    outputFile=$currDir'/'$2
    OP_NAME=$3
    dbPerfDataArrayCtr=$4

    # echo $outputFile"--"$OP_NAME"--"$dbPerfDataArrayCtr


    totalLines=$(wc -l < ${outputFile})
    lineCtr=1
    
    dbStatsConsResultsArray=()
    recordsCount=0
    queryCons=

    while IFS= read -r TUPLE
    do
        if [ -n "${TUPLE}" ] && [ $lineCtr -lt $totalLines ]; then  # Last line contains total rows, skip that line

            # Parse Header Row into array
            if [ $lineCtr -eq 1 ]; then

                IFS='|' read -a colsArray <<< "$TUPLE"
                # echo -e "\n-> Total Columns in Header Row: "${#colsArray[@]} >&2

                for colIdx in "${!colsArray[@]}"
                do
                    case "${OP_NAME}" in
                        ${OP_NAME_VACUUM_LASTEXECUTED})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_TABLE}" ]]; then
                                vacuum_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_LASTRUN}" ]]; then
                                vacuum_lastrunIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_LASTEXECUTED_LASTRUN_AUTO}" ]]; then
                                vacuum_lastrunAutoIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_ANALYZE_LASTEXECUTED})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_TABLE}" ]]; then
                                analyze_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_LASTRUN}" ]]; then
                                analyze_lastrunIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_LASTEXECUTED_LASTRUN_AUTO}" ]]; then
                                analyze_lastrunAutoIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_VACUUM_ISRUNNING})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_TABLE}" ]]; then
                                vacuum_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_DBNAME}" ]]; then
                                vacuum_dbNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_PID}" ]]; then
                                vacuum_pidIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_STATE}" ]]; then
                                vacuum_stateIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_WAITEVENT}" ]]; then
                                vacuum_waitEventIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_RUNNINGSINCE}" ]]; then
                                vacuum_runningSinceIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ISRUNNING_QUERY}" ]]; then
                                vacuum_queryIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_VACUUM_SETTINGS})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_NAME}" ]]; then
                                vacuum_setting_nameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_SETTING}" ]]; then
                                vacuum_setting_settingIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_UNIT}" ]]; then
                                vacuum_setting_unitIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_CATEGORY}" ]]; then
                                vacuum_setting_categoryIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_SHORTDESC}" ]]; then
                                vacuum_setting_short_descIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_VARTYPE}" ]]; then
                                vacuum_setting_vartypeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_MINVAL}" ]]; then
                                vacuum_setting_min_valIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_MAXVAL}" ]]; then
                                vacuum_setting_max_valIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_VACUUM_SETTINGS_TABLES})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_TABLES_TABLE}" ]]; then
                                vacuum_setting_tables_relnameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_SETTINGS_TABLES_OPTIONS}" ]]; then
                                vacuum_setting_tables_reloptionsIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_VACUUM_TOTALRUN})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_TOTALRUN_TABLE}" ]]; then
                                vacuum_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_TOTALRUN_COUNT}" ]]; then
                                vacuum_totalRunIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_TOTALRUN_COUNT_AUTO}" ]]; then
                                vacuum_totalRunAutoIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_ANALYZE_TOTALRUN})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_TOTALRUN_TABLE}" ]]; then
                                analyze_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_TOTALRUN_COUNT}" ]]; then
                                analyze_totalRunIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_ANALYZE_TOTALRUN_COUNT_AUTO}" ]]; then
                                analyze_totalRunAutoIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_DEAD_TUPLES_EXISTS})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_TABLE}" ]]; then
                                dead_tuples_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_DEADCOUNT}" ]]; then
                                dead_tuples_deadCountIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_THRESHOLD}" ]]; then
                                dead_tuples_thresholdIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_LIVERECORDS}" ]]; then
                                dead_tuples_liveTuplesIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DEAD_TUPLES_EXIST_ISVACUUMREQ}" ]]; then
                                dead_tuples_isVacuumReqIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_VACUUM_ELIGIBLE_TABLES})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TABLE}" ]]; then
                                vacuum_elig_tables_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TABLESIZE}" ]]; then
                                vacuum_elig_tables_deadCountIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_TXNIDAGE}" ]]; then
                                vacuum_elig_tables_txnIdAge=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_FREEZE_MAXAGE}" ]]; then
                                vacuum_elig_tables_freezeMaxAge=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_THRESHOLD}" ]]; then
                                vacuum_elig_tables_thresholdIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_VACUUM_ELIGIBLE_TABLES_DEADCOUNT}" ]]; then
                                vacuum_elig_tables_deadCountIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_DB_OBJECTS_SIZE})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DB_OBJ_SIZES_TABLE}" ]]; then
                                db_objects_size_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DB_OBJ_SIZES_TOTALSIZE}" ]]; then
                                db_objects_size_totalSizeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DB_OBJ_SIZES_OBJSIZE}" ]]; then
                                db_objects_size_objSizeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DB_OBJ_SIZES_EXTSIZE}" ]]; then
                                db_objects_size_extSizeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_DB_OBJ_SIZES_OBJTYPE}" ]]; then
                                db_objects_size_objTypeIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_LARGE_TABLES_NOT_VACUUMED})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_TABLE}" ]]; then
                                large_tables_not_vacuumed_tableNameIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_SIZE}" ]]; then
                                large_tables_not_vacuumed_tableSizeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_LASTRUN}" ]]; then
                                large_tables_not_vacuumed_lastrunIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_LASTRUNAUTO}" ]]; then
                                large_tables_not_vacuumed_lastrunAutoIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_LARGE_TABLES_NOT_VACUUMED_CURRTIME}" ]]; then
                                large_tables_not_vacuumed_currTimeIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_BLOCKED_SESSIONS})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_PID}" ]]; then
                                blocked_sessions_blockedPidIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_USER}" ]]; then
                                blocked_sessions_blockedUserIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_DURATION}" ]]; then
                                blocked_sessions_blockedDurationIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKED_STMT}" ]]; then
                                blocked_sessions_blockedStmtIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_PID}" ]]; then
                                blocked_sessions_blockingPidIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_USER}" ]]; then
                                blocked_sessions_blockingUserIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_DURATION}" ]]; then
                                blocked_sessions_blockingDurationIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_BLOCKED_SESSIONS_BLOCKING_STMT}" ]]; then
                                blocked_sessions_blockingStmtIdx=${colIdx}
                            fi
                            ;;

                        ${OP_NAME_TOP_SLOW_QUERIES})  
                            if [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_QUERY}" ]]; then
                                top_slowest_queries_queryIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_TOTAL_EXECTIME}" ]]; then
                                top_slowest_queries_totalExecTimeIdx=${colIdx}
                            elif [[ "${colsArray[$colIdx]}" = "${TUPLE_HEAD_COL_TOP_SLOWEST_QUERIES_ROWS}" ]]; then
                                top_slowest_queries_rowsIdx=${colIdx}
                            fi
                            ;;
 
                        *)  echo -e "ERROR: Invalid option '${OP_NAME}' has been passed (while parsing header row), please check it again. \n" >&2
                            exit 1
                            ;;

                    esac
                done
            # Parse Result Rows
            else
                # Replace double pipes in query statement with substitute character(s) to prevent splitting line based on single pipe
                TUPLE=$(echo "$TUPLE" | sed -e 's/ || / '${seperator_query_rep_doublePipes}' /g')
                IFS='|' read -a dataArray <<< "$TUPLE"

                case "${OP_NAME}" in
                    ${OP_NAME_VACUUM_LASTEXECUTED})  
                        tableName=${dataArray[$vacuum_tableNameIdx]}
                        lastRun=${dataArray[$vacuum_lastrunIdx]}
                        lastRunAuto=${dataArray[$vacuum_lastrunAutoIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${lastRun}${seperator}${lastRunAuto}"
                        ;;

                    ${OP_NAME_ANALYZE_LASTEXECUTED})  
                        tableName=${dataArray[$analyze_tableNameIdx]}
                        lastRun=${dataArray[$analyze_lastrunIdx]}
                        lastRunAuto=${dataArray[$analyze_lastrunAutoIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${lastRun}${seperator}${lastRunAuto}"
                        ;;

                    ${OP_NAME_VACUUM_ISRUNNING})  
                        tableName=${dataArray[$vacuum_tableNameIdx]}
                        dbName=${dataArray[$vacuum_dbNameIdx]}
                        pid=${dataArray[$vacuum_pidIdx]}
                        state=${dataArray[$vacuum_stateIdx]}
                        waitEvent=${dataArray[$vacuum_waitEventIdx]}
                        runningSince=${dataArray[$vacuum_runningSinceIdx]}
                        query=${dataArray[$vacuum_queryIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${dbName}${seperator}${pid}${seperator}${state}${seperator}${waitEvent}${seperator}${runningSince}${seperator}${query}"
                        ;;

                    ${OP_NAME_VACUUM_SETTINGS})  
                        name=${dataArray[$vacuum_setting_nameIdx]}
                        setting=${dataArray[$vacuum_setting_settingIdx]}
                        unit=${dataArray[$vacuum_setting_unitIdx]}
                        category=${dataArray[$vacuum_setting_categoryIdx]}
                        shortDesc=${dataArray[$vacuum_setting_short_descIdx]}
                        varType=${dataArray[$vacuum_setting_vartypeIdx]}
                        minValue=${dataArray[$vacuum_setting_min_valIdx]}
                        maxValue=${dataArray[$vacuum_setting_max_valIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${name}${seperator}${setting}${seperator}${unit}${seperator}${category}${seperator}${shortDesc}${seperator}${varType}${seperator}${minValue}${seperator}${maxValue}"
                        ;;

                    ${OP_NAME_VACUUM_SETTINGS_TABLES})  
                        tableName=${dataArray[$vacuum_setting_tables_relnameIdx]}
                        options=${dataArray[$vacuum_setting_tables_reloptionsIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${options}"
                        ;;

                    ${OP_NAME_VACUUM_TOTALRUN})  
                        tableName=${dataArray[$vacuum_tableNameIdx]}
                        totalRun=${dataArray[$vacuum_totalRunIdx]}
                        totalRunAuto=${dataArray[$vacuum_totalRunAutoIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${totalRun}${seperator}${totalRunAuto}"
                        ;;

                    ${OP_NAME_ANALYZE_TOTALRUN})  
                        tableName=${dataArray[$analyze_tableNameIdx]}
                        totalRun=${dataArray[$analyze_totalRunIdx]}
                        totalRunAuto=${dataArray[$analyze_totalRunAutoIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${totalRun}${seperator}${totalRunAuto}"
                        ;;

                    ${OP_NAME_DEAD_TUPLES_EXISTS})  
                        tableName=${dataArray[$dead_tuples_tableNameIdx]}
                        deadCount=${dataArray[$dead_tuples_deadCountIdx]}
                        threshold=${dataArray[$dead_tuples_thresholdIdx]}
                        liveTuples=${dataArray[$dead_tuples_liveTuplesIdx]}
                        isVacuumReq=${dataArray[$dead_tuples_isVacuumReqIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${deadCount}${seperator}${threshold}${seperator}${liveTuples}${seperator}${isVacuumReq}"
                        ;;

                    ${OP_NAME_VACUUM_ELIGIBLE_TABLES})  
                        tableName=${dataArray[$vacuum_eligible_tables_tableNameIdx]}
                        tableSize=${dataArray[$vacuum_eligible_tables_tableSizeIdx]}
                        txnIdAge=${dataArray[$vacuum_eligible_tables_txnIdAgeIdx]}
                        freezeMaxAge=${dataArray[$vacuum_eligible_tables_freezeMaxAgeIdx]}
                        threshold=${dataArray[$vacuum_eligible_tables_thresholdIdx]}
                        deadCount=${dataArray[$vacuum_eligible_tables_deadCountIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${tableSize}${seperator}${txnIdAge}${seperator}${freezeMaxAge}${seperator}${threshold}${seperator}${deadCount}"
                        ;;

                    ${OP_NAME_DB_OBJECTS_SIZE})  
                        tableName=${dataArray[$db_objects_size_tableNameIdx]}
                        objSize=${dataArray[$db_objects_size_objSizeIdx]}
                        extSize=${dataArray[$db_objects_size_extSizeIdx]}
                        totalSize=${dataArray[$db_objects_size_totalSizeIdx]}
                        objType=${dataArray[$db_objects_size_objTypeIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${objSize}${seperator}${extSize}${seperator}${totalSize}${seperator}${objType}"
                        ;;

                    ${OP_NAME_LARGE_TABLES_NOT_VACUUMED})  
                        tableName=${dataArray[$large_tables_not_vacuumed_tableNameIdx]}
                        objSize=${dataArray[$large_tables_not_vacuumed_tableSizeIdx]}
                        lastRun=${dataArray[$large_tables_not_vacuumed_lastrunIdx]}
                        lastRunAuto=${dataArray[$large_tables_not_vacuumed_lastrunAutoIdx]}
                        currTime=${dataArray[$large_tables_not_vacuumed_currTimeIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${tableName}${seperator}${objSize}${seperator}${lastRun}${seperator}${lastRunAuto}${seperator}${currTime}"
                        ;;

                    ${OP_NAME_BLOCKED_SESSIONS})  
                        blockedPid=${dataArray[$blocked_sessions_blockedPidIdx]}
                        blockedUser=${dataArray[$blocked_sessions_blockedUserIdx]}
                        blockedDuration=${dataArray[$blocked_sessions_blockedDurationIdx]}
                        blockedStmt=${dataArray[$blocked_sessions_blockedStmtIdx]}
                        blockingPid=${dataArray[$blocked_sessions_blockingPidIdx]}
                        blockingUser=${dataArray[$blocked_sessions_blockingUserIdx]}
                        blockingDuration=${dataArray[$blocked_sessions_blockingDurationIdx]}
                        blockingStmt=${dataArray[$blocked_sessions_blockingStmtIdx]}
                        dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${blockedPid}${seperator}${blockedUser}${seperator}${blockedDuration}${seperator}${blockedStmt}${seperator}${blockingPid}${seperator}${blockingUser}${seperator}${blockingDuration}${seperator}${blockingStmt}"
                        ;;

                    ${OP_NAME_TOP_SLOW_QUERIES})  
                        query="${dataArray[$top_slowest_queries_queryIdx]}"
                        queryCons=${queryCons}${query}
                        totalExecTime=${dataArray[$top_slowest_queries_totalExecTimeIdx]}
                        rows=${dataArray[$top_slowest_queries_rowsIdx]}
                        if [ -n "${totalExecTime}" ]; then
                            dbStatsConsResultsArray[${dbPerfDataArrayCtr}]="${queryCons}${seperator}${totalExecTime}${seperator}${rows}"
                            queryCons=
                        fi
                        
                        ;;

                    *)  echo -e "ERROR: Invalid option '${OP_NAME}' has been passed (while traversing records), please check it again. \n" >&2
                        ;;

                esac

                ((recordsCount++))
                ((dbPerfDataArrayCtr++))
            fi
        fi

        ((lineCtr++))
    done < ${outputFile}

    # For debugging purpose
    # declare -p dbStatsConsResultsArray >&2

    # Set other values
    echo $recordsCount > "$currDir/.dataRecordsCount"
    echo $dbPerfDataArrayCtr > "$currDir/.dbPerfDataArrayCtr"

    # Return the array
    arrayToVar="$( declare -p dbStatsConsResultsArray )"
    # Preserve whitspaces in array fields 
    IFS=$'\v'
    echo "${arrayToVar#*=}"

    # Restore IFS its default value: <space><tab><newline>
    IFS=' '$'\t'$'\n'
}

generate_output_report(){
    eval declare -a dbStatsConsResultsArray="$( echo "$1" )"
    # Restore IFS its default value: <space><tab><newline>
    IFS=' '$'\t'$'\n'

    dbOptimOptResults=$2
    OP_NAME=$3
    RUN_OPTIM_OPT=$4
    dbOptimOptScriptLog=$5
    noRecords=

    if [ ${RUN_OPTIM_OPT} = true ]; then 
        dbName=$(echo $dbOptimOptResults | cut -d "${array_rds_seperator}" -f1)
        dbOptimOptResults=$(echo $dbOptimOptResults | cut -d "${array_rds_seperator}" -f2)

        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

        echo -e "${high}Script Execution Log                                           ${high}${reset}"
        echo -e "${high}------------------------------------------------------------------${high}${reset}"
        echo -e "$dbOptimOptScriptLog"
        echo -e "\n${high}Script Execution Results                                       ${high}${reset}"
        echo -e "${high}------------------------------------------------------------------${high}${reset}"
        echo -e "$dbOptimOptResults"

        case "${OP_NAME}" in
            ${OP_NAME_PERFORM_MANUAL_VACUUM_TABLE})  
                # Reserve space for later
                ;;

            ${OP_NAME_PERFORM_MANUAL_ANALYZE_TABLE})  
                # Reserve space for later
                ;;

            ${OP_NAME_PERFORM_MANUAL_ANALYZE_FULL})  
                # Reserve space for later
                ;;

            ${OP_NAME_PERFORM_MANUAL_REINDEX_TABLE})  
                # Reserve space for later
                ;;

            *)  echo -e "ERROR: Invalid option '${OP_NAME}' has been passed (for Run Optim Opt), please check it again. \n" >&2
                ;;

        esac

    else
        # For debugging purpose
        # declare -p dbStatsConsResultsArray >&2

        dbStatsConsResultsArrayLength=${#dbStatsConsResultsArray[@]}
        reportRowsCtr=

        for dbStatsArrIdx in "${!dbStatsConsResultsArray[@]}"
        do
            value=${dbStatsConsResultsArray[$dbStatsArrIdx]}
            

            case "${OP_NAME}" in
                ${OP_NAME_VACUUM_LASTEXECUTED})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Vacuum Last Executed' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                          |   Last Vacuum                      |   Last Auto-Vacuum              ${high}${reset}"
                            echo -e "${high}  -----|----------------------------------------------------|------------------------------------|---------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        lastVacuum=$(echo $value | cut -d "${seperator}" -f2)
                        lastAutoVacuum=$(echo $value | cut -d "${seperator}" -f3)
                        printf '    %-3s |     %-45s |   %-32s |   %-32s\n' "$ctr" "$tableName" "$lastVacuum" "$lastAutoVacuum"
                    fi
                    ;;

                ${OP_NAME_ANALYZE_LASTEXECUTED})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Analyze Last Executed' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                          |   Last Analyze                      |   Last Auto-Analyze              ${high}${reset}"
                            echo -e "${high}  -----|----------------------------------------------------|------------------------------------|---------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        lastAnalyze=$(echo $value | cut -d "${seperator}" -f2)
                        lastAutoAnalyze=$(echo $value | cut -d "${seperator}" -f3)
                        printf '    %-3s |     %-45s |   %-32s |   %-32s\n' "$ctr" "$tableName" "$lastAnalyze" "$lastAutoAnalyze"
                    fi
                    ;;

                ${OP_NAME_VACUUM_ISRUNNING}) 
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${noteCol}INFO: No Records are found for 'If Vacuum is still running' details for Database '${dbName}', it can be concluded that Vacumm process is NOT running. ${noteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                         |   PID         |   State            |   Wait Event          |   Running Since      |   Query                                                       ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|---------------|--------------------|-----------------------|----------------------|---------------------------------------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        pid=$(echo $value | cut -d "${seperator}" -f2)
                        state=$(echo $value | cut -d "${seperator}" -f3)
                        waitEvent=$(echo $value | cut -d "${seperator}" -f4)
                        runningSince=$(echo $value | cut -d "${seperator}" -f5)
                        query=$(echo $value | cut -d "${seperator}" -f6)
                        printf '    %-3s |     %-45s |   %-18s |   %-18s |   %-18s |   %-32s |   %-60s\n' "$ctr" "$tableName" "$pid" "$state" "$waitEvent" "$runningSince" "$query"
                    fi
                    ;;

                ${OP_NAME_VACUUM_SETTINGS})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Vacuum Settings (At DB Level)' details for Database '${dbName}', either due to permission issue program is not able to retrieve details from system tables or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Setting                                |   Value        |   Unit |   Type     |   Min Value  |   Max Value  |   Description                                  ${high}${reset}"
                            echo -e "${high}  -----|--------------------------------------------|----------------|--------|------------|--------------|--------------|------------------------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        name=$(echo $value | cut -d "${seperator}" -f1)
                        setting=$(echo $value | cut -d "${seperator}" -f2)
                        unit=$(echo $value | cut -d "${seperator}" -f3)
                        category=$(echo $value | cut -d "${seperator}" -f4)
                        desc=$(echo $value | cut -d "${seperator}" -f5)
                        varType=$(echo $value | cut -d "${seperator}" -f6)
                        minValue=$(echo $value | cut -d "${seperator}" -f7)
                        maxValue=$(echo $value | cut -d "${seperator}" -f8)
                        printf '   %-3s |     %-38s |   %-12s |   %-4s |   %-8s |   %-10s |   %-10s |   %-45s\n' "$ctr" "$name" "$setting" "$unit" "$varType" "$minValue" "$maxValue" "$desc"
                    fi
                    ;;

                ${OP_NAME_VACUUM_SETTINGS_TABLES})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Vacuum Settings (At Tables Level)' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                         |   Settings                             ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|----------------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                            echo -e "If 'Settings' column in the report shows empty value for any table (or for all table), it means no settings have been configured explicitly."
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        settings=$(echo $value | cut -d "${seperator}" -f2)
                        printf '    %-3s |    %-45s |   %-45s\n' "$ctr" "$tableName" "$settings"
                    fi
                    ;;

                ${OP_NAME_VACUUM_TOTALRUN})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Vacuum Total Times Run' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                         |   Total Run Count [Manual]         |   Total Run Count [Auto]        ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|------------------------------------|---------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        totalRun=$(echo $value | cut -d "${seperator}" -f2)
                        totalRunAuto=$(echo $value | cut -d "${seperator}" -f3)
                        printf '   %-3s |     %-45s |   %-32s |   %-32s\n' "$ctr" "$tableName" "$totalRun" "$totalRunAuto"
                    fi
                    ;;

                ${OP_NAME_ANALYZE_TOTALRUN})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Analyze Total Times Run' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |     Table                                         |   Total Run Count [Manual]         |   Total Run Count [Auto]        ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|------------------------------------|---------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        totalRun=$(echo $value | cut -d "${seperator}" -f2)
                        totalRunAuto=$(echo $value | cut -d "${seperator}" -f3)
                        printf '   %-3s |     %-45s |   %-32s |   %-32s\n' "$ctr" "$tableName" "$totalRun" "$totalRunAuto"
                    fi
                    ;;

                ${OP_NAME_DEAD_TUPLES_EXISTS})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'Dead Tuples Exists' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Table                                           |   Dead Tuples |   Threshold |   Live Tuples |   Is Vacuum Req. ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|---------------|-------------|---------------|------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                            echo -e "'Threshold' column in the report indicates that vacuum will run when the dead tuples exceeds the vacuum threshold since the last VACUUM"
                            echo -e "If 'Live Tuples' column shows -1 it indicates the table has never yet been vacuumed or analyzed, and the row count is unknown.\n"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        deadCount=$(echo $value | cut -d "${seperator}" -f2)
                        threshold=$(echo $value | cut -d "${seperator}" -f3)
                        liveTuples=$(echo $value | cut -d "${seperator}" -f4)
                        isVacuumReq=$(echo $value | cut -d "${seperator}" -f5)
                        if [ "${isVacuumReq}" = "f" ]; then isVacuumReq=no; else isVacuumReq=yes; fi;
                        printf '   %-3s |     %-45s |   %-11s |   %-10.5s |   %-10.5s |   %-10.5s\n' "$ctr" "$tableName" "$deadCount" "$threshold" "$liveTuples" "$isVacuumReq"
                    fi
                    ;;

                ${OP_NAME_VACUUM_ELIGIBLE_TABLES})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${noteCol}INFO: No Records are found for 'Currently Eligible Tables for Vacuum' details for Database '${dbName}', it can be concluded that no tables needs Vacuumization at present. ${noteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Table                                           |   Table Size  |   Age (Txn Ids)    |   Max Allowed Freeze Age |   Threshold |   Dead Tuples ${high}${reset}"
                            echo -e "${high}  -----|---------------------------------------------------|---------------|--------------------|--------------------------|-------------|---------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                            echo -e "'Age (Txn Ids)' column in the report tracks whether the table needs to be vacuumed in order to prevent transaction ID wraparound \n"
                            echo -e "'Max Allowed Freeze Age' specifies Age at which to autovacuum a table to prevent transaction ID wraparound\n"
                            echo -e "'Threshold' column in the report indicates that vacuum will run when the dead tuples exceeds the vacuum threshold since the last VACUUM"
                            echo -e "_______________________________"
                            echo -e "1. When the age of a database reaches 2 billion transaction IDs, transaction ID (Txn Ids) wraparound occurs and the database becomes read-only. "
                            echo -e "2. if 'autovacuum_freeze_max_age' value is set to 200 million transactions (200,000,000):"
                            echo -e "    ● If a table reaches 500 million unvacuumed transactions, that triggers a low-severity alarm."
                            echo -e "    ● If a table ages to 1 billion, this should be treated as an alarm to take action on."
                            echo -e "    ● If a table reaches 1.5 billion unvacuumed transactions, that triggers a high-severity alarm."
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        tableSize=$(echo $value | cut -d "${seperator}" -f2)
                        txnIdAge=$(echo $value | cut -d "${seperator}" -f3)
                        freezeMaxAge=$(echo $value | cut -d "${seperator}" -f4)
                        threshold=$(echo $value | cut -d "${seperator}" -f5)
                        deadCount=$(echo $value | cut -d "${seperator}" -f6)
                        printf '   %-3s |     %-45s |   %-11s |   %-20s |   %-20s |   %-11s |   %-11s\n' "$ctr" "$tableName" "$tableSize" "$txnIdAge" "$freezeMaxAge" "$threshold" "$deadCount"
                    fi
                    ;;

                ${OP_NAME_DB_OBJECTS_SIZE})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'DB Objects Size' details for Database '${dbName}', either no table exists in this database or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Table                                                               |   Object Size |   External Size |   Total Size |   Obj. Type   ${high}${reset}"
                            echo -e "${high}  -----|-----------------------------------------------------------------------|---------------|-----------------|--------------|---------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                            echo -e "'Total Size' column in the report represents the Size that includes Indexes, stored procedures, etc. used by that object\n"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        objSize=$(echo $value | cut -d "${seperator}" -f2)
                        extSize=$(echo $value | cut -d "${seperator}" -f3)
                        totalSize=$(echo $value | cut -d "${seperator}" -f4)
                        objType=$(echo $value | cut -d "${seperator}" -f5)
                        if [ "${isVacuumReq}" = "f" ]; then isVacuumReq=no; else isVacuumReq=yes; fi;
                        printf '   %-3s |     %-65s |   %-11s |   %-13s |   %-10.5s |   %-11s\n' "$ctr" "$tableName" "$objSize" "$extSize" "$totalSize" "$objType"
                    fi
                    ;;

                ${OP_NAME_LARGE_TABLES_NOT_VACUUMED})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${noteCol}INFO: No Records are found for 'largest tables not vacuumed' details for Database '${dbName}', it can be concluded that no such tables exists which are not vacuumed as per the searching criteria. ${noteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Table                                              |   Table Size |   Last Vacuum                  |   Last Auto-Vacuum             |   Current Time                 ${high}${reset}"
                            echo -e "${high}  -----|------------------------------------------------------|--------------|--------------------------------|--------------------------------|--------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        tableName=$(echo $value | cut -d "${seperator}" -f1)
                        tableSize=$(echo $value | cut -d "${seperator}" -f2)
                        lastVacuum=$(echo $value | cut -d "${seperator}" -f3)
                        lastAutoVacuum=$(echo $value | cut -d "${seperator}" -f4)
                        currTime=$(echo $value | cut -d "${seperator}" -f5)
                        printf '   %-3s |    %-50s |   %-10.5s |   %-28s |   %-28s |   %-28s \n' "$ctr" "$tableName" "$tableSize" "$lastVacuum" "$lastAutoVacuum" "$currTime"
                    fi
                    ;;

                ${OP_NAME_BLOCKED_SESSIONS})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${noteCol}INFO: No Records are found for 'blocked sessions' details for Database '${dbName}', it can be concluded that no blocked sessions exists as per the searching criteria. ${noteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Blocked Pid  |   Blocked User    |   Blocked Duration                 |   Blocked Statement                                    |   Blocking Pid  |   Blocking User    |   Blocking Duration                 |   Blocking Statement                                    ${high}${reset}"
                            echo -e "${high}  -----|-------------|-------------------|------------------------------------|--------------------------------------------------------|-----------------|--------------------|-------------------------------------|---------------------------------------------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        blockedPid=$(echo $value | cut -d "${seperator}" -f1)
                        blockedUser=$(echo $value | cut -d "${seperator}" -f2)
                        blockedDuration=$(echo $value | cut -d "${seperator}" -f3)
                        blockedStmt=$(echo $value | cut -d "${seperator}" -f4)
                        blockingPid=$(echo $value | cut -d "${seperator}" -f5)
                        blockingUser=$(echo $value | cut -d "${seperator}" -f6)
                        blockingDuration=$(echo $value | cut -d "${seperator}" -f7)
                        blockingStmt=$(echo $value | cut -d "${seperator}" -f8)
                        printf '   %-3s |   %-10.5s |   %-15s |   %-28s |   %-45s |   %-10.5s |   %-15s |   %-28s |   %-45s \n' "$ctr" "$blockedPid" "$blockedUser" "$blockedDuration" "$blockedStmt" "$blockingPid" "$blockingUser" "$blockingDuration" "$blockingStmt"
                    fi
                    ;;

                ${OP_NAME_TOP_SLOW_QUERIES})  
                    if echo $value | grep -q "\\${array_rds_seperator}"; then
                        # Get Database Name and records count
                        dbName=$(echo $value | cut -d "${array_rds_seperator}" -f1)
                        recordsCount=$(echo $value | cut -d "${array_rds_seperator}" -f2)
                        reportRowsCtr=0

                        echo -e "\n${noteCol}${high} Database Name: ${dbName}${high}${noteCol}${reset}\n"

                        if [ ${recordsCount} -eq 0 ]; then
                            noRecords=true
                            echo -e "\n${high}${blueBgCol}${whiteCol}INFO: No Records are found for 'top slowest queries' details for Database '${dbName}', either due to permission issue program is not able to retrieve details from system tables or some problem could have been occured. ${whiteCol}${reset}\n"
                        else
                            noRecords=false
                            echo -e "${high}    #  |   Query                                                                                                     |    Total Duration (ms)     |    Total Records  ${high}${reset}"
                            echo -e "${high}  -----|-------------------------------------------------------------------------------------------------------------|----------------------------|-------------------${high}${reset}"
                        fi

                    elif echo $value | grep -q "End"; then
                        if [ ${noRecords} = false ]; then
                            echo -e "_______________________________"
                            echo -e "'Total Duration' column in the report represents Total time spent executing the query."
                            echo -e "'Total Records' column in the report represents how many rows are retrieved or affected by the query. \n"
                        fi
                    else
                        # Display Results
                        ctr=${reportRowsCtr}
                        query=$(echo $value | cut -d "${seperator}" -f1)
                        query=$(echo "$query" | sed -e 's/ '${seperator_query_rep_doublePipes}' / \|| /g')
                        query=$(echo "$query" | sed -e 's/ \\\* / * /g')
                        totalExecTime=$(echo $value | cut -d "${seperator}" -f2)
                        rows=$(echo $value | cut -d "${seperator}" -f3)
                        printf '   %-3s |   %-105s |   %-24s |   %-18s \n' "$ctr" "$query" "$totalExecTime" "$rows"
                    fi
                    ;;

                *)  echo -e "ERROR: Invalid option '${OP_NAME}' has been passed (while generating text output), please check it again. \n" >&2
                    ;;

            esac

            reportRowsCtr=$(($reportRowsCtr+1))

        done
    fi

}
