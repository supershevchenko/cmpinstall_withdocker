if [ "$(netstat -ant | grep -w ${port} | grep -v grep )" == "" ]
then 
	#systemclt restart nginx.service
	#sleep 5   
	#if [ "$(netstat -ant | grep ${port}| grep -v grep )" == "" ]
	#then  
	systemctl restart keepalived
  	#fi 
fi
