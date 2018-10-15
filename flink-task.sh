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

flink_create_task(){
        get_alive_swarmnode
        echo "===============Create flink task================"
        result=`ssh -n $SWARM_ALIVE_HOST docker ps -a |grep flink-task |wc -l`
        if [ $result -gt 0 ]; then
        	ssh -n $SWARM_ALIVE_HOST docker rm flink-task --force
        fi

        ssh -n $SWARM_ALIVE_HOST mkdir -p /tmp/flink
        scp ./software/EvSiddhiFlink-0.0.2-SNAPSHOT.jar $SWARM_ALIVE_HOST:/tmp/flink/
        ssh -n $SWARM_ALIVE_HOST docker run --rm -d --network=${evproject}-network -v /tmp/flink/:/tmp/ --name=flink-task flink:1.5.3 flink run -m jobmanager:8081 -c com.ghca.easyview.SidhhikafkaJob /tmp/EvSiddhiFlink-0.0.2-SNAPSHOT.jar --flink.nativeRunning=false
        sleep 10
        result=`ssh -n $SWARM_ALIVE_HOST docker ps |grep flink-task |wc -l`
        if [ $result -lt 1 ]; then
        	echo "ERROR:Create flink task fail,please."
                exit 97
        else
                echo "Create a new flink task success."
                ssh -n $SWARM_ALIVE_HOST docker rm flink-task --force
        fi
}

flink_create_task
