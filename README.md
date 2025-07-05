# Tool to monitor PostgreSQL database performances, collecting statistical data and running Optimization Operations

## Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Usage](#usage)
4. [How It Works](#how-it-works)


## Overview

'Database Performance Monitor' an automated tool to monitor PostgreSQL database performances and performing Optimization Operations. This tool helps in collecting various statistics of DB operations. It makes convenient to understand how tables data is working, vacuum processes, slow queries and other several performances paradigms.

This program is able to collect various statistics of DB operations and performing optimization operations like:

1.  Determine when the Vacuum/Auto-Vacuum process Last Executed
2.  Determine when the Analyze/Auto-Analyze process Last Executed
3.  Determine if the Vacuum process is still running
4.  Get Autovacuum Daemon Configuration Details - Database Level
5.  Get Autovacuum Daemon Configuration Details - Tables Level
6.  Determine how many times Vacuum/Auto-Vacuum process ran
7.  Determine how many times Analyze/Auto-Analyze process ran
8.  Determine if Dead Tuples exists in database
9.  Determine which tables are currently eligible for Vacuum
10. Determine size of tables/objects in the database
11. Find out 10 Largest tables NOT vacuumed in past 1 month
12. Find out Blocked Sessions to retrieve processes that create locks on tables
13. Find out top 10 slowest queries
14. Perform Manual Vacuum [Table basis]
15. Perform Manual Analyze [Table basis]
16. Perform Manual Analyze [Full]
17. Perform Manual ReIndex [Table basis]


Results of all performance statistics are displayed on terminal in text format.

This is a menu based program to display various performance statistical data collection options and optimization operations. First, it displays menu to choose a RDS instance for which performance operations need to be executed and then it shows the operations selection menu.

- All results are produced in structured report in interactive format.

- All configurations are managed at `.conf` file.

- Database connection parameters are inherited from InfraSetup component and no need to maintain them separately.

- Report is displayed directly in the local terminal



## Prerequisites

1. Infra Stack already deployed and running
2. RDS Host Instances are running
3. AWS profile is already set in AWS CLI (aws configure) locally based on the environment (dev, beta, externalQA, uat, staging, prod)
4. jq is installed


## Usage

From the terminal, run following commands:

```
$ cd iac/launchers/dbManagement/dbPerformanceMonitor
$ chmod -R 777 *.sh
$ ./run.sh <env>

Possible values for env: 
- dev / beta / externalQA / uat / staging / prod
```

> *.pem key file is required inorder to send the script files to EC2 instance. Please ensure .pem key file is setup in `.conf` file*


## How it works

1. This program runs certain SQL scripts on each database to retrieve statistical data for all features supported by this tool. These scripts could include procs or functions. Queries have additional conditional logic to filter the records with required information. Output of these records are saved into text files.

2. These SQL scripts are executed via Bastion host since RDS instances reside behind private subnets. Main ‘postgres’ user is used to run SQL scripts.

3. This program sends SQL scripts to Bastion host via SSH using `.pem` key, bastion host in turn, runs these SQL scripts in databases which generates output results in text files.

4. These generated output text files are send back from Bastion host to local terminal

5. Program then parses, processes output results and transforms into composite objects collection

6. These composite objects collection is further formatted into text report objects to create consolidated interactive Report.
