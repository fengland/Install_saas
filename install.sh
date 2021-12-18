#!/bin/bash
#================================================#
## Install ##
# Version Number:1.00
# Type:app
# Language:bash shell
#================================================#

. ./comm_func.lib

#install mysql
function install_db
{
	install_log "INFO" "install_db" "Begin to install mysql db"
	typeset db_port=$(read_value "db_port")
	iptables -F
	#decompression
	tar -zxf ${PKG_DIR}/mysql-5.*tar.gz -C ${USER_HOME}/
	mv ${USER_HOME}/mysql-5.* ${USER_HOME}/mysql
	#MySQL 5.7 installation method
	mkdir -p ${USER_HOME}/mysql/data
	mkdir -p ${USER_HOME}/mysql/logs
	#Initialize my.cnf file
	echo "[mysql]" > /etc/my.cnf
	echo "default_character_set=utf8" >> /etc/my.cnf
	echo "socket=${USER_HOME}/mysql/mysqld.sock" >> /etc/my.cnf
	echo "[mysqld]" >> /etc/my.cnf
	echo "user=${USER_NAME}" >> /etc/my.cnf
	echo "port=${db_port}" >> /etc/my.cnf
	echo "max_connections=2000" >> /etc/my.cnf
	echo "character_set_server=utf8" >> /etc/my.cnf
	echo "basedir=${USER_HOME}/mysql" >> /etc/my.cnf
	echo "datadir=${USER_HOME}/mysql/data" >> /etc/my.cnf
    echo "default-storage-engine=INNODB" >> /etc/my.cnf
    echo "max_allowed_packet=20M" >> /etc/my.cnf
	echo "log-error=${USER_HOME}/mysql/logs/mysql.err" >> /etc/my.cnf
	echo "pid-file=${USER_HOME}/mysql/mysqld.pid" >> /etc/my.cnf
	echo "socket=${USER_HOME}/mysql/mysqld.sock" >> /etc/my.cnf
	echo "[client]" >> /etc/my.cnf
	echo "socket=${USER_HOME}/mysql/mysqld.sock" >> /etc/my.cnf
	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME}/mysql
	chown ${USER_NAME}:${GROUP_NAME} /etc/my.cnf
	#Silent installation mysql5.7
	su - ${USER_NAME} -c "${USER_HOME}/mysql/bin/mysqld --initialize-insecure" >> ${SCRIPT_DIR}/log/install_db_log
	grep -ri "error" ${SCRIPT_DIR}/log/install_db_log | grep -v "\["
	if [ $? -eq 0 ];then
		install_log "ERROR" "install_db" "install mysql is failed"
		return 1
	fi
	
	chmod 644 /etc/my.cnf
	mkdir -p ${USER_HOME}/mysql/istorm_sql
	cp ${PKG_DIR}/sql/*.sql ${USER_HOME}/mysql/istorm_sql/
	
	return 0
}

#install jdk
function install_jdk
{
	install_log "INFO" "install_jdk" "Begin to install jdk"

	#decompression
	tar -zxf ${PKG_DIR}/jdk-8*gz -C /usr/local/
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_jdk" "Decompression jdk-8 to /usr/local/ is failed"
		return 1
	fi

	mv /usr/local/jdk1.8* /usr/local/jdk1.8

	#Initialize environment variables
    grep "/usr/local/jdk1.8" /etc/profile > /dev/null
    if [ $? -ne 0 ];then
        echo "export JAVA_HOME=/usr/local/jdk1.8" >> /etc/profile
        echo "export JRE_HOME=\$JAVA_HOME/jre" >> /etc/profile
        echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin" >> /etc/profile
        echo "CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar:\$JRE_HOME/lib" >> /etc/profile
    fi
	
    source /etc/profile
    
	install_log "INFO" "install_jdk" "Install jdk Successfull"

	return 0
}

#install nginx
function install_nginx
{
	install_log "INFO" "install_nginx" "Begin to install nginx"

	#decompression nginx
	tar -zxf ${PKG_DIR}/nginx-1*.tar.gz -C /usr/local/src > /dev/null
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_nginx" "Decompression nginx-1*.tar.gz to /usr/local/src is failed"
		return 1
	fi
    
    #decompression pcre
	tar -zxf ${PKG_DIR}/pcre-8*.tar.gz -C /usr/local/src > /dev/null
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_nginx" "Decompression pcre-8*.tar.gz to /usr/local/src is failed"
		return 1
	fi
    
    #decompression zlib
	tar -zxf ${PKG_DIR}/zlib-1*.tar.gz -C /usr/local/src > /dev/null
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_nginx" "Decompression zlib-1*.tar.gz to /usr/local/src is failed"
		return 1
	fi

    install_log "INFO" "install_nginx" "Begin to install pcre"
	typeset pcre_dir=$(ls -al /usr/local/src | awk '{print $9}' | grep "^pcre")
    cd /usr/local/src/${pcre_dir}
    ./configure >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "/usr/local/src/${pcre_dir}/configure is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "pcre make is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make install >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "pcre make install is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    install_log "INFO" "install_nginx" "Begin to install zlib"
    typeset zlib_dir=$(ls -al /usr/local/src | awk '{print $9}' | grep "^zlib")
    cd /usr/local/src/${zlib_dir}
    ./configure >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "/usr/local/src/${zlib_dir}/configure is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "zlib make is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make install >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "zlib make install is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    install_log "INFO" "install_nginx" "Begin to install nginx"
    typeset nginx_dir=$(ls -al /usr/local/src | awk '{print $9}' | grep "^nginx")
    cd /usr/local/src/${nginx_dir}
    ./configure >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "/usr/local/src/${nginx_dir}/configure is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "nginx make is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    make install >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_nginx" "nginx make install is failed.please check ${LOG_FILE}"
        return 1
    fi
    
    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf_bak
    cp ${PKG_DIR}/nginx.conf /usr/local/nginx/conf/
    
	install_log "INFO" "install_nginx" "Install nginx Successfull"

	return 0
}

#install redis
function install_redis
{
	install_log "INFO" "install_redis" "Begin to install redis"

	#decompression redis
	tar -zxf ${PKG_DIR}/redis-3*.tar.gz -C /usr/local/src > /dev/null
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_redis" "Decompression redis-3*.tar.gz to /usr/local/src is failed"
		return 1
	fi

	typeset redis_dir=$(ls -al /usr/local/src | awk '{print $9}' | grep "^redis")
    cd /usr/local/src/${redis_dir}
    make PREFIX=/usr/local/redis install >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "INFO" "install_redis" "make PREFIX=/usr/local/redis install install is failed.please check ${LOG_FILE}"
        return 1
    fi
    
	install_log "INFO" "install_redis" "Install redis Successfull"

	return 0
}

#install mq
function install_mq
{
	install_log "INFO" "install_mq" "Begin to install mq"

    rpm -ivh ${PKG_DIR}/erlang-19*.x86_64.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_mq" "rpm -ivh ${PKG_DIR}/erlang-19*.x86_64.rpm is failed"
		return 1
	fi

	rpm -ivh ${PKG_DIR}/rabbitmq-server-3*.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_mq" "rpm -ivh ${PKG_DIR}/rabbitmq-server-3*.rpm is failed"
		return 1
	fi
    
	install_log "INFO" "install_mq" "Install mq Successfull"

	return 0
}

#install ansible
function install_ansible
{
	install_log "INFO" "install_ansible" "Begin to install ansible"

	rpm -ivh ${PKG_DIR}/sshpass-1*.x86_64.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_ansible" "rpm -ivh ${PKG_DIR}/sshpass-1*.x86_64.rpm is failed"
		return 1
	fi
    
    rpm -ivh ${PKG_DIR}/epel-release-latest-7.noarch.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_ansible" "rpm -ivh ${PKG_DIR}/epel-release-latest-7.noarch.rpm is failed"
		return 1
	fi
    
    rpm -ivh ${PKG_DIR}/python-jinja2*.noarch.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_ansible" "rpm -ivh ${PKG_DIR}/python-jinja2*.noarch.rpm is failed"
		return 1
	fi
    
    rpm -ivh ${PKG_DIR}/PyYAML-3*x86_64.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_ansible" "rpm -ivh ${PKG_DIR}/PyYAML-3*x86_64.rpm is failed"
		return 1
	fi
    
    rpm -ivh ${PKG_DIR}/ansible-2*.noarch.rpm
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_ansible" "rpm -ivh ${PKG_DIR}/ansible-2*.noarch.rpm is failed"
		return 1
	fi
    
	install_log "INFO" "install_ansible" "Install ansible Successfull"

	return 0
}

#install seata
function install_seata
{
	install_log "INFO" "install_seata" "Begin to install seata"
	
	#decompression
	tar -zxf ${PKG_DIR}/seata-server-1*.tar.gz -C ${USER_HOME}
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_seata" "Decompression seata-server-1*.tar.gz to ${USER_HOME} is failed"
		return 1
	fi
    
    chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME}
    
	install_log "INFO" "install_seata" "Install seata Successfull"

	return 0
}

#install kkfileview
function install_kkfileview
{
	install_log "INFO" "install_kkfileview" "Begin to install kkfileview"
    mkdir -p ${USER_HOME}/code/kkFileView-File
	
	#decompression kkfile
	tar -zxf ${PKG_DIR}/kkFileView.tar.gz -C ${USER_HOME}/code/
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_kkfileview" "Decompression kkFileView.tar.gz to ${USER_HOME} is failed"
		return 1
	fi
    
    #decompression OpenOffice
	tar -zxf ${PKG_DIR}/Apache_OpenOffice_4*.tar.gz -C /tmp
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_kkfileview" "Decompression Apache_OpenOffice_4*.tar.gz to /tmp is failed"
		return 1
	fi
    
    chown -R ${USER_NAME}:${GROUP_NAME} /tmp/zh-CN
    
    chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME}
    
    sh ${USER_HOME}/code/kkFileView/bin/install.sh >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_kkfileview" "sh ${USER_HOME}/code/kkFileView/bin/install.sh is failed"
        return 1
    fi
    
    su - ${USER_NAME} -c "${USER_HOME}/code/kkFileView/bin/startup.sh"
    sleep 10
    su - ${USER_NAME} -c "${USER_HOME}/code/kkFileView/bin/shutdown.sh"
    
    mkdir -p /usr/share/fonts
    
    #decompression font
	tar -zxf ${PKG_DIR}/font.tar.gz -C /usr/share/fonts
	if [ $? -ne 0 ];then
		install_log "ERROR" "install_kkfileview" "Decompression font.tar.gz to /usr/share/fonts is failed"
		return 1
	fi
    
    cd /usr/share/fonts/win
    
    mkfontscale >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_kkfileview" "mkfontscale is failed"
        return 1
    fi
    
    mkfontdir >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_kkfileview" "mkfontdir is failed"
        return 1
    fi
    
    fc-cache >> ${LOG_FILE}
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_kkfileview" "fc-cache is failed"
        return 1
    fi
    
	install_log "INFO" "install_kkfileview" "Install kkfileview Successfull"

	return 0
}

#install web
function install_web
{
	install_log "INFO" "install_web" "Begin to install web"
    
    mkdir -p ${USER_HOME}/app/code/web
    
    cp ${PKG_DIR}/qian/* ${USER_HOME}/app/code/web/
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_web" "mv ${PKG_DIR}/qian/* ${USER_HOME}/app/code/web/ is failed."
        return 1
    fi
    
    cp ${PKG_DIR}/hou/* ${USER_HOME}/code/
    if [ $? -ne 0 ];then
        install_log "ERROR" "install_web" "mv ${PKG_DIR}/hou/* ${USER_HOME}/code/ is failed."
        return 1
    fi
    
    cp ${PKG_DIR}/start_all_*.sh ${USER_HOME}/code/start_all.sh
    chmod +x ${USER_HOME}/code/start_all.sh
    
    chown -R ${USER_NAME}. ${USER_HOME}
    
	install_log "INFO" "install_web" "Install web Successfull"

	return 0
}

#-------------Install main-------------#
#Install DRsaas
function install
{
	install_log "INFO" "install" "Begin to install DRsaas"

	typeset ne_list=$(get_ne_type_list)
	if [ "X${ne_list}" == "X" ];then
		install_log "ERROR" "install" "get ne_type_list is failed"
		return 1
	fi
	#Creating an istorm user
	grep "^istorm:" /etc/passwd > /dev/null
	if [ $? -ne 0 ];then
		create_user
		if [ $? -ne 0 ];then
			install_log "ERROR" "install web" "create user is failed"
			return 1
		fi
	fi
	
	for ne in ${ne_list}
	do
		if [ "X${ne}" != "X" ];then
			if [ "X${ne}" == "Xdrsaas" ];then
				typeset install_rep=$(check_repeat "install_jdk")
				if [ "X${install_rep}" != "X2" ];then
					install_jdk
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install jdk is failed"
						sed -i 's/install_jdk.*/install_jdk 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_jdk.*/install_jdk 2/g' ${REPEAT_FILE}
					fi
				fi
				
				install_rep=$(check_repeat "install_nginx")
				if [ "X${install_rep}" != "X2" ];then
					install_nginx
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install nginx is failed"
						sed -i 's/install_nginx.*/install_nginx 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_nginx.*/install_nginx 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_redis")
				if [ "X${install_rep}" != "X2" ];then
					install_redis
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install redis is failed"
						sed -i 's/install_redis.*/install_redis 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_redis.*/install_redis 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_mq")
				if [ "X${install_rep}" != "X2" ];then
					install_mq
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install mq is failed"
						sed -i 's/install_mq.*/install_mq 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_mq.*/install_mq 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_ansible")
				if [ "X${install_rep}" != "X2" ];then
					install_ansible
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install ansible is failed"
						sed -i 's/install_ansible.*/install_ansible 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_ansible.*/install_ansible 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_seata")
				if [ "X${install_rep}" != "X2" ];then
					install_seata
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install seata is failed"
						sed -i 's/install_seata.*/install_seata 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_seata.*/install_seata 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_kkfileview")
				if [ "X${install_rep}" != "X2" ];then
					install_kkfileview
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install kkfileview is failed"
						sed -i 's/install_kkfileview.*/install_kkfileview 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_kkfileview.*/install_kkfileview 2/g' ${REPEAT_FILE}
					fi
				fi
                
                install_rep=$(check_repeat "install_drsaas")
				if [ "X${install_rep}" != "X2" ];then
					install_web
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install drsaas is failed"
						sed -i 's/install_drsaas.*/install_drsaas 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_drsaas.*/install_drsaas 2/g' ${REPEAT_FILE}
					fi
				fi
			elif [ "X${ne}" == "Xdb" ];then
				typeset install_rep=$(check_repeat "install_db")
				if [ "X${install_rep}" != "X2" ];then
					install_db
					if [ $? -ne 0 ];then
						install_log "ERROR" "install" "Install mysql db is failed"
						sed -i 's/install_db.*/install_db 1/g' ${REPEAT_FILE}
						return 1
					else
						sed -i 's/install_db.*/install_db 2/g' ${REPEAT_FILE}
					fi
				fi
			fi
		fi
	done

	install_log "INFO" "install" "Install DRsaas Successfull"

	return 0
}

#main
install $@
if [ $? -ne 0 ];then
	install_log "ERROR" "install" "script_execute_error"
	exit 1
fi

exit 0
