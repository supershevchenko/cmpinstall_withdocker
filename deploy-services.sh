set -e
cd `dirname $0`
source ./environment.config

change_variables(){
	#------------copy from template  -----------------------
	cat ./support-files/docker-composev3-template.yml > ./support-files/docker-composev3.yml
	cat ./support-files/docker-composev3-cluster-template.yml > ./support-files/docker-composev3-cluster.yml

	#------------change local_mirror env-----------------------
	sed -i "s/\${local_registory}/$local_registory/g" ./support-files/docker-composev3.yml
	sed -i "s/\${local_registory}/$local_registory/g" ./support-files/docker-composev3-cluster.yml

	#------------change single-mode env-----------------------
	cat ./support-files/docker-composev3.yml > ./support-files/docker-compose.single.yml

	sed -i "s/\${evproject}/$evproject/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${configprofile}/$configprofile/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${configlabel}/$configlabel/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${exposezuulport}/$exposezuulport/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${exposethirdport}/$exposethirdport/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${preferrednetworks}/$preferrednetworks/g" ./support-files/docker-compose.single.yml

	sed -i "s/\${git_uri}/$git_uri/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${git_username}/$git_username/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${git_password}/$git_password/g" ./support-files/docker-compose.single.yml

	sed -i "s/\${mysql_root_password}/$mysql_root_password/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${mysql_im_password}/$mysql_im_password/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${mysql_evuser_password}/$mysql_evuser_password/g" ./support-files/docker-compose.single.yml

	sed -i "s/\${redis_password}/$redis_password/g" ./support-files/docker-compose.single.yml

	sed -i "s/\${artemis_username}/$artemis_username/g" ./support-files/docker-compose.single.yml
	sed -i "s/\${artemis_password}/$artemis_password/g" ./support-files/docker-compose.single.yml

	#------------change cluster-mode env-----------------------
        #envsubst < docker-composev3-cluster.yml > docker-compose.cluster.yml

	cat ./support-files/docker-composev3-cluster.yml > ./support-files/docker-compose.cluster.yml
	sed -i "s/\${evproject}/$evproject/g" ./support-files/docker-compose.cluster.yml

	sed -i "s/\${mysql_root_password}/$mysql_root_password/g" ./support-files/docker-compose.cluster.yml
	sed -i "s/\${mysql_im_password}/$mysql_im_password/g" ./support-files/docker-compose.cluster.yml
	sed -i "s/\${mysql_evuser_password}/$mysql_evuser_password/g" ./support-files/docker-compose.cluster.yml

	sed -i "s/\${redis_password}/$redis_password/g" ./support-files/docker-compose.cluster.yml

	sed -i "s/\${mongodb_root_password}/$mongodb_root_password/g" ./support-files/docker-compose.cluster.yml
	sed -i "s/\${mongodb_username}/$mongodb_username/g" ./support-files/docker-compose.cluster.yml
	sed -i "s/\${mongodb_user_password}/$mongodb_user_password/g" ./support-files/docker-compose.cluster.yml
}

single_install(){
	change_variables
        cat ./support-files/docker-compose.single.yml > ./support-files/docker-compose.stack.yml
        docker stack deploy -c=./support-files/docker-compose.stack.yml $evproject
	[ $? -eq 0 ] && echo "deploy services complete..." || echo "deploy services fail,please check."

}

cluster_install(){
	change_variables
        rm -f ./support-files/docker-compose.stack.yml
        docker-compose -f ./support-files/docker-compose.single.yml -f ./support-files/docker-compose.cluster.yml config > ./support-files/docker-compose.stack.yml
        docker stack deploy -c=./support-files/docker-compose.stack.yml $evproject 
	[ $? -eq 0 ] && echo "deploy services complete..." || echo "deploy services fail,please check."
}

delete_stack(){
	echo "--Delete docker container."
	check=`docker stack ls |grep ${evproject} |wc -l`
	[ "$check" -ne "0" ] && docker stack rm $evproject
	[ $? -eq 0 ] && echo "rm stack deploy services complete..." || echo "rm stack deploy services fail,please check."
	sleep 10
}

args_c=$#
if [ $args_c -eq 1 ]
then
	args_v=$1
elif [ $args_c -gt 1 ]
then
	echo "args wrong,too much args.only accept most one args or without."
	exit 200
else
	args_v=100
fi

if [ $args_c -eq 1 -a $args_v -eq 1 ]
then
	single_install
elif [ $args_c -eq 1 -a $args_v -eq 2 ]
then
	cluster_install
elif [ $args_c -eq 1 -a $args_v -eq 3 ]
then
	delete_stack
else

	echo "**********************************"
	echo "*     1---install single mode    *"
	echo "*     2---install cluster mode   *"
	echo "*     3---uninstall              *"
	echo "*     0---Cancel install         *"
	echo "**********************************"
	while read -p "Please Select: " item
	do
        	case $item in
                	1)
                        	echo "--Install single mode begin."
                        	single_install
                        	break
                	;;
                	2)
                        	echo "--Install cluster mode begin."
                        	cluster_install
                        	break
                	;;
                	3)
                        	echo "--unistall stack project. begin."
                        	delete_stack
                        	break
                	;;
			0)
				echo "Cancel install.GoodBye."
				exit 0
		esac
		echo "-----Error,Please retry-----"
done
fi
