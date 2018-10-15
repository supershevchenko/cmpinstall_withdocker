ostype=`hostnamectl | grep "Operating System" | awk '{print $3$5}'`
if [ "$ostype" == "CentOS7" ]; then
	firewall-cmd --permanent --zone=public --add-port=2377/tcp
	firewall-cmd --permanent --zone=public --add-port=7946/tcp
	firewall-cmd --permanent --zone=public --add-port=7946/udp
	firewall-cmd --permanent --zone=public --add-port=4789/udp

	firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="224.0.0.18/24" accept"
	firewall-cmd --permanent --add-rich-rule="rule family="ipv4" destination address="224.0.0.18/24" accept"
	firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --destination 224.0.0.18 --protocol vrrp -j ACCEPT
	firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --source 224.0.0.18 --protocol vrrp -j ACCEPT
	firewall-cmd --permanent --zone=public --add-port=${exposezuulport}/tcp

	firewall-cmd --reload
elif [ "$ostype" = "Ubuntu" ]; then
	echo "$ostype not support set iptables!"
else
	echo "$ostype not support set iptables!"
	exit 98
fi

