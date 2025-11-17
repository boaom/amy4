#!/bin/bash
#==========================#
###### Author: CuteBi ######
#==========================#

#Stop v2ray & delete v2ray files.
Delete() {
	systemctl disable v2ray.service
	rm -rf /etc/init.d/v2ray /lib/systemd/system/v2ray.service
	if [ -f "${v2ray_install_directory:=/usr/local/v2ray}/v2ray.init" ]; then
		"$v2ray_install_directory"/v2ray.init stop
		rm -rf "$v2ray_install_directory"
	fi
}

#Print error message and exit.
Error() {
	echo $echo_e_arg "\033[41;37m$1\033[0m"
	echo -n "remove v2ray?[y]: "
	read remove
	echo "$remove"|grep -qi 'n' || Delete
	exit 1
}

makeHttpInbound() {
local port="$1"
local tlsConfig="$2"
local protocol="$3"
echo '{
			"port": "'$port'",
			"protocol": "'$protocol'",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"level": 0,
					"alterId": 0
				}]
			},
			"streamSettings": {
				"sockopt": {
					"tcpFastOpen": '$tcpFastOpen'
				},
				"network": "tcp",
				"tcpSettings": {
					"header": {
						"type": "http"
					}
				}'$tlsConfig'
			}
		}'
}

makeWSInbound() {
local port="$1"
local tlsConfig="$2"
local url="$3"
local protocol="$4"
echo '{
			"port": "'$port'",
			"protocol": "'$protocol'",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"flow": "xtls-rprx-direct",
					"level": 0,
					"alterId": 0
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"sockopt": {
					"tcpFastOpen": '$tcpFastOpen'
				},
				"network": "ws",
				"wsSettings": {
					"path": "'$url'"
				}'$tlsConfig'
			}
		}'
}

makeTcpInbound() {
local port="$1"
local tlsConfig="$2"
local protocol="$3"
echo '{
			"port": "'$port'",
			"protocol": "'$protocol'",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"flow": "xtls-rprx-direct",
					"level": 0,
					"alterId": 0
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"sockopt": {
					"tcpFastOpen": '$tcpFastOpen'
				},
				"network": "tcp"'$tlsConfig'
			}
		}'
}

makeKcpInbound() {
local port="$1"
local tlsConfig="$2"
local headerType="$3"
local protocol="$4"
echo '{
			"port": "'$port'",
			"protocol": "'$protocol'",
			"settings": {
				"udp": true,
				"clients": [{
					"id": "'$uuid'",
					"flow": "xtls-rprx-direct",
					"level": 0,
					"alterId": 0
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "kcp",
				"kcpSettings": {
					"header": {
						"type": "'$headerType'"
					}
				}'$tlsConfig'
			}
		}'
}

#Input v2ray.json
Config() {
	clear
	uuid=`cat /proc/sys/kernel/random/uuid`
	tcpFastOpen=`[ -f /proc/sys/net/ipv4/tcp_fastopen ] && echo -n 'true' || echo -n 'false'`
	echo -n "请输入v2ray安装目录(默认/usr/local/v2ray): "
	read v2ray_install_directory
	echo -n "安装UPX压缩版本?[n]: "
	read v2ray_UPX
	echo "$v2ray_UPX"|grep -qi 'y' && v2ray_UPX="upx" || v2ray_UPX=""
	echo $echo_opt_e "options(tls默认为自签名证书, 如有需要请自行更改):
	\r\t1. tcp_http(vmess)
	\r\t2. WebSocket(vmess)
	\r\t3. WebSocket+tls(vless)
	\r\t4. mkcp(vmess)
	\r\t5. mkcp+tls(vless)
	\r\t6. tcp+xtls(vless)
	\r请输入你的选项(用空格分隔多个选项):"
	read v2ray_inbounds_options
	for opt in $v2ray_inbounds_options; do
		case $opt in
			1)
				echo -n "请输入v2ray http端口: "
				read v2ray_http_port
			;;
			2)
				echo -n "请输入v2ray webSocket端口: "
				read v2ray_ws_port
				echo -n "请输入v2ray WebSocket请求头的Path(默认为/): "
				read v2ray_ws_path
				v2ray_ws_path=${v2ray_ws_path:-/}
			;;
			3)
				echo -n "请输入v2ray webSocket tls端口: "
				read v2ray_ws_tls_port
				echo -n "请输入v2ray WebSocket请求头的Path(默认为/): "
				read v2ray_ws_tls_path
				v2ray_ws_tls_path=${v2ray_ws_tls_path:-/}
			;;
			4)
				echo -n "请输入v2ray mKCP端口: "
				read v2ray_mkcp_port
			;;
			5)
				echo -n "请输入v2ray mKCP xtls端口: "
				read v2ray_mkcp_xtls_port
			;;
			6)
				echo -n "请输入v2ray tcp xtls端口: "
				read v2ray_tcp_xtls_port
			;;
		esac
	done
}



GetAbi() {
	machine=`uname -m`
	#mips[...] use 'le' version
	if echo "$machine"|grep -q 'mips64'; then
		machine='mips64le'
	elif echo "$machine"|grep -q 'mips'; then
		machine='mipsle'
	elif echo "$machine"|grep -Eq 'i686|i386'; then
		machine='386'
	elif echo "$machine"|grep -Eq 'armv5'; then
		machine='armv5'
	elif echo "$machine"|grep -Eq 'armv6'; then
		machine='armv6'
	elif echo "$machine"|grep -Eq 'armv7'; then
		machine='armv7'
	elif echo "$machine"|grep -Eq 'armv8|aarch64'; then
		machine='arm64'
	elif echo "$machine"|grep -q 's390x'; then
		machine='s390x'
	else
		machine='amd64'
	fi
}


#install v2ray v2ray.init v2ray.service
InstallFiles() {
	GetAbi
	if echo "$machine" | grep -q 'mips'; then
		cat /proc/cpuinfo | grep -qiE 'fpu|neon|vfp|softfp|asimd' || softfloat='_softfloat'
	fi
	mkdir -p "${v2ray_install_directory:=/usr/local/v2ray}" || Error "Create v2ray install directory failed."
	cd "$v2ray_install_directory" || Error "Create cns install directory failed."
	#install v2ray
	$download_tool_cmd v2ray https://codeberg.org/asdf88/stn-28/raw/branch/master/v2ray5.3.0/v2ray-linux-${machine}${softfloat} || Error "v2ray download failed."
	$download_tool_cmd v2ray.init https://codeberg.org/asdf88/stn-28/raw/branch/master/v2ray5.3.0/v2ray.init || Error "v2ray.init download failed."
	[ -f '/etc/rc.common' ] && rcCommon='/etc/rc.common'
	sed -i "s~#!/bin/sh~#!$SHELL $rcCommon~" v2ray.init
	sed -i "s~\[v2ray_install_directory\]~$v2ray_install_directory~g" v2ray.init
	sed -i "s~\[v2ray_tcp_port_list\]~$v2ray_http_port $v2ray_http_tls_port $v2ray_ws_port $v2ray_ws_tls_port~g" v2ray.init
	sed -i "s~\[v2ray_udp_port_list\]~$v2ray_mkcp_port $v2ray_mkcp_xtls_port~g" v2ray.init
	ln -s "$v2ray_install_directory/v2ray.init" /etc/init.d/v2ray
	chmod -R +rwx "$v2ray_install_directory" /etc/init.d/v2ray
	if which systemctl && [ -z "$(systemctl --failed|grep -q 'Host is down')" ]; then
		$download_tool_cmd /lib/systemd/system/v2ray.service https://codeberg.org/asdf88/stn-28/raw/branch/master/v2ray5.3.0/v2ray.service || Error "v2ray.service download failed."
		chmod +rwx /lib/systemd/system/v2ray.service
		sed -i "s~\[v2ray_install_directory\]~$v2ray_install_directory~g" /lib/systemd/system/v2ray.service
		systemctl daemon-reload
	fi
	#make json config
	local tlsConfig=',
			"security": "tls",
			"tlsSettings": {
				"certificates": ['"`./v2ray tls cert`"']
			}'
	for opt in $v2ray_inbounds_options; do
		[ -n "$in_networks" ] && in_networks="$in_networks, "
		case $opt in
			1) in_networks="$in_networks"`makeHttpInbound "$v2ray_http_port" "" vmess`;;
			2) in_networks="$in_networks"`makeWSInbound "$v2ray_ws_port" "" "$v2ray_ws_path" vmess`;;
			3) in_networks="$in_networks"`makeWSInbound "$v2ray_ws_tls_port" "$tlsConfig" "$v2ray_ws_tls_path" vless`;;
			4) in_networks="$in_networks"`makeKcpInbound "$v2ray_mkcp_port" "" utp vmess`;;
			5) in_networks="$in_networks"`makeKcpInbound "$v2ray_mkcp_xtls_port" "${tlsConfig//tls/xtls}" none vless`;;
			6) in_networks="$in_networks"`makeTcpInbound "$v2ray_tcp_xtls_port" "${tlsConfig//tls/xtls}" vless`;;
		esac
	done
	echo $echo_E_arg '
	{
		"log" : {
			"loglevel": "none"
		},
		"inbounds": ['"$in_networks"'],
		"outbounds": [{
			"protocol": "freedom"
		}]
	}
	' >v2ray.json
}

#install initialization
InstallInit() {
	echo -n "make a update?[n]: "
	read update
	PM=`which apt-get || which yum`
	echo "$update"|grep -qi 'y' && $PM -y update
	$PM -y install curl wget #unzip
	type curl && download_tool_cmd='curl -L --connect-timeout 7 -ko' || download_tool_cmd='wget -T 60 --no-check-certificate -O'
	getip_urls="http://myip.dnsomatic.com/ http://ip.sb/"
	for url in $getip_urls; do
		ip=`$download_tool_cmd - "$url"`
	done
}

AddAutoStart() {
	if [ -n "$rcCommon" ]; then
		if /etc/init.d/v2ray enable; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: /etc/init.d/v2ray disable\033[0m"
			return
		fi
	fi
	if type systemctl &>/dev/null && [ -z "$(systemctl --failed|grep -q 'Host is down')" ]; then
		if systemctl enable v2ray &>/dev/null; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: systemctl disable v2ray\033[0m"
			return
		fi
	fi
	if type chkconfig &>/dev/null; then
		if chkconfig --add v2ray &>/dev/null && chkconfig v2ray on &>/dev/null; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: chkconfig v2ray off\033[0m"
			return
		fi
	fi
	if [ -d '/etc/rc.d/rc5.d' -a -f '/etc/init.d/v2ray' ]; then
		if ln -s '/etc/init.d/v2ray' '/etc/rc.d/rc5.d/S99v2ray'; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: rm -f /etc/rc.d/rc5.d/S99v2ray\033[0m"
			return
		fi
	fi
	if [ -d '/etc/rc5.d' -a -f '/etc/init.d/v2ray' ]; then
		if ln -s '/etc/init.d/v2ray' '/etc/rc5.d/S99v2ray'; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: rm -f /etc/rc5.d/S99v2ray\033[0m"
			return
		fi
	fi
	if [ -d '/etc/rc.d' -a -f '/etc/init.d/v2ray' ]; then
		if ln -s '/etc/init.d/v2ray' '/etc/rc.d/S99v2ray'; then
			echo -e "\033[44;37m  已添加开机自启, 如需关闭请执行: rm -f /etc/rc.d/S99v2ray\033[0m"
			return
		fi
	fi
	echo -e "\033[44;37m  没有添加开机自启, 如需开启请手动添加\033[0m"
}

outputVmessLink() {
	[ -z "$ip" ] && return
	for opt in $v2ray_inbounds_options; do
		case $opt in
			1)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": '$v2ray_http_port', "aid": "0", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "tcp", "path": "/", "ps": "http_'$ip:$v2ray_http_port'", "tls": "", "type": "http", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rhttp:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			2)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_ws_port'", "aid": "0", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "ws", "path": "'$v2ray_ws_path'", "ps": "ws_'$ip:$v2ray_ws_port'", "tls": "", "type": "none", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rws:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			3)
				#link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_ws_tls_port'", "aid": "0", "host": "cutebi.taobao69.cn", "id": "'$uuid'", "net": "ws", "path": "'$v2ray_ws_tls_path'", "ps": "ws+tls_'$ip:$v2ray_ws_tls_port'", "tls": ".cutebi.taobao69.cn", "type": "none", "v": "2"}'|base64 -w 0`
				#echo $echo_e_arg "\033[45;37m\rws+tls:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
				echo $echo_e_arg "\033[45;37m\rws+tls:\033[0m\n\t\033[4;35mvless://${uuid}@${ip}:${v2ray_ws_tls_port}?path=${v2ray_ws_tls_path}&security=tls&encryption=none&host=cutebi.taobao69.cn&type=ws&allowInsecure=1#ws+tls_${ip}:${v2ray_ws_tls_port}\033[0m"
				
			;;
			4)
				link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_mkcp_port'", "aid": "0", "host": "", "id": "'$uuid'", "net": "kcp", "path": "", "ps": "mkcp_'$ip:$v2ray_mkcp_port'", "tls": "", "type": "utp", "v": "2"}'|base64 -w 0`
				echo $echo_e_arg "\033[45;37m\rmkcp:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
			;;
			5)
				#link=`echo -n $echo_E_arg '{"add": "'$ip'", "port": "'$v2ray_mkcp_xtls_port'", "aid": "0", "host": "", "id": "'$uuid'", "net": "kcp", "path": "", "ps": "mkcp_'$ip:$v2ray_mkcp_xtls_port'", "tls": "tls", "host": "cutebi.taobao69.cn", "type": "utp", "v": "2"}'|base64 -w 0`
				#echo $echo_e_arg "\033[45;37m\rmkcp+tls:\033[0m\n\t\033[4;35mvmess://$link\033[0m"
				echo $echo_e_arg "\033[45;37m\rmkcp+xtls:\033[0m\n\t\033[4;35mvless://${uuid}@${ip}:${v2ray_mkcp_xtls_port}?security=xtls&encryption=none&headerType=none&sni=cutebi.taobao69.cn&type=kcp&flow=xtls-rprx-direct&allowInsecure=1#mkcp+xtls_${ip}:${v2ray_mkcp_xtls_port}\033[0m"
			;;
			6)
				echo $echo_e_arg "\033[45;37m\rtcp+tls:\033[0m\n\t\033[4;35mvless://${uuid}@${ip}:${v2ray_tcp_xtls_port}?security=xtls&encryption=none&host=cutebi.taobao69.cn&headerType=none&type=tcp&flow=xtls-rprx-direct&allowInsecure=1#tcp+xtls_${ip}:${v2ray_tcp_xtls_port}\033[0m"
			;;
		esac
	done
}

Install() {
	Config
	Delete >/dev/null 2>&1
	InstallInit
	InstallFiles
	"$v2ray_install_directory/v2ray.init" start|grep -q FAILED && Error "v2ray install failed."
	which systemctl && [ -z "$(systemctl --failed|grep -q 'Host is down')" ] && systemctl restart v2ray &>/dev/null
	AddAutoStart
	echo $echo_e_arg \
		"\033[44;37mv2ray install success.\033[0;34m
		`
			for opt in $v2ray_inbounds_options; do
				case $opt in
					1) echo $echo_e_arg "\r	http server(vmess):\033[34G port=${v2ray_http_port}";;
					2) echo $echo_e_arg "\r	webSocket server(vmess):\033[34G port=${v2ray_ws_port} path=${v2ray_ws_path}";;
					3) echo $echo_e_arg "\r	webSocket tls server(vless):\033[34G port=${v2ray_ws_tls_port} path=${v2ray_ws_tls_path}";;
					4) echo $echo_e_arg "\r	mKCP server(vmess):\033[34G port=${v2ray_mkcp_port} type=utp";;
					5) echo $echo_e_arg "\r	mKCP xtls server(vless):\033[34G port=${v2ray_mkcp_xtls_port} type=none";;
					6) echo $echo_e_arg "\r	tcp xtls server(vless):\033[34G port=${v2ray_tcp_xtls_port} flow: xtls-rprx-direct";;
				esac
			done
		`
		\r	uuid:\033[35G$uuid
		\r	alterId:\033[35G0
		\r`[ -f /etc/init.d/v2ray ] && /etc/init.d/v2ray usage || \"$v2ray_install_directory/v2ray.init\" usage`
		`outputVmessLink`\033[0m"
}

Uninstall() {
	if [ -z "$v2ray_install_directory" ]; then
		echo -n "Please input v2ray install directory(default is /usr/local/v2ray): "
		read v2ray_install_directory
	fi
	Delete &>/dev/null && \
		echo $echo_e_arg "\n\033[44;37mv2ray uninstall success.\033[0m" || \
		echo $echo_e_arg "\n\033[41;37mv2ray uninstall failed.\033[0m"
}

#script initialization
ScriptInit() {
	emulate bash 2>/dev/null #zsh emulation mode
	if echo -e ''|grep -q 'e'; then
		echo_e_arg=''
		echo_E_arg=''
	else
		echo_e_arg='-e'
		echo_E_arg='-E'
	fi
}
ScriptInit
echo $*|grep -qi uninstall && Uninstall || Install
