#!/bin/bash
#================================================#
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

. ./comm_func.lib

#-------------Install main-------------#
#Install the total control script
function install_main
{
	install_log "INFO" "install_main" "Begin to install IStorm DRsaas"
	#Initialization log
	mkdir -p ${SCRIPT_DIR}/log
	touch ${LOG_FILE}
	create_repeat
	#Environmental inspection
	echo "================================================================================================"
	install_log "INFO" "install_main" "Begin to check Installation environment"
	typeset check_rep=$(check_repeat "checkenv")
	if [ "X${check_rep}" != "X2" ];then
		${SCRIPT_DIR}/check_env.sh
		if [ $? -ne 0 ];then
			install_log "ERROR" "install_main" "Execute check_env.sh failed"
			return 1
		fi
	fi

	#Install
	echo "================================================================================================"
	install_log "INFO" "install_main" "Begin to install DRsaas  and mysql"
	${SCRIPT_DIR}/install.sh
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_main" "Execute install.sh failed"
		return 1
	fi

	#Environmental initialization
	echo "================================================================================================"
	install_log "INFO" "install_main" "Begin to environmental initialization"
    ${SCRIPT_DIR}/install_env_init.sh
    if [ $? -ne 0 ];then
    	install_log "ERROR" "install_main" "Execute install_env_init.sh failed"
    	return 1
    fi

	#start app
	echo "================================================================================================"
	install_log "INFO" "install_main" "Begin to start IStorm"
	${SCRIPT_DIR}/start.sh
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_main" "Execute start.sh failed"
		return 1
	fi

	install_log "INFO" "install_main" "Install IStorm DR Successfull"
	
	return 0
}

#main
install_main $@
if [ $? -ne 0 ];then
	install_log "ERROR" "main" "script_execute_error"
	exit 1
fi

exit 0
