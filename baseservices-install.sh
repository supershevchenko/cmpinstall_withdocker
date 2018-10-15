set -e
cd `dirname $0`
source ./environment.config

declare -a SWARM_HOSTS=($docker_hosts)
declare -a SWARM_ALIVE_HOST=”“

ssh_connect(){
	echo "==============================================================="
	echo "Set ssh Password for free login,If first Please entry Password."
	echo "==============================================================="
        local ssh_init_path=./ssh-init.sh

        $ssh_init_path $docker_hosts
        if [ $? -ne 0 ]; then
                echo "Fail,please check..."
                exit 1
        fi

        echo "end ssh..."
        sleep 1
	echo "Set Password for free login complete."
}

add_iptables_ports(){
	cat ./add-iptables-ports.sh > /tmp/add-iptables-ports.sh
	sed -i "s/\${exposezuulport}/$exposezuulport/g" /tmp/add-iptables-ports.sh
	for i in "${SWARM_HOSTS[@]}"
	do
		echo "$i add iptables ports."
		scp /tmp/add-iptables-ports.sh $i:/tmp/
		ssh -n $i chmod +x /tmp/add-iptables-ports.sh
		ssh -n $i /tmp/add-iptables-ports.sh
		#ssh -n $i rm -f /tmp/add-iptables-ports.sh
	done
	
}

get_ostype(){
	local ostype=$(ssh -n $i hostnamectl |grep "Operating System" |awk -F ' ' '{print $3}')
	echo $ostype
}

function rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /proc/sys/kernel/random/uuid | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}
#rnd=$(rand 129 248)
 

install_docker(){
	echo "================= Install-set-start docker ================="
	cat ./support-files/daemon.json-template > ./support-files/daemon.json
	sed -i "s/\${local_registory}/$local_registory/g" ./support-files/daemon.json
	for i in "${SWARM_HOSTS[@]}"
	do
		scp ./support-files/daemon.json $i:/tmp/
		scp ./installsoft-docker.sh $i:/tmp/
		check_cpu=`ssh -n $i uname -m`
		if [ "$check_cpu" == "x86_64" ]; then
			echo "Install docker-compose 1.22.0"
			scp ./software/docker-compose-Linux-x86_64 $i:/usr/local/bin/docker-compose
		else
			echo "Install docker-compose fail,not support 32 bit os system"
		fi
		ssh -Tq $i <<EOF
			#curl -sSL https://get.daocloud.io/docker | sh
			#curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
			sh /tmp/installsoft-docker.sh
			chmod +x /usr/local/bin/docker-compose
			modprobe overlay
			mkdir -p /etc/docker
			cat /tmp/daemon.json > /etc/docker/daemon.json
			systemctl daemon-reload
			systemctl enable docker
			systemctl restart docker
		exit
EOF
	echo "docker initialize Complete."
	done
}

create_swarmcluster(){
	echo "================= Create swarm cluster ================="
	local k=1
	local swarm_token=""
	local check_swarm=""
	for i in "${SWARM_HOSTS[@]}"
	do
		if [ $k -eq 1 ]; then
			check_swarm=`ssh -n $i netstat -ant | grep -w '2377' | wc -l`
			if [ $check_swarm -gt 0 ]; then
				echo "$i haved exist swarm cluster.skip it"
			else
				ssh -n $i docker swarm init --advertise-addr=$i
				if [ $? -ne 0 ]; then
					echo "$i init swarm cluster fail,please check."
					exit 43
				fi
				swarm_token=`ssh -n $i docker swarm join-token manager`
				echo $swarm_token |awk -F : '{print $2":"$3}' > ./swarm_token.sh
				chmod +x ./swarm_token.sh
				echo "swarm init success in $i."
			fi
		else
			check_swarm=`ssh -n $i netstat -ant | grep -w '2377' | wc -l`
			if [ $check_swarm -gt 0 ]; then
				echo "$i haved exist swarm cluster.skip it"
			else
				scp ./swarm_token.sh $i:/tmp/
				ssh -n $i /tmp/swarm_token.sh
				if [ $? -eq 0 ]; then
					echo "$i join swarm cluster cussess."
				else
					echo "$i join swarm cluster wrong,please check."
					exit 44
				fi
			fi
		fi
		let k=k+1
	done
}

create_networks(){
	echo "================= Create docker network ================="
        check=`docker network ls |grep "proxy"|wc -l`
        [ "$check" -eq "0" ] && docker network create --attachable=true --driver overlay proxy || echo "--network:proxy already exists.skip."

        check=`docker network ls |grep ${evproject}-network|wc -l`
        [ "$check" -eq "0" ] && docker network create --subnet=${preferrednetworks}.0.0/16 --attachable=true --driver overlay ${evproject}-network || echo "--network:${evproject}-network already exists.skip."
        echo "Create network :${evproject}-dbusernetwork."
        check=`docker network ls |grep ${evproject}-dbusernetwork|wc -l`
        [ "$check" -eq "0" ] && docker network create --subnet=${dbevusernetworks}.0.0/16 --attachable=true --driver overlay ${evproject}-dbusernetwork || echo "--network:${evproject}-dbusernetwork already exists.skip."
        echo "--Create network :${evproject}-dbimnetwork."
        check=`docker network ls |grep ${evproject}-dbimnetwork|wc -l`
        [ "$check" -eq "0" ] && docker network create --subnet=${dbimnetworks}.0.0/16 --attachable=true --driver overlay ${evproject}-dbimnetwork || echo "--network:${evproject}-dbimnetwork already exists.skip."
}

delete_networks(){
	echo "================= Delete docker all network ================="

        check=`docker network ls |grep proxy|wc -l`
        [ "$check" -ne "0" ] && sudo docker network rm proxy

        check=`docker network ls |grep ${evproject}-network|wc -l`
        [ "$check" -ne "0" ] && sudo docker network rm ${evproject}-network

        check=`docker network ls |grep ${evproject}-dbusernetwork|wc -l`
        [ "$check" -ne "0" ] && sudo docker network rm ${evproject}-dbusernetwork

        check=`docker network ls |grep ${evproject}-dbimnetwork|wc -l`
        [ "$check" -ne "0" ] && sudo docker network rm ${evproject}-dbimnetwork

        echo "--Delete docker all_network complete."
}

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

install_proxy(){
	cat ./support-files/docker-flow-proxy-template.yml > ./support-files/docker-flow-proxy.yml
	sed -i "s/\${zuulport}/$exposezuulport/g" ./support-files/docker-flow-proxy.yml
	sed -i "s/\${thirdport}/$exposethirdport/g" ./support-files/docker-flow-proxy.yml
	
	get_alive_swarmnode
	echo "================= Install front proxy ================="
	ssh -n $SWARM_ALIVE_HOST mkdir -p /opt/stack-deploy
	scp ./support-files/docker-flow-proxy.yml $SWARM_ALIVE_HOST:/opt/stack-deploy/
	ssh -n $SWARM_ALIVE_HOST docker stack deploy -c=/opt/stack-deploy/docker-flow-proxy.yml flow-proxy
	[ $? -eq 0 ] && echo "flow proxy deploy OK." || echo "flow proxy deploy fail,please check."
}

deploy_services(){
	get_alive_swarmnode
	echo "================= Deploy services ================="
	ssh -n $SWARM_ALIVE_HOST rm -fr /opt/stack-deploy
	ssh -n $SWARM_ALIVE_HOST mkdir -p /opt/stack-deploy
	scp -r ./ $SWARM_ALIVE_HOST:/opt/stack-deploy/
	#scp ./deploy-services.sh $SWARM_ALIVE_HOST:/opt/stack-deploy/
	#scp ./environment.config $SWARM_ALIVE_HOST:/opt/stack-deploy/
	ssh -n $SWARM_ALIVE_HOST /opt/stack-deploy/deploy-services.sh $install_mode
}

ssh_connect
add_iptables_ports
install_docker
create_swarmcluster
create_networks
deploy_services
install_proxy

get_alive_swarmnode
scp ./check-deploy-services.sh $SWARM_ALIVE_HOST:/tmp/
ssh -n $SWARM_ALIVE_HOST chmod +x /tmp/check-deploy-services.sh
ssh -n $SWARM_ALIVE_HOST /tmp/check-deploy-services.sh ${evproject}
if [ $? -eq 0 ]; then
	sh ./flink-task.sh
	sh ./install-keepalived.sh
else
	echo "not install keepalived and flow-flink,please check."
fi
