#!/bin/bash
#================================================#
## Install env init ##
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

. ./comm_func.lib

#init mysql,startup mysql && modify root passwd and init istorm sql
function init_db
{
	install_log "INFO" "init_db" "Begin to init mysql db"
	
    typeset db_ip=$(read_value "db_ip")
	typeset db_passwd=$(read_value "db_root_passwd")

	ps aux | grep mysql | grep -v grep | awk '{print $2}' | xargs -n1 -i kill -9 {}
	#Start MySQL and initialize the root password
	su - ${USER_NAME} -c "${USER_HOME}/mysql/support-files/mysql.server start"
	su - ${USER_NAME} -c "${USER_HOME}/mysql/bin/mysqladmin -u root -h localhost.localdomain password ''${db_passwd}''"
	
    sleep 10
    
	grep -ri "${USER_HOME}/mysql" ${USER_HOME}/.bash_profile > /dev/null
	if [ $? -ne 0 ];then
		echo "export PATH=${USER_HOME}/mysql/bin:\$PATH" >> ${USER_HOME}/.bash_profile
	fi
	#Create Sid and import Dr's initialization SQL script, and empower
    ls -al ${USER_HOME}/mysql/istorm_sql/ | grep "^-rw" | awk '{print $9}' | awk -F"." '{print $1}' > ${USER_HOME}/mysql_file
    echo "" >> ${USER_HOME}/mysql_file
    
    ${USER_HOME}/mysql/bin/mysql -u root -p${db_passwd}<<EOF
grant all privileges on *.* to root@'%' identified by '${db_passwd}';
UPDATE mysql.user SET Grant_priv='Y', Super_priv='Y' WHERE User='root';
flush privileges;
EOF

    while read line
    do
        if [ "X${line}" != "X" ];then
            typeset sql_file=$(ls ${USER_HOME}/mysql/istorm_sql/${line}.sql)
            ${USER_HOME}/mysql/bin/mysql -u root -p${db_passwd}<<EOF
create database \`${line}\`;
use ${line};
source ${sql_file};
EOF
        fi
    done<${USER_HOME}/mysql_file

    ${USER_HOME}/mysql/bin/mysql -u root -p${db_passwd}<<EOF
use framework-draas;
update \`tenant_datasource\` set \`datasource_url\` = REPLACE(\`datasource_url\`,'127.0.0.1:3306','${db_ip}:3306') , \`datasource_username\` =  'root', \`datasource_password\` = '${db_passwd}';
commit;
EOF

	cp ${USER_HOME}/mysql/support-files/mysql.server /etc/init.d/mysqld
	#Add self start
	chkconfig --add mysqld
	chkconfig mysqld on

    firewall-cmd --zone=public --add-port=3306/tcp --permanent
    firewall-cmd --reload
    rm -rf ${USER_HOME}/mysql_file
	install_log "INFO" "init_db" "Init mysql db is Successfull"
	
	return 0
}

#modify nginx config
function init_nginx
{
	install_log "INFO" "init_nginx" "Begin to init nginx"
	
    typeset drsaas_ip=$(read_value "drsaas_ip")

    sed -i "s#127.0.0.1#${drsaas_ip}#g" /usr/local/nginx/conf/nginx.conf
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_nginx" "Modify drsaas_ip Configure is failed."
        return 1
    fi
    
    sed -i "s#/opt/hatech#/home/istorm/app#g" /usr/local/nginx/conf/nginx.conf
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_nginx" "Modify /opt/hatech Configure is failed."
        return 1
    fi

    /usr/local/nginx/sbin/nginx -t
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_nginx" "nginx -t is failed."
        return 1
    fi
    
	install_log "INFO" "init_nginx" "Modify agent Configure is Successfull"
	
	return 0
}

#modify redis config
function init_redis
{
	install_log "INFO" "init_redis" "Begin to init redis"

    typeset redis_dir=$(ls -al /usr/local/src | awk '{print $9}' | grep "^redis")
    cp /usr/local/src/${redis_dir}/redis.conf /usr/local/redis/bin
    
    sed -i "s#daemonize no#daemonize yes#g" /usr/local/redis/bin/redis.conf
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_redis" "Modify /usr/local/redis/bin/redis.conf Configure is failed."
        return 1
    fi
    
    grep "redis-server" /etc/rc.local > /dev/null
    if [ $? -ne 0 ];then
        echo "/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis-conf" >> /etc/rc.local
    fi

	install_log "INFO" "init_redis" "Modify redis Configure is Successfull"
	
	return 0
}

#modify mq config
function init_mq
{
	install_log "INFO" "init_mq" "Begin to init mq"

    /sbin/service rabbitmq-server start
    /sbin/rabbitmq-plugins list > /dev/null
    /sbin/rabbitmqctl status > /dev/null
    
    /sbin/rabbitmq-plugins enable rabbitmq_management
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_mq" "rabbitmq-plugins enable rabbitmq_management is failed."
        return 1
    fi
    
    /sbin/rabbitmqctl add_user admin admin
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_mq" "rabbitmqctl add_user admin admin is failed."
        return 1
    fi
    
    /sbin/rabbitmqctl set_user_tags admin administrator
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_mq" "rabbitmqctl set_user_tags admin administrator is failed."
        return 1
    fi
    
    /sbin/rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_mq" "rabbitmqctl set_permissions -p / admin \".*\" \".*\" \".*\" is failed."
        return 1
    fi
    
    sudo firewall-cmd --zone=public --add-port=4369/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=5672/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=25672/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=15672/tcp --permanent

    sudo firewall-cmd --reload
    
    /sbin/service rabbitmq-server stop

	install_log "INFO" "init_mq" "Modify redis Configure is Successfull"
	
	return 0
}

#modify seata config
function init_seata
{
	install_log "INFO" "init_seata" "Begin to init seata"

    typeset reg_file="${USER_HOME}/seata/conf/registry.conf"
    sed -i '0,/type = "file"/s//type = "eureka"/' ${reg_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_seata" "sed -i type = \"eureka\" is failed."
        return 1
    fi
    
    typeset drsaas_ip=$(read_value "drsaas_ip")
    
    sed -i "s#serviceUrl = \"http://localhost:8761/eureka\"#serviceUrl = \"http://${drsaas_ip}:8761/eureka\"#g" ${reg_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_seata" "sed -i serviceUrl is failed."
        return 1
    fi
    
    sed -i "/serviceUrl/{n;s#default#hatech-seata-server#g}" ${reg_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_seata" "sed -i hatech-seata-server is failed."
        return 1
    fi
    
    su - ${USER_NAME} -c "mkdir -p ${USER_HOME}/seata/logs"
    typeset log_file="${USER_HOME}/seata/conf/logback.xml"
    sed -i "s#<property name=\"LOG_HOME\" value=\"\${user.home}/logs/seata\"/>#<property name=\"LOG_HOME\" value=\"${USER_HOME}/code/seata/logs\"/>#g" ${log_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_seata" "sed -i ${log_file} is failed."
        return 1
    fi
    
	install_log "INFO" "init_seata" "Modify seata Configure is Successfull"
	
	return 0
}

#modify kkfileview config
function init_kkfileview
{
	install_log "INFO" "init_kkfileview" "Begin to init kkfileview"

    typeset application_file="${USER_HOME}/code/kkFileView/config/application.properties"
    sed -i "s#server.port.*#server.port=\${KK_SERVER_PORT:8102}#g" ${application_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_kkfileview" "modify server.port is failed."
        return 1
    fi
    
    sed -i "s#server.context-path.*#server.context-path = \${KK_CONTEXT_PATH:/filePreview}#g" ${application_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_kkfileview" "modify server.context-path is failed."
        return 1
    fi
    
    sed -i "s#spring.http.multipart.max-request-size.*#spring.http.multipart.max-request-size = 50MB#g" ${application_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_kkfileview" "modify max-request-size is failed."
        return 1
    fi
    
    sed -i "s#spring.http.multipart.max-file-size.*#spring.http.multipart.max-file-size = 50MB#g" ${application_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_kkfileview" "modify max-file-size is failed."
        return 1
    fi
    
    sed -i "s#file.dir.*#file.dir = \${KK_FILE_DIR:${USER_HOME}/code/kkFileView-File/}#g" ${application_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_kkfileview" "modify file.dir is failed."
        return 1
    fi
    
	install_log "INFO" "init_kkfileview" "Modify kkfileview Configure is Successfull"
	
	return 0
}

#modify web config
function init_web
{
	install_log "INFO" "init_web" "Begin to init web"
    
    typeset drsaas_ip=$(read_value "drsaas_ip")
    typeset db_ip=$(read_value "db_ip")
	typeset db_passwd=$(read_value "db_root_passwd") 
    
    typeset start_file="${USER_HOME}/code/start_all.sh"
    sed -i "s#127.0.0.1#${drsaas_ip}#g" ${start_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_web" "modify drsaas_ip is failed."
        return 1
    fi
    
    sed -i "s#DATABASE_IP=.*#DATABASE_IP=${db_ip}#g" ${start_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_web" "modify db_ip is failed."
        return 1
    fi
    
    sed -i "s#DATABASE_PASSWORD=.*#DATABASE_PASSWORD='${db_passwd}'#g" ${start_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_web" "modify db_passwd is failed."
        return 1
    fi
    
    sed -i "s#SEATA_SERVER_SH=.*#SEATA_SERVER_SH=${USER_HOME}/seata/bin/seata-server.sh#g" ${start_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_web" "modify seata-server.sh is failed."
        return 1
    fi
    
    sed -i "s#/opt/hatech#${USER_HOME}#g" ${start_file}
    if [ $? -ne 0 ];then
        install_log "ERROR" "init_web" "modify func.file.rootPath is failed."
        return 1
    fi
    
	install_log "INFO" "init_web" "Modify web Configure is Successfull"
	
	return 0
}

#-------------install_env_init-------------#
#Initialize the environment and prepare for startup.
function install_env_init
{
	install_log "INFO" "install_env_init" "Begin to init DRsaas"

	typeset ne_list=$(get_ne_type_list)
	if [ "X${ne_list}" == "X" ];then
		install_log "ERROR" "install_env_init" "get ne_type_list is failed"
		return 1
	fi

	for ne in ${ne_list}
	do
		if [ "X${ne}" != "X" ];then
			if [ "X${ne}" == "Xdrsaas" ];then
                typeset init_rep=$(check_repeat "init_nginx")
				if [ "X${init_rep}" != "X2" ];then
					init_nginx
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init nginx is failed"
						sed -i 's/init_nginx.*/init_nginx 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_nginx.*/init_nginx 2/g' ${REPEAT_FILE}
					fi
				fi
                
                init_rep=$(check_repeat "init_redis")
				if [ "X${init_rep}" != "X2" ];then
					init_redis
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init redis is failed"
						sed -i 's/init_redis.*/init_redis 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_redis.*/init_redis 2/g' ${REPEAT_FILE}
					fi
				fi
                
                init_rep=$(check_repeat "init_mq")
				if [ "X${init_rep}" != "X2" ];then
					init_mq
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init mq is failed"
						sed -i 's/init_mq.*/init_mq 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_mq.*/init_mq 2/g' ${REPEAT_FILE}
					fi
				fi
                
                init_rep=$(check_repeat "init_seata")
				if [ "X${init_rep}" != "X2" ];then
					init_seata
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init seata is failed"
						sed -i 's/init_seata.*/init_seata 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_seata.*/init_seata 2/g' ${REPEAT_FILE}
					fi
				fi
                
                init_rep=$(check_repeat "init_kkfileview")
				if [ "X${init_rep}" != "X2" ];then
					init_kkfileview
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init kkfileview is failed"
						sed -i 's/init_kkfileview.*/init_kkfileview 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_kkfileview.*/init_kkfileview 2/g' ${REPEAT_FILE}
					fi
				fi
                
				init_rep=$(check_repeat "init_drsaas")
				if [ "X${init_rep}" != "X2" ];then
					init_web
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init drsaas is failed"
						sed -i 's/init_drsaas.*/init_drsaas 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_drsaas.*/init_drsaas 2/g' ${REPEAT_FILE}
					fi
				fi
			elif [ "X${ne}" == "Xdb" ];then
                typeset init_rep=$(check_repeat "init_db")
				if [ "X${init_rep}" != "X2" ];then
					init_db
					if [ $? -ne 0 ];then
						install_log "ERROR" "install_env_init" "Init mysql db is failed"
						sed -i 's/init_db.*/init_db 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/init_db.*/init_db 2/g' ${REPEAT_FILE}
					fi
				fi
			fi
		fi
	done
    
    chmod -R 755 ${USER_HOME}
    
	install_log "INFO" "install_env_init" "Install env init Successfull"
    
	return 0
}

#main
install_env_init $@
if [ $? -ne 0 ];then
	install_log "ERROR" "install_env_init" "script_execute_error"
	exit 1
fi

exit 0
