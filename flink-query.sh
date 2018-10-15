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

flink_query_task(){
        get_alive_swarmnode
        result=`ssh -n $SWARM_ALIVE_HOST docker ps -a |grep flink-query |wc -l`
        if [ $result -gt 0 ]; then
                ssh -n $SWARM_ALIVE_HOST docker rm flink-query --force
        	sleep 2
        fi

        echo "===============query flink task================"
        ssh -n $SWARM_ALIVE_HOST docker run -d --network=${evproject}-network --name=flink-query flink:1.5.3 flink list -r -m jobmanager:8081
        sleep 8
        ssh -n $SWARM_ALIVE_HOST docker logs flink-query
        sleep 2
        ssh -n $SWARM_ALIVE_HOST docker logs flink-query
}

flink_query_task
