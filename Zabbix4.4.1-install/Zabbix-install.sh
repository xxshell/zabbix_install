#!/bin/sh
process()
{
install_date="zabbix_install_$(date +%Y-%m-%d_%H:%M:%S).log"
printf "
#######################################################################
#                 欢迎使用Zabbix离线一键部署脚本                      #
#             脚本适配环境CentOS7+/Radhat7+、内存1G+                  #
#             避免软件包产生冲突建议使用纯净的操作系统进行安装！      #
#             更多信息请访问 https://xxshell.com                      #
#######################################################################
"

while :; do echo
    read -p "设置Mysql数据库root密码（建议使用字母+数字）: " Database_Password 
    [ -n "$Database_Password" ] && break
done

#
echo "#######################################################################"
echo "#                                                                     #"
echo "#                    正在软件与编译环境 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
rpm -Uvh zabbix_APP_RPM/*.rpm --force
#rpm安装httpd、php、Mysql、编译环境等
echo "#######################################################################"
echo "#                                                                     #"
echo "#                  正在关闭SElinux策略 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"
setenforce 0
#临时关闭SElinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
#永久关闭SElinux
echo $?="关闭SElinux成功"

echo "#######################################################################"
echo "#                                                                     #"
echo "#                  正在配置Firewall策略 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp --permanent
 
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
#放行TCP80、10050、10051端口
echo "#######################################################################"
echo "#                                                                     #"
echo "#                 正在配置Mariadb数据库 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
systemctl start mariadb
systemctl enable mariadb
echo "#######################################################################"
echo "#                                                                     #"
echo "#                 正在配置PHP环境 请稍等~                             #"
echo "#                                                                     #"
echo "#######################################################################"
systemctl start php-fpm
systemctl enable php-fpm
echo "#######################################################################"
echo "#                                                                     #"
echo "#                 正在配置Apache服务 请稍等~                          #"
echo "#                                                                     #"
echo "#######################################################################"
systemctl start httpd
systemctl enable httpd
echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在创建Zabbix用户 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"
groupadd zabbix
useradd zabbix -g zabbix -s /sbin/nologin
echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在编译Zabbix软件 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"
chmod 776 -R zabbix-4.4.1
#解决权限不足问题
cd zabbix-4.4.1
#切换到zabbix安装包

./configure  \
        --prefix=/usr/local/zabbix  \
        --enable-server  \
        --enable-agent  \
        --with-mysql=/usr/bin/mysql_config   \
        --with-net-snmp  \
        --with-libcurl  \
        --with-libxml2  \
        --enable-java  
 
make -j 2 && make install 
#编译安装Zabbix
echo $?="Zabbix编译完成"

echo "#######################################################################"
echo "#                                                                     #"
echo "#                   正在配置Mariadb数据库 请稍等~                     #"
echo "#                                                                     #"
echo "#######################################################################"
mysqladmin -u root password "$Database_Password"
echo "---mysqladmin -u root password "$Database_Password""
#修改数据库密码

mysql -uroot -p$Database_Password -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_general_ci;"
echo $?="正在创建zabbix数据库"
#将创建数据的命令重定向到数据库中

mysql -uroot -p$Database_Password -e "use zabbix;"
echo $?="对zabbix数据库进行操作"
#将选中的命令重定向到数据库中

mysql -uroot -p$Database_Password  zabbix < database/mysql/schema.sql
mysql -uroot -p$Database_Password  zabbix < database/mysql/images.sql
mysql -uroot -p$Database_Password  zabbix < database/mysql/data.sql
echo $?="对zabbix数据库进行操作"
#zabbix数据库导入

echo "#######################################################################"
echo "#                                                                     #"
echo "#                    正在配置Zabbix软件 请稍等~                       #"
echo "#                                                                     #"
echo "#######################################################################"
cp misc/init.d/fedora/core/* /etc/init.d/
#拷贝启动文件到/etc/init.d/下
echo $?="拷贝启动文件到/etc/init.d/下"

sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#" /etc/init.d/zabbix_server
sed -i "s#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#" /etc/init.d/zabbix_agentd
#编辑启动模块下
echo $?="编辑启动模块"

sed -i "s|# DBHost=localhost|DBHost=localhost|" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "s|DBUser=zabbix|DBUser=root|" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "s|# DBPassword=|DBPassword=$Database_Password|" /usr/local/zabbix/etc/zabbix_server.conf
#编辑Zabbix配置配置文件
echo $?="编辑Zabbix配置配置文件"

/etc/init.d/zabbix_server restart
/etc/init.d/zabbix_agentd restart
#启动zabbix服务
 
systemctl restart zabbix_server 
systemctl restart zabbix_agentd
#重启验证服务
#通过”netstat -an | grep LIS“查看10050、10051端口能否正常监听，如果不能正常监听可能数据库或配置文件有问题。
 
systemctl enable zabbix_server
systemctl enable zabbix_agentd
echo $?="配置Zabbix完成"
echo "#######################################################################"
echo "#                                                                     #"
echo "#                    正在配置PHP.ini 请稍等~                          #"
echo "#                                                                     #"
echo "#######################################################################"
sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 600/" /etc/php.ini
sed -i "s/max_input_time = 60/max_input_time = 600/" /etc/php.ini
sed -i "s#;date.timezone =#date.timezone = Asia/Shanghai#" /etc/php.ini
#修改PHP配置文件
echo $?="PHP.inin配置完成完成"

echo "#######################################################################"
echo "#                                                                     #"
echo "#               正在配置Zabbix前台文件 请稍等~                        #"
echo "#                                                                     #"
echo "#######################################################################"

rm -rf /var/www/html/*
#清空网站根目录
cp -r frontends/php/* /var/www/html/
#复制PHP文件到网站根目录
chown -R apache:apache  /var/www/html/
chmod -R 777 /var/www/html/conf/
#给网站目录添加属主
echo $?="网页文件拷贝完成"

echo "#######################################################################"
echo "#                                                                     #"
echo "#                       正在重启服务 请稍等~                          #"
echo "#                                                                     #"
echo "#######################################################################"

systemctl restart php-fpm httpd mariadb zabbix_server zabbix_agentd
echo $?="服务启动完成"

echo "--------------------------- 安装已完成 ---------------------------"
echo " 数据库名     :zabbix"
echo " 数据库用户名 :root"
echo " 数据库密码   :"$Database_Password
echo " 网站目录     :/var/www/html"
echo " Zabbix登录   :http://主机IP"
echo " 安装日志文件 :/var/log/"$install_date
echo "------------------------------------------------------------------"
echo " 如果安装有问题请反馈安装日志文件。"
echo " 使用有问题请在这里寻求帮助:https://www.xxshell.com"
echo " 电子邮箱:admin@xxshell.com"
echo "------------------------------------------------------------------"
}
LOGFILE=/var/log/"zabbix_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-