set -e
cd `dirname $0`
source ./environment.config

declare -a SWARM_HOSTS=($docker_hosts)
declare -a SWARM_ALIVE_HOST=”“

get_alive_swarmnode(){
        SWARM_ALIVE_HOST=""
        for i in "${SWARM_HOSTS[@]}"
        do
                echo "check alive swarm node."
                host_name=`ssh -n $i hostname`
                check_alived=`ssh -n $i docker node ls | grep $host_name | grep 'Ready' | grep 'Active' | wc -l`
                if [ $check_alived -eq 1 ]; then
                        SWARM_ALIVE_HOST="$i"
                        break
                else
                        echo "$i haved problem,please check itm,use: docker node ls."
                fi
        done
        if [ "$SWARM_ALIVE_HOST" == "" ]; then
                echo "there is not found docker swarm cluster,please check."
                exit 35
        fi
}

scale_services(){
        get_alive_swarmnode
        echo "================= Scale services ================="
        ssh -Tq $SWARM_ALIVE_HOST <<EOF
		echo "start scale ${evproject}_dbevuser"
        	docker service scale ${evproject}_dbevuser=2 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_dbevuser fail,please check."
		fi
		
		echo "start scale ${evproject}_dbim"
                docker service scale ${evproject}_dbim=2 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_dbim fail,please check."
		fi

		echo "start scale ${evproject}_evconfig"
                docker service scale ${evproject}_evconfig=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_ evconfigfail,please check."
		fi

		echo "start scale ${evproject}_evtaskengine"
                docker service scale ${evproject}_evtaskengine=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evtaskengine fail,please check."
		fi

		echo "start scale ${evproject}_evcmdb"
                docker service scale ${evproject}_evcmdb=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evcmdb fail,please check."
		fi

		echo "start scale ${evproject}_evi18nserver"
                docker service scale ${evproject}_evi18nserver=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evi18nserver fail,please check."
		fi

		echo "start scale ${evproject}_evgatherframe"
                docker service scale ${evproject}_evgatherframe=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evgatherframe fail,please check."
		fi

		echo "start scale ${evproject}_evvsphereagent"
                docker service scale ${evproject}_evvsphereagent=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evvsphereagent fail,please check."
		fi

		echo "start scale ${evproject}_evvspheremanager"
                docker service scale ${evproject}_evvspheremanager=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evvspheremanager fail,please check."
		fi

		echo "start scale ${evproject}_evalarmcenter"
                docker service scale ${evproject}_evalarmcenter=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evalarmcenter fail,please check."
		fi

		echo "start scale ${evproject}_evtaskjob"
                docker service scale ${evproject}_evtaskjob=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evtaskjob fail,please check."
		fi

		echo "start scale ${evproject}_evservicemonitor"
                docker service scale ${evproject}_evservicemonitor=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evservicemonitor fail,please check."
		fi

		echo "start scale ${evproject}_evzuulmanager"
                docker service scale ${evproject}_evzuulmanager=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evzuulmanager fail,please check."
		fi

		echo "start scale ${evproject}_evimtask"
                docker service scale ${evproject}_evimtask=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evimtask fail,please check."
		fi

		echo "start scale ${evproject}_evimthird"
                docker service scale ${evproject}_evimthird=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evimthird fail,please check."
		fi

		echo "start scale ${evproject}_evimapiprovider"
                docker service scale ${evproject}_evimapiprovider=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evimapiprovider fail,please check."
		fi

		echo "start scale ${evproject}_evimweb"
                docker service scale ${evproject}_evimweb=3 > /dev/null
		if [ $? -ne 0 ] ; then
			echo "Scale ${evproject}_evimweb fail,please check."
		fi
	exit
EOF
}

scale_services
