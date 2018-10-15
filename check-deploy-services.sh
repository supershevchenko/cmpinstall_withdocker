set -e
cd `dirname $0`
IFS=$'\n'

evproject=$1
if [ $# -ne 1 ]; then
	echo "args error,please use: check-deploy-services.sh \$deploy_name"
	exit 77
fi

while :
do
	docker stack ps ${evproject} > /dev/null
	if [ $? -ne 0 ];then
		echo "Nothing found in stack: $evproject ,please check."
		exit 88
	fi

	k=1
	total=`docker stack services ${evproject} | grep -v 'ID' | wc -l`

	for i in `docker stack services ${evproject} | grep -v 'ID'`
	do
		var1=`echo $i | awk '{print $4}' | awk -F '/' '{print $1}'`
		var2=`echo $i | awk '{print $4}' | awk -F '/' '{print $2}'`
		if [ $var1 -eq $var2 ]; then
			if [ $k -eq $total ]; then
				echo "deploy all services is starting and running,It is ok!"
				exit 0
			fi
			let k=$k+1
			continue
		else
			break
		fi
	done
	echo "Wait a moment,Being checked."
	sleep 10
done
