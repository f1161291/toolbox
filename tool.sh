#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}


back2menu(){
	green "所选操作执行完成"
	read -p "请输入“y”退出，或按任意键回到主菜单：" back2menuInput
	case "$back2menuInput" in
		y) exit 1 ;;
		*) menu ;;
	esac
}


back1menu(){
  bash tool.sh
}

root_user(){
  REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
  RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
  CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

  for i in "${CMD[@]}"; do
	  SYS="$i" && [[ -n $SYS ]] && break
  done

  for ((int=0; int<${#REGEX[@]}; int++)); do
	  [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
  done

  [[ -z $SYSTEM ]] && red "不支持VPS的当前系统，请使用主流操作系统" && exit 1
  [[ ! -f /etc/ssh/sshd_config ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} openssh-server
  [[ -z $(type -P curl) ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} curl

  IP=$(curl ifconfig.me)
  IP6=$(curl 6.ipw.cn)

  sudo lsattr /etc/passwd /etc/shadow >/dev/null 2>&1
  sudo chattr -i /etc/passwd /etc/shadow >/dev/null 2>&1
  sudo chattr -a /etc/passwd /etc/shadow >/dev/null 2>&1
  sudo lsattr /etc/passwd /etc/shadow >/dev/null 2>&1

  read -p "输入即将设置的SSH端口（如未输入，默认22）：" sshport
  [ -z $sshport ] && red "端口未设置，将使用默认22端口" && sshport=22
  read -p "输入即将设置的root密码：" password
  [ -z $password ] && red "端口未设置，将使用随机生成的root密码" && password=$(cat /proc/sys/kernel/random/uuid)
  echo root:$password | sudo chpasswd root

  sudo sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config;
  sudo sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config;
  sudo sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config;

  sudo service ssh restart >/dev/null 2>&1 # 某些VPS系统的ssh服务名称为ssh，以防无法重启服务导致无法立刻使用密码登录
  sudo service sshd restart >/dev/null 2>&1

  yellow "VPS root登录信息设置完成！"
  green "VPS登录地址：$IP:$sshport: $IP6:$sshport"
  green "用户名：root"
  green "密码：$password"
  yellow "请妥善保存好登录信息！然后重启VPS确保设置已保存！"
  back2menu
}

open_ports(){
  systemctl stop firewalld.service 2>/dev/null
  systemctl disable firewalld.service 2>/dev/null
  setenforce 0 2>/dev/null
  ufw disable 2>/dev/null
  iptables -P INPUT ACCEPT 2>/dev/null
  iptables -P FORWARD ACCEPT 2>/dev/null
  iptables -P OUTPUT ACCEPT 2>/dev/null
  iptables -t nat -F 2>/dev/null
  iptables -t mangle -F 2>/dev/null
  iptables -F 2>/dev/null
  iptables -X 2>/dev/null
  netfilter-persistent save 2>/dev/null
  green "VPS的防火墙端口已放行！"
  back2menu
}

tcp_up(){
cat > '/etc/sysctl.conf' << EOF
fs.file-max=1000000
fs.inotify.max_user_instances=65536

net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1

net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

net.ipv4.tcp_syncookies=1
net.ipv4.tcp_retries1=3
net.ipv4.tcp_retries2=5
net.ipv4.tcp_orphan_retries=3
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries=3
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_max_tw_buckets=32768
net.ipv4.tcp_max_syn_backlog=131072
net.core.netdev_max_backlog=131072
net.core.somaxconn=32768
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_autocorking=0
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.tcp_mem=262144 1048576 4194304
net.ipv4.udp_mem=262144 1048576 4194304
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=fq
net.ipv4.ping_group_range=0 2147483647
EOF
sysctl -p /etc/sysctl.conf > /dev/null
bbr=$(lsmod | grep bbr)
yellow "$bbr"
back2menu
}

menu(){
	clear
	red "=================================="
	green "          cc tool              "
	red "        cc liux一键运行脚本    "
	echo "                           "
	red "=================================="
	echo "                           "
	green "1. root/ssh登录/改密码/ssh端口"
	green "2. 开启端口禁用防火墙"
	green "3. Oracle DD系统"
	green "4. 安装Hystria2"
	green "5. 安装Alist"
	green "6. 安装x-ui"
	green "7. 自动证书"
	green "8. 性能测试"
	green "9. 青龙面板"
	green "10. TCP调优"
	green "0. 极光面板"
	green "a. S-UI"
  	green "b. tailscale"
 	green "c. aria2 安装"
 	green "d. cd2 安装"
   	green "e. Rclone安装"
	green "f. CasaOS 安装"
 	green "g. YAML下载"
    green "h. X-UI"
	green "i. Pve-Debian"
	green "j. Kejilion脚本"
    green "k. warp"
	green "l. lxc"
	green "x. 一键换源"
	green "z. Docker 安装"
    red   "dd. 脚本更新"
	echo "         "
	read -p "请输入数字:" NumberInput
	case "$NumberInput" in
		1) root_user ;;
		2) open_ports ;;
		3) bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 11 -v 64 -p 123456789 ;;
		4) wget -N --no-check-certificate https://gh.130401.xyz/https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh ;;
		5) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
		6) bash <(curl -Ls https://gh.130401.xyz/https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) ;;
		7) apt update -y && apt upgrade -y && apt install git -y && bash <(curl -fsSL https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh) ;;
		8) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh) ;;
		9) wget -q https://gh.130401.xyz/https://raw.githubusercontent.com/yanyuwangluo/VIP/main/Scripts/sh/ql.sh -O ql.sh && bash ql.sh ;;
		10) tcp_up ;; 
        a) bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh) ;;
		b) curl -fsSL https://tailscale.com/install.sh | sh ;; 
		c) wget -N git.io/aria2.sh && chmod +x aria2.sh && bash aria2.sh ;;       
  		d) bash <(curl -sSLf https://ailg.ggbond.org/cd2.sh) ;;
	    e) curl https://rclone.org/install.sh | sudo bash ;;
        f) wget -qO- https://get.casaos.io | sudo bash ;;
		g) rm -rf toolbox && git clone https://gh.130401.xyz/https://github.com/f1161291/toolbox  && cd toolbox && chmod +x tool.sh  && bash tool.sh ;;
        h) bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)  ;;
		i) bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh)"  ;;
		j) bash <(curl -sL kejilion.sh) ;;
		k) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ;;
		l) bash -c "$(curl -sSL https://www.linkease.com/rd/fastpve/)" ;;
		x) bash <(curl -sSL https://linuxmirrors.cn/main.sh) ;; 
  		z) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun  ;;
		0) bash <(curl -fsSL https://gh.130401.xyz/https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        dd) wget -N --no-check-certificate https://gh.130401.xyz/https://raw.githubusercontent.com/f1161291/toolbox/main/tool.sh && chmod +x tool.sh && bash tool.sh ;;
              
	esac
}
menu
