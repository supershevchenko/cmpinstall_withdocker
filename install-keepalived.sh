set -e
cd `dirname $0`
source ./environment.config

declare -a SWARM_HOSTS=($docker_hosts)
declare -a SWARM_ALIVE_HOST=”“

function rand(){ 
    min=$1  
    max=$(($2-$min+1))
    num=$(cat /proc/sys/kernel/random/uuid | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}

get_ostype(){
        local ostype=$(ssh -n $i hostnamectl |grep "Operating System" |awk -F ' ' '{print $3}')
        echo $ostype 
}

change_keepalived_conf(){
        echo "change keepalived config file."
        echo "================= Pre-configuration keepalived ================="
        local line=""
        cat ./support-files/monitor-service-template.sh > ./support-files/monitor-service.sh
        cat ./support-files/keepalived-template.conf > ./support-files/keepalived.conf
        sed -i "s/\${port}/$exposezuulport/g" ./support-files/monitor-service.sh
        #front service LVS load balancing:
        #for i in "${SWARM_HOSTS[@]}"
        #do
        #       \cp -f ./support-files/rip.template ./support-files/rip.conf
        #       sed -i "s/\${rip}/$i/g" ./support-files/rip.conf
        #       line=$(cat ./support-files/keepalived.conf |wc -l) && line=$line"d"
        #       sed -i "$line" ./support-files/keepalived.conf
        #       cat ./support-files/rip.conf >> ./support-files/keepalived.conf
        #done

        sed -i "s/\${vip}/$keepalived_vip/g" ./support-files/keepalived.conf
        sed -i "s/\${port}/$exposezuulport/g" ./support-files/keepalived.conf

        local k=100
	local v=$(rand 129 248)
        local ethname=""
        for i in "${SWARM_HOSTS[@]}"
        do
                ethname=$(ssh -n $i ip a|grep $i |awk -F ' ' '{print $NF}')
                sed -i "s/\${eth0}/$ethname/g" ./support-files/keepalived.conf
                sed -i "s/\${vrid}/$v/g" ./support-files/keepalived.conf
                sed -i "s/\${priority}/$k/g" ./support-files/keepalived.conf

                \cp -f ./support-files/rip.template ./support-files/rip.conf
                \cp -f ./support-files/keepalived.conf /tmp/keepalived.conf.temp
                sed -i "s/\${rip}/$i/g" ./support-files/rip.conf
                sed -i "s/\${port}/$exposezuulport/g" ./support-files/rip.conf
                line=$(cat ./support-files/keepalived.conf |wc -l) && line=$line"d"
                sed -i "$line" ./support-files/keepalived.conf
                cat ./support-files/rip.conf >> ./support-files/keepalived.conf
                echo "}" >> ./support-files/keepalived.conf

                scp ./support-files/keepalived.conf $i:/tmp/
                cat /tmp/keepalived.conf.temp > ./support-files/keepalived.conf
                rm -f /tmp/keepalived.conf.temp
                #sed -i "s/virtual_router_id $v/virtual_router_id \${vrid}/g" ./support-files/keepalived.conf
                sed -i "s/priority $k/priority \${priority}/g" ./support-files/keepalived.conf
                #let v=v+1
                let k=k-10
        done
}


install_keepalived(){
        echo "================= Install keepalived ================="
        local ostype=""
        change_keepalived_conf
        for i in "${SWARM_HOSTS[@]}"
        do
                ostype=$(get_ostype $i)
                echo "$i:install keepalived."
                if [ "$ostype" == "CentOS" ]; then
                        ssh -n $i yum install -y  keepalived openssl* libnfnetlink*
                elif [ "$ostype" = "Ubuntu" ]; then
                        ssh -n $i apt-get install -y  keepalived openssl* libnfnetlink*
                else
                        echo "Only support Centos and Ubutu Operating System"
                        exit 98
                fi
                scp ./support-files/monitor-service.sh $i:/usr/local/bin/
               	echo "$i:Start keepalived service."
		ssh -Tq $i <<EOF
                	cat /tmp/keepalived.conf > /etc/keepalived/
			chmod +x /usr/local/bin/monitor-service.sh
                	systemctl restart keepalived
                	systemctl enable keepalived
		exit
EOF
        done
}

install_keepalived
