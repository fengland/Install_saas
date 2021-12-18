#!/bin/bash
#================================================#
## startup web db agent server ##
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

. ./comm_func.lib

#start web
function start_web
{
	install_log "INFO" "start_web" "Begin to start DRsaas"

	su - ${USER_NAME} -c "cd ${USER_HOME}/code;sh start_all.sh start all"
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_web" "Start web app is failed,please check"
		sed -i 's/start_drsaas.*/start_drsaas 1/g' ${REPEAT_FILE}
		return 1
    fi
	
	sed -i 's/start_drsaas.*/start_drsaas 2/g' ${REPEAT_FILE}
	install_log "INFO" "start_web" "Start DRsaas is Successfull"
	return 0
}

#start nginx
function start_nginx
{
	install_log "INFO" "start_nginx" "Begin to start nginx"
    
    /usr/local/nginx/sbin/nginx
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_nginx" "Start nginx is failed"
        sed -i 's/start_nginx.*/start_nginx 1/g' ${REPEAT_FILE}
        return 1
    fi
    
    ps -ef | grep nginx | grep -v grep > /dev/null
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_nginx" "nginx pid is 0"
        sed -i 's/start_nginx.*/start_nginx 1/g' ${REPEAT_FILE}
        return 1
    fi
    
	sed -i 's/start_nginx.*/start_nginx 2/g' ${REPEAT_FILE}
	install_log "INFO" "start_nginx" "Start nginx is Successfull"
	return 0
}

#start redis
function start_redis
{
	install_log "INFO" "start_redis" "Begin to start redis"

    /usr/local/redis/bin/redis-server /usr/local/redis/bin/redis.conf
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_redis" "Start redis is failed"
        sed -i 's/start_redis.*/start_redis 1/g' ${REPEAT_FILE}
        return 1
    fi
    
    ps -ef | grep redis | grep -v grep > /dev/null
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_redis" "redis pid is null"
        sed -i 's/start_redis.*/start_redis 1/g' ${REPEAT_FILE}
        return 1
    fi
    
	sed -i 's/start_redis.*/start_redis 2/g' ${REPEAT_FILE}
	install_log "INFO" "start_redis" "Start redis is Successfull"
	return 0
}

#start mq
function start_mq
{
	install_log "INFO" "start_mq" "Begin to start mq"

    /sbin/service rabbitmq-server start >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_mq" "Start mq is failed"
        sed -i 's/start_mq.*/start_mq 1/g' ${REPEAT_FILE}
        return 1
    fi
    
    /sbin/rabbitmqctl status >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_mq" "rabbitmqctl status is failed"
        sed -i 's/start_mq.*/start_mq 1/g' ${REPEAT_FILE}
        return 1
    fi
    
	sed -i 's/start_mq.*/start_mq 2/g' ${REPEAT_FILE}
	install_log "INFO" "start_mq" "Start mq is Successfull"
	return 0
}

#start kkfileview
function start_kkfileview
{
	install_log "INFO" "start_kkfileview" "Begin to start kkfileview"

    su - ${USER_NAME} -c "${USER_HOME}/code/kkFileView/bin/startup.sh"
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_kkfileview" "Start kkfileview is failed"
        sed -i 's/start_kkfileview.*/start_kkfileview 1/g' ${REPEAT_FILE}
        return 1
    fi
    
    ps -ef | grep -ri kkfileview | grep -v grep > /dev/null
    if [ $? -ne 0 ];then
        install_log "ERROR" "start_kkfileview" "kkfileview pid num is null"
        sed -i 's/start_kkfileview.*/start_kkfileview 1/g' ${REPEAT_FILE}
        return 1
    fi
    
	sed -i 's/start_kkfileview.*/start_kkfileview 2/g' ${REPEAT_FILE}
	install_log "INFO" "start_kkfileview" "Start kkfileview is Successfull"
	return 0
}

#-------------start-------------#
#apps for startup.
function startup_main
{
	install_log "INFO" "startup_main" "Begin to start DRsaas"

	typeset ne_list=$(get_ne_type_list)
	if [ "X${ne_list}" == "X" ];then
		install_log "ERROR" "startup_main" "get ne_type_list is failed"
		return 1
	fi

	chown -R ${USER_NAME}. ${USER_HOME}
    
    typeset start_rep=$(check_repeat "start_nginx")
	if [ "X${start_rep}" != "X2" ];then
        start_nginx
        if [ $? -ne 0 ];then
            install_log "ERROR" "startup_main" "Start nginx is failed"
            return 1
        fi
    fi
    
    start_rep=$(check_repeat "start_redis")
	if [ "X${start_rep}" != "X2" ];then
        start_redis
        if [ $? -ne 0 ];then
            install_log "ERROR" "startup_main" "Start redis is failed"
            return 1
        fi
    fi
    
    start_rep=$(check_repeat "start_mq")
	if [ "X${start_rep}" != "X2" ];then
        start_mq
        if [ $? -ne 0 ];then
            install_log "ERROR" "startup_main" "Start mq is failed"
            return 1
        fi
    fi
    
    start_rep=$(check_repeat "start_kkfileview")
	if [ "X${start_rep}" != "X2" ];then
        start_kkfileview
        if [ $? -ne 0 ];then
            install_log "ERROR" "startup_main" "Start kkfileview is failed"
            return 1
        fi
    fi
    
    start_rep=$(check_repeat "start_drsaas")
	if [ "X${start_rep}" != "X2" ];then
        start_web
        if [ $? -ne 0 ];then
            install_log "ERROR" "startup_main" "Start DRsaas is failed"
            return 1
        fi
    fi

    iptables -F
    
	install_log "INFO" "startup_main" "Start DRsaas Successfull"

}

#main
startup_main $@
if [ $? -ne 0 ];then
	install_log "ERROR" "startup_main" "script_execute_error"
	exit 1
fi

exit 0
