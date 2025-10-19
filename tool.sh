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
```
 speedtest(){
    echo ""
    echo -e " ${GREEN}1.${PLAIN} VPS测试 (misakabench)"
    echo -e " ${GREEN}2.${PLAIN} VPS测试 (bench.sh)"
    echo -e " ${GREEN}3.${PLAIN} VPS测试 (superbench)"
    echo -e " ${GREEN}4.${PLAIN} VPS测试 (lemonbench)"
    echo -e " ${GREEN}5.${PLAIN} VPS测试 (融合怪全测)"
    echo -e " ${GREEN}6.${PLAIN} 流媒体检测"
    echo -e " ${GREEN}7.${PLAIN} 三网测速"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp " 请输入选项 [0-7]:" menuInput
    case $menuInput in
        1) bash <(curl -Lso- https://cdn.jsdelivr.net/gh/misaka-gh/misakabench@master/misakabench.sh) ;;
        2) wget -qO- bench.sh | bash ;;
        3) wget -qO- --no-check-certificate https://raw.githubusercontent.com/oooldking/script/master/superbench.sh | bash ;;
        4) curl -fsL https://ilemonra.in/LemonBenchIntl | bash -s fast ;;
        5) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh) ;;
        6) bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh) ;;
        7) bash <(curl -Lso- https://git.io/superspeed.sh) ;;
        0) menu ;;
        *) exit 1 ;;
    esac
}
```

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

```
acme_rg(){
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "注意：请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i"
    if [[ -n $SYS ]]; then
        break
    fi
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        if [[ -n $SYSTEM ]]; then
            break
        fi
    fi
done

[[ -z $SYSTEM ]] && red "不支持当前VPS系统, 请使用主流的操作系统" && exit 1

back2menu() {
    echo ""
    green "所选命令操作执行完成"
    read -rp "请输入“y”退出, 或按任意键回到主菜单：" back2menuInput
    case "$back2menuInput" in
        y) exit 1 ;;
        *) menu ;;
    esac
}

install_base(){
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl wget sudo socat
    if [[ $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_INSTALL[int]} cronie
        systemctl start crond
        systemctl enable crond
    else
        ${PACKAGE_INSTALL[int]} cron
        systemctl start cron
        systemctl enable cron
    fi
}

install_acme(){
    install_base
    read -rp "请输入注册邮箱 (例: admin@gmail.com, 或留空自动生成一个gmail邮箱): " acmeEmail
    if [[ -z $acmeEmail ]]; then
        autoEmail=$(date +%s%N | md5sum | cut -c 1-16)
        acmeEmail=$youlam.gu@gmail.com
        yellow "已取消设置邮箱, 使用自动生成的gmail邮箱: $acmeEmail"
    fi
    curl https://get.acme.sh | sh -s email=$acmeEmail
    source ~/.bashrc
    bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    if [[ -n $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
        green "Acme.sh证书申请脚本安装成功!"
    else
        red "抱歉, Acme.sh证书申请脚本安装失败"
        green "建议如下："
        yellow "1. 检查VPS的网络环境"
        yellow "2. 脚本可能跟不上时代, 建议截图发布到GitHub Issues、GitLab Issues、论坛或TG群询问"
    fi
    back2menu
}

check_80(){
 
    if [[ -z $(type -P lsof) ]]; then
        ${PACKAGE_UPDATE[int]}
        ${PACKAGE_INSTALL[int]} lsof
    fi
    
    yellow "正在检测80端口是否占用..."
    sleep 1
    
    if [[  $(lsof -i:"80" | grep -i -c "listen") -eq 0 ]]; then
        green "检测到目前80端口未被占用"
        sleep 1
    else
        red "检测到目前80端口被其他程序被占用，以下为占用程序信息"
        lsof -i:"80"
        read -rp "如需结束占用进程请按Y，按其他键则退出 [Y/N]: " yn
        if [[ $yn =~ "Y"|"y" ]]; then
            lsof -i:"80" | awk '{print $2}' | grep -v "PID" | xargs kill -9
            sleep 1
        else
            exit 1
        fi
    fi
}

acme_standalone(){
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && red "未安装acme.sh, 无法执行操作" && exit 1
    check_80
    WARPv4Status=$(curl -s4m10 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    WARPv6Status=$(curl -s6m10 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    if [[ $WARPv4Status =~ on|plus ]] || [[ $WARPv6Status =~ on|plus ]]; then
        wg-quick down wgcf >/dev/null 2>&1
    fi
    
    ipv4=$(curl ifconfig.me)
    ipv6=$(curl 6.ipw.cn)
    
    echo ""
    yellow "在使用80端口申请模式时, 请先将您的域名解析至你的VPS的真实IP地址, 否则会导致证书申请失败"
    echo ""
    if [[ -n $ipv4 && -n $ipv6 ]]; then
        echo -e "VPS的真实IPv4地址为: ${GREEN} $ipv4 ${PLAIN}"
        echo -e "VPS的真实IPv6地址为: ${GREEN} $ipv6 ${PLAIN}"
    elif [[ -n $ipv4 && -z $ipv6 ]]; then
        echo -e "VPS的真实IPv4地址为: ${GREEN} $ipv4 ${PLAIN}"
    elif [[ -z $ipv4 && -n $ipv6 ]]; then
        echo -e "VPS的真实IPv6地址为: ${GREEN} $ipv6 ${PLAIN}"
    fi
    echo ""
    read -rp "请输入解析完成的域名: " domain
    [[ -z $domain ]] && red "未输入域名，无法执行操作！" && exit 1
    green "已输入的域名：$domain" && sleep 1
    domainIP=$(curl -sm8 ipget.net/?ip="${domain}")
    
    if [[ $domainIP == $ipv6 ]]; then
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --renew-hook --listen-v6 --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    fi
    if [[ $domainIP == $ipv4 ]]; then
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --renew-hook --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    fi
    
    if [[ -n $(echo $domainIP | grep nginx) ]]; then
        yellow "域名解析失败, 请检查域名是否正确填写或等待解析完成再执行脚本"
        exit 1
    elif [[ -n $(echo $domainIP | grep ":") || -n $(echo $domainIP | grep ".") ]]; then
        if [[ $domainIP != $ipv4 ]] && [[ $domainIP != $ipv6 ]]; then
            if [[ -n $(type -P wg-quick) && -n $(type -P wgcf) ]]; then
                wg-quick up wgcf >/dev/null 2>&1
            fi
            green "域名 ${domain} 目前解析的IP: ($domainIP)"
            red "当前域名解析的IP与当前VPS使用的真实IP不匹配"
            green "建议如下："
            yellow "1. 请确保CloudFlare小云朵为关闭状态(仅限DNS), 其他域名解析或CDN网站设置同理"
            yellow "2. 请检查DNS解析设置的IP是否为VPS的真实IP"
            yellow "3. 脚本可能跟不上时代, 建议截图发布到GitHub Issues、GitLab Issues、论坛或TG群询问"
            exit 1
        fi
    fi
    
    checktls
}

acme_cfapiTLD(){
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && red "未安装Acme.sh, 无法执行操作" && exit 1
    ipv4=$(curl ifconfig.me)
    ipv6=$(curl 6.ipw.cn)
    read -rp "请输入需要申请证书的域名: " domain
    if [[ $(echo ${domain:0-2}) =~ cf|ga|gq|ml|tk ]]; then
        red "检测为Freenom免费域名, 由于CloudFlare API不支持, 故无法使用本模式申请!"
        back2menu
    fi
    read -rp "请输入CloudFlare Global API Key: " GAK
    [[ -z $GAK ]] && red "未输入CloudFlare Global API Key, 无法执行操作!" && exit 1
    export CF_Key="$GAK"
    read -rp "请输入CloudFlare的登录邮箱: " CFemail
    [[ -z $domain ]] && red "未输入CloudFlare的登录邮箱, 无法执行操作!" && exit 1
    export CF_Email="$CFemail"
    if [[ -z $ipv4 ]]; then
        bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d "${domain}" -k ec-256 --renew-hook --listen-v6 --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    else
        bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d "${domain}" -k ec-256 --renew-hook --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    fi
    checktls
}

acme_cfapiNTLD(){
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && red "未安装acme.sh, 无法执行操作" && exit 1
    ipv4=$(curl ifconfig.me)
    ipv6=$(curl 6.ipw.cn)
    read -rp "请输入需要申请证书的泛域名 (输入格式：example.com): " domain
    [[ -z $domain ]] && red "未输入域名，无法执行操作！" && exit 1
    if [[ $(echo ${domain:0-2}) =~ cf|ga|gq|ml|tk ]]; then
        red "检测为Freenom免费域名, 由于CloudFlare API不支持, 故无法使用本模式申请!"
        back2menu
    fi
    read -rp "请输入CloudFlare Global API Key: " GAK
    [[ -z $GAK ]] && red "未输入CloudFlare Global API Key, 无法执行操作！" && exit 1
    export CF_Key="$GAK"
    read -rp "请输入CloudFlare的登录邮箱: " CFemail
    [[ -z $domain ]] && red "未输入CloudFlare的登录邮箱, 无法执行操作!" && exit 1
    export CF_Email="$CFemail"
    if [[ -z $ipv4 ]]; then
        bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d "*.${domain}" -d "${domain}" -k ec-256 --renew-hook --listen-v6 --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    else
        bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d "*.${domain}" -d "${domain}" -k ec-256 --renew-hook --install-cert -d ${domain} --key-file /root/key.pem --fullchain-file /root/cert.pem --ecc
    fi
    checktls
}

checktls() {
    if [[ -f /root/cert.pem && -f /root/key.pem ]]; then
        if [[ -s /root/cert.pem && -s /root/key.pem ]]; then
            if [[ -n $(type -P wg-quick) && -n $(type -P wgcf) ]]; then
                wg-quick up wgcf >/dev/null 2>&1
            fi
            sed -i '/--cron/d' /etc/crontab >/dev/null 2>&1
            echo "0 0 * * * root bash /root/.acme.sh/acme.sh --cron -f >/dev/null 2>&1" >> /etc/crontab
            green "证书申请成功! 脚本申请到的证书 (/root/cert.pem) 和私钥 (/root/key.pem) 文件已保存到 /root 文件夹下"
            yellow "证书crt文件路径如下: /root/cert.pem"
            yellow "私钥key文件路径如下: /root/key.pem"
            back2menu
        else
            if [[ -n $(type -P wg-quick) && -n $(type -P wgcf) ]]; then
                wg-quick up wgcf >/dev/null 2>&1
            fi
            red "很抱歉，证书申请失败"
            green "建议如下: "
            yellow "1. 自行检测防火墙是否打开, 如使用80端口申请模式时, 请关闭防火墙或放行80端口"
            yellow "2. 同一域名多次申请可能会触发Let's Encrypt官方风控, 请尝试使用脚本菜单的9选项更换证书颁发机构, 再重试申请证书, 或更换域名、或等待7天后再尝试执行脚本"
            yellow "3. 脚本可能跟不上时代, 建议截图发布到GitHub Issues、GitLab Issues、论坛或TG群询问"
            back2menu
        fi
    fi
}

view_cert(){
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装acme.sh, 无法执行操作!" && exit 1
    bash ~/.acme.sh/acme.sh --list
    back2menu
}

revoke_cert() {
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装acme.sh, 无法执行操作!" && exit 1
    bash ~/.acme.sh/acme.sh --list
    read -rp "请输入要撤销的域名证书 (复制Main_Domain下显示的域名): " domain
    [[ -z $domain ]] && red "未输入域名，无法执行操作!" && exit 1
    if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $domain) ]]; then
        bash ~/.acme.sh/acme.sh --revoke -d ${domain} --ecc
        bash ~/.acme.sh/acme.sh --remove -d ${domain} --ecc
        rm -rf ~/.acme.sh/${domain}_ecc
        rm -f /root/cert.pem /root/key.pem
        green "撤销${domain}的域名证书成功"
        back2menu
    else
        red "未找到${domain}的域名证书, 请自行检查!"
        back2menu
    fi
}

renew_cert() {
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装acme.sh, 无法执行操作!" && exit 1
    bash ~/.acme.sh/acme.sh --list
    read -rp "请输入要续期的域名证书 (复制Main_Domain下显示的域名): " domain
    [[ -z $domain ]] && red "未输入域名, 无法执行操作!" && exit 1
    if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $domain) ]]; then
        bash ~/.acme.sh/acme.sh --renew -d ${domain} --force --ecc
        checktls
        back2menu
    else
        red "未找到${domain}的域名证书，请再次检查域名输入正确"
        back2menu
    fi
}

switch_provider(){
    yellow "请选择证书提供商, 默认通过 Letsencrypt.org 来申请证书 "
    yellow "如果证书申请失败, 例如一天内通过 Letsencrypt.org 申请次数过多, 可选 BuyPass.com 或 ZeroSSL.com 来申请."
    echo -e " ${GREEN}1.${PLAIN} Letsencrypt.org"
    echo -e " ${GREEN}2.${PLAIN} BuyPass.com"
    echo -e " ${GREEN}3.${PLAIN} ZeroSSL.com"
    read -rp "请选择证书提供商 [1-3，默认1]: " provider
    case $provider in
        2) bash ~/.acme.sh/acme.sh --set-default-ca --server buypass && green "切换证书提供商为 BuyPass.com 成功！" ;;
        3) bash ~/.acme.sh/acme.sh --set-default-ca --server zerossl && green "切换证书提供商为 ZeroSSL.com 成功！" ;;
        *) bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt && green "切换证书提供商为 Letsencrypt.org 成功！" ;;
    esac
    back2menu
}

uninstall() {
    [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "未安装Acme.sh, 卸载程序无法执行!" && exit 1
    ~/.acme.sh/acme.sh --uninstall
    sed -i '/--cron/d' /etc/crontab >/dev/null 2>&1
    rm -rf ~/.acme.sh
    green "Acme  一键申请证书脚本已彻底卸载!"
}

menu() {
    clear
    echo "#############################################################"
    echo -e "#                   ${RED}Acme  一键申请证书脚本${PLAIN}                  #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 安装 Acme.sh 域名证书申请脚本"
    echo -e " ${GREEN}2.${PLAIN} ${RED}卸载 Acme.sh 域名证书申请脚本${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}3.${PLAIN} 申请单域名证书 ${YELLOW}(80端口申请)${PLAIN}"
    echo -e " ${GREEN}4.${PLAIN} 申请单域名证书 ${YELLOW}(CF API申请)${PLAIN} ${GREEN}(无需解析)${PLAIN} ${RED}(不支持freenom域名)${PLAIN}"
    echo -e " ${GREEN}5.${PLAIN} 申请泛域名证书 ${YELLOW}(CF API申请)${PLAIN} ${GREEN}(无需解析)${PLAIN} ${RED}(不支持freenom域名)${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}6.${PLAIN} 查看已申请的证书"
    echo -e " ${GREEN}7.${PLAIN} 撤销并删除已申请的证书"
    echo -e " ${GREEN}8.${PLAIN} 手动续期已申请的证书"
    echo -e " ${GREEN}9.${PLAIN} 切换证书颁发机构"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 返回主菜单"
    echo ""
    read -rp "请输入选项 [0-9]: " NumberInput
    case "$NumberInput" in
        1) install_acme ;;
        2) uninstall ;;
        3) acme_standalone ;;
        4) acme_cfapiTLD ;;
        5) acme_cfapiNTLD ;;
        6) view_cert ;;
        7) revoke_cert ;;
        8) renew_cert ;;
        9) switch_provider ;;
        *) back1menu ;;
    esac
}
    menu
}
```

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
	green "a. H-UI"
  	green "b. tailscale"
 	green "c. aria2 安装"
 	green "d. cd2 安装"
   	green "e. Rclone安装"
	green "f. CasaOS 安装"
 	green "g. YAML下载"
    green "h. 3X-UI"
				green "i. Pve-Debian"
	green "x. 一键换源"
	green "z. Docker 安装"
    red   "dd. 脚本更新"
	echo "         "
	read -p "请输入数字:" NumberInput
	case "$NumberInput" in
		1) root_user ;;
		2) open_ports ;;
		3) bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 10 -v 64 -p 123456789 ;;
		4) wget -N --no-check-certificate https://gh.130401.xyz/https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh ;;
		5) curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh ;;
		6) bash <(curl -Ls https://gh.130401.xyz/https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) ;;
		7) apt update -y && apt upgrade -y && apt install git -y && bash <(curl -fsSL https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh) ;;
		8) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh) ;;
		9) wget -q https://gh.130401.xyz/https://raw.githubusercontent.com/yanyuwangluo/VIP/main/Scripts/sh/ql.sh -O ql.sh && bash ql.sh ;;
		10) tcp_up ;; 
        a) bash <(curl -fsSL https://gh.130401.xyz/https://raw.githubusercontent.com/jonssonyan/h-ui/main/install.sh) ;;
		b) curl -fsSL https://tailscale.com/install.sh | sh ;; 
		c) wget -N git.io/aria2.sh && chmod +x aria2.sh && bash aria2.sh ;;       
  		d) bash <(curl -sSLf https://ailg.ggbond.org/cd2.sh) ;;
	    e) curl https://rclone.org/install.sh | sudo bash ;;
        f) wget -qO- https://get.casaos.io | sudo bash ;;
		g) rm -rf toolbox && git clone https://gh.130401.xyz/https://github.com/f1161291/toolbox  && cd toolbox && chmod +x tool.sh  && bash tool.sh ;;
        h) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)  ;;
								i) bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh)"  ;;
		x) bash <(curl -sSL https://linuxmirrors.cn/main.sh);; 
  		z) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun  ;;
		0) bash <(curl -fsSL https://gh.130401.xyz/https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        dd) wget -N --no-check-certificate https://raw.githubusercontent.com/f1161291/toolbox/main/tool.sh && chmod +x tool.sh && bash tool.sh ;;
              
	esac
}
menu
