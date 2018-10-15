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

install_proxy(){
        \cp ./support-files/docker-flow-proxy-template.yml ./support-files/docker-flow-proxy.yml
        sed -i "s/\${zuulport}/$exposezuulport/g" ./support-files/docker-flow-proxy.yml
        sed -i "s/\${thirdport}/$exposethirdport/g" ./support-files/docker-flow-proxy.yml

        get_alive_swarmnode
        echo "================= Install front proxy ================="
        ssh -n $SWARM_ALIVE_HOST mkdir -p /opt/stack-deploy
        scp ./support-files/docker-flow-proxy.yml $SWARM_ALIVE_HOST:/opt/stack-deploy/
        ssh -n $SWARM_ALIVE_HOST docker stack deploy -c=/opt/stack-deploy/docker-flow-proxy.yml flow-proxy
        [ $? -eq 0 ] && echo "flow proxy deploy OK." || echo "flow proxy deploy fail,please check."
}

install_proxy
