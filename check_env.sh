#!/bin/bash
#================================================#
## Environmental inspection ##
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

. ./comm_func.lib

function check_drsaas
{
	install_log "INFO" "check drsaas" "Begin to check drsaas app"
	typeset drsaas_flag=0
	typeset user_id=2000
	typeset group_id=2000

	#check user:istorm
	grep -i "${USER_NAME}:x" /etc/passwd > /dev/null
	if [ $? -eq 0 ];then
		install_log "ERROR" "check drsaas" "The user name already exists"
		((drsaas_flag+=1))
	fi

	grep -i "x:${user_id}:" /etc/passwd > /dev/null
	if [ $? -eq 0 ];then
		install_log "ERROR" "check drsaas" "The user id already exists"
		((drsaas_flag+=1))
	fi

	#check group id
	grep -i ":${group_id}:" /etc/group > /dev/null
	if [ $? -eq 0 ];then
		install_log "ERROR" "check drsaas" "The user group id already exists"
		((drsaas_flag+=1))
	fi

	#check HOME dir
	grep -i ":${USER_HOME}:" /etc/passwd > /dev/null
	if [ $? -eq 0 ];then
		install_log "ERROR" "check drsaas" "The user directory already exists"
		((drsaas_flag+=1))
	fi

	#check tomcat、war、jdk
	check_package "drsaas"
	if [ $? -ne 0 ];then
		install_log "ERROR" "check drsaas" "Missing the installation package for the drsaas, please put it under the dir directory and check again"
		((drsaas_flag+=1))
	fi

	if [ $drsaas_flag -gt 0 ];then
		install_log "ERROR" "check drsaas" "Check drsaas app is failed"
		return 1
	else
		install_log "INFO" "check drsaas" "Check drsaas app Successfull"
	fi

	return 0
}

function check_db
{
	install_log "INFO" "check db" "Begin to check mysql db"
	typeset db_flag=0
	typeset db_rpm_list="glibc gcc gcc-c++ openssl perl autoconf"
	typeset db_USER_NAME="mysql"

	#Check mysql need rpm
	for rpm_name in ${db_rpm_list}
	do
		grep -wi "${rpm_name}" rpm_list > /dev/null
		if [ $? -ne 0 ];then
			install_log "INFO" "check db" "This RPM ${rpm_name} package is not installed"
			yum install ${rpm_name} -y >> ${LOG_FILE}
            if [ $? -ne 0 ];then
                install_log "ERROR" "check db" "This RPM ${rpm_name} install is failed"
                ((db_flag+=1))
            fi
		fi
	done

	#check mysql tar
	check_package "db"
	if [ $? -ne 0 ];then
		install_log "ERROR" "check db" "Missing the installation package for the db, please put it under the dir directory and check again"
		((db_flag+=1))
	fi

	if [ $db_flag -gt 0 ];then
		install_log "ERROR" "check db" "Check mysql db is failed"
		return 1
	else
		install_log "INFO" "check db" "Check mysql db Successfull"
	fi

	return 0
}

function check_agent
{
	install_log "INFO" "check agent" "Begin to check agent"
	typeset age_flag=0
	
	#check worker dir
	ls -l /home/istorm/worker > /dev/null 2>&1
	if [ $? -eq 0 ];then
		install_log "ERROR" "check agent" "Agent has been installed, please uninstall the retry"
		((age_flag+=1))
	fi

	#check istorm_worker.zip
	check_package "agent"
	if [ $? -ne 0 ];then
		install_log "ERROR" "check agent" "Missing the installation package for the agent, please put it under the dir directory and check again"
		((age_flag+=1))
	fi

	if [ $age_flag -gt 0 ];then
		install_log "ERROR" "check agent" "Check agent is failed"
		return 1
	else
		install_log "INFO" "check agent" "Check agent Successfull"
	fi

	return 0
}

function check_linux
{
	#check rpm
	install_log "INFO" "check linux" "Begin to check need rpm"
	rpm -qa > rpm_list
	#delete mariadb
	grep -ri "mariadb" rpm_list > /dev/null
	if [ $? -eq 0 ];then
		yum remove mariadb -y
		rm -f /etc/my.cnf
		rm -rf /var/lib/mysql/
	fi
    
    #delete jdk
	grep -ri "jdk" rpm_list > /dev/null
	if [ $? -eq 0 ];then
		rpm -qa | grep jdk | xargs -n1 -i rpm -e --nodeps {}
	fi
	
	#check space
	typeset space=$(df -h | grep -wi "/home" | awk '{print $4}' | sed 's/[A-Z]//g' | awk -F"." '{print $1}')
	if [ "X${space}" == "X" ];then
		space=$(df -h | grep -wi "/" | awk '{print $4}' | sed 's/[A-Z]//g' | awk -F"." '{print $1}')
	fi
	
	if [ $space -le 20 ];then
		install_log "ERROR" "check linux" "IStorm DR Minimum installation space: 20g"
		return 1
	fi
    
    #install need rpm
    yum install zlib pcre pcre-devel openssl openssl-devel socat python python2 python-babel python-markupsafe python-paramiko python-setuptools python2-cryptography gcc-c++ fontconfig mkfontscale libyaml -y >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "check linux" "Install zlib pcre pcre-devel openssl openssl-devel socat python python2 python-babel python-markupsafe python-paramiko python-setuptools python2-cryptography gcc-c++ fontconfig mkfontscale libyaml is failed."
        return 1
    fi
	
	return 0
}

function check_port
{
	install_log "INFO" "check port" "Begin to check need port"
	typeset port_flag=0
	#Check the required port according to the content of the configuration file
	typeset port_list="8761 8040 8022 8000 7011 7030 7060 9000 7050 9020 9010 7020 7040 7010 9060 7070 9050 9070 9400 9030 3306 9065 8087 8086"
	for port in ${port_list}
	do
		netstat -an | grep ${port} | grep LISTEN
		if [ $? -eq 0 ];then
			install_log "ERROR" "check port" "The port:${port} is busy"
			((port_flag+=1))
		fi
	done
	
	if [ $port_flag -gt 0 ];then
		install_log "ERROR" "check port" "Check port is failed"
		return 1
	else
		install_log "INFO" "check port" "Check port Successfull"
	fi
	
	return 0
}

function check_env
{
	#main function
	install_log "INFO" "check env" "Begin to check env"
	typeset flag=0

	typeset ne_list=$(get_ne_type_list)
	if [ "X${ne_list}" == "X" ];then
		install_log "ERROR" "check env" "get ne_type_list is failed"
		return 1
	fi
	
	for ne in ${ne_list}
	do
		if [ "X${ne}" != "X" ];then
			if [ "X${ne}" == "Xdb" ];then
				check_db
				if [ $? -ne 0 ];then
					install_log "ERROR" "check env" "Check mysql db Install front requirement is failed"
					((flag+=1))
				fi
			elif [ "X${ne}" == "Xdrsaas" ];then
				check_drsaas
				if [ $? -ne 0 ];then
					install_log "ERROR" "check env" "Check drsaas Install front requirement is failed"
					((flag+=1))
				fi
			else
				check_agent
				if [ $? -ne 0 ];then
					install_log "ERROR" "check env" "Check agent Install front requirement is failed"
					((flag+=1))
				fi
			fi
		fi
	done
    
    check_linux
	if [ $? -ne 0 ];then
		install_log "ERROR" "check env" "Check linux need rpm is failed"
		((flag+=1))
	fi
	
	check_port
	if [ $? -ne 0 ];then
		install_log "ERROR" "check env" "Check linux port is failed"
		((flag+=1))
	fi

	if [ $flag -gt 0 ];then
		install_log "ERROR" "check env" "Check env failed,Please check"
		return 1
	else
		install_log "INFO" "check env" "Check env Successfull"
		install_log "INFO" "check env" "script_execute_success"
	fi
	
	sed -i 's/checkenv.*/checkenv 2/g' ${REPEAT_FILE}
	
	return 0
}

check_env $@
if [ $? -ne 0 ];then
	install_log "ERROR" "check env main" "script_execute_error"
	sed -i 's/checkenv.*/checkenv 1/g' ${REPEAT_FILE}
	exit 1
fi

exit 0
