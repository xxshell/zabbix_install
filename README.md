Zabbix离线一键部署
=
1、版本信息与部署环境
-
[安装包下载](http://home.aalook.com:81/%E7%BD%91%E7%AB%99%E4%B8%8B%E8%BD%BD%E7%9B%AE%E5%BD%95/Zabbix/%E7%A6%BB%E7%BA%BF%E5%AE%89%E8%A3%85%E5%8C%85/) 
* Zabbix4.4.1-install软件包  
WEB：Apache/2.4.6  
PHP：7.0.33  
数据库：MariaDB5.5.64  
安装包依赖环境：CentOS7.X/RedHat7.X最小安装（mini），内存1G内存，磁盘容量大于5G

2、安装部署
-
**为保证软件部署的稳定性建议使用纯净的操作系统进行安装**  
### ①上传软件包到操作系统中,通过unzip解压安装包:  
```
unzip Zabbix4.4.1-install.zip  
cd Zabbix4.4.1-install  
chmod +x Zabbix-install.sh  
sh Zabbix-install.sh  
```
如果没有unzip安装包可以下载rpm安装包通过”rpm -i“进行手动安装也可以通过yum安装

### ②配置Mysql数据库root密码  
建议使用较为复杂的密码，但是不建议使用特殊字符。

### ③安装完成提示信息  
根据安装提示内容打开WEB进行访问，将提示的信息输入到Zabbix中。   

如您遇到部署问题，可以在[未来往事的博客](http://www.xxshell.com)搜索zabbix,也可以在github下进行问题回复。
