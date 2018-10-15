if [ "$(netstat -ant | grep -w 21992 | grep -v grep )" == "" ]
then 
	#systemclt restart nginx.service
	#sleep 5   
	#if [ "$(netstat -ant | grep 21992| grep -v grep )" == "" ]
	#then  
	systemctl restart keepalived
  	#fi 
fi
