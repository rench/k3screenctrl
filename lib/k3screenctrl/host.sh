#!/bin/bash
# Copyright (C) 2017 XiaoShan https://www.mivm.cn
# Copyright (C) 2017 L&W <18565615@qq.com>
online_list=($(cat /proc/net/arp | grep : | grep -v "0x0" | grep -v "00:00:00:00:00:00" |awk '{print $1}'))

cat /proc/net/arp | grep : | grep -v "0x0" | grep -v "00:00:00:00:00:00" | awk '{print $1}' > /tmp/mac_ip
iptables -N UPLOAD
iptables -N DOWNLOAD

while read line;do iptables -I FORWARD 1 -s $line -j UPLOAD;done < /tmp/mac_ip
while read line;do iptables -I FORWARD 1 -d $line -j DOWNLOAD;done < /tmp/mac_ip

sleep 1

up_sp=($(iptables -nvx -L FORWARD | grep DOWNLOAD | awk '{print $2}'))
dw_sp=($(iptables -nvx -L FORWARD | grep UPLOAD | awk '{print $2}'))
while read line;do iptables -D FORWARD -s $line -j UPLOAD;done < /tmp/mac_ip
while read line;do iptables -D FORWARD -d $line -j DOWNLOAD;done < /tmp/mac_ip

iptables -Z UPLOAD
iptables -X UPLOAD
iptables -Z DOWNLOAD
iptables -X DOWNLOAD

#echo "${#online_list[@]}"
outstr=""
online_count=0
for ((i=0;i<${#online_list[@]};i++))
do
	x=$(expr "${#online_list[@]}" - "$i" - "1")
	mac_hostname=($(cat /tmp/dhcp.leases | grep ${online_list[i]} | awk '{print $2,$4}'))
	if [[ ${mac_hostname[1]} = "" ]]; then
		continue
	else
		outstr=${outstr}'\n'${mac_hostname[1]}
	fi
	outstr=${outstr}'\n'${up_sp[x]}
	outstr=${outstr}'\n'${dw_sp[x]}
	mac=${mac_hostname[0]//:/}
	mac=$(echo ${mac:0:6} | tr '[a-z]' '[A-Z]')
	logo=$(cat /lib/k3screenctrl/verdor.txt | grep ${mac} | head -1 | awk '{print $1}')
	if [[ ${logo} = "" || ${logo}>29 ]]; then
		outstr=${outstr}'\n'"0"
	else
		outstr=${outstr}'\n'${logo}
	fi
	let online_count+=1
done
echo -e ${online_count}${outstr}