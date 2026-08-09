#!/bin/bash

# ==================== 颜色定义 ====================
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly PLAIN='\033[0m'

# ==================== 颜色输出函数 ====================
color_echo() {
    echo -e "${1}${2}${PLAIN}"
}

red() { color_echo "$RED" "$1"; }
green() { color_echo "$GREEN" "$1"; }
yellow() { color_echo "$YELLOW" "$1"; }

# ==================== 工具函数 ====================
get_public_ip() {
    local ip=""
    for url in "ifconfig.me" "ipecho.net/plain" "icanhazip.com"; do
        ip=$(curl -s --max-time 5 "https://$url" 2>/dev/null)
        [[ -n "$ip" ]] && break
    done
    echo "${ip:-未获取到IP}"
}

validate_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c 20 2>/dev/null || \
    openssl rand -base64 16 2>/dev/null || \
    date +%s | sha256sum | base64 | head -c 20
}

back_to_menu() {
    local msg="${1:-所选操作执行完成}"
    green "$msg"
    read -p "输入 'y' 退出，或按任意键回到主菜单: " input
    [[ "$input" == "y" ]] && exit 0 || menu
}

# ==================== 系统检测 ====================
detect_os() {
    local os_info
    os_info=$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d '"' -f2)
    os_info=${os_info:-$(hostnamectl 2>/dev/null | grep -i system | cut -d: -f2)}
    os_info=${os_info:-$(lsb_release -sd 2>/dev/null)}
    os_info=${os_info:-$(grep -i description /etc/lsb-release 2>/dev/null | cut -d '"' -f2)}
    os_info=${os_info:-$(grep . /etc/redhat-release 2>/dev/null)}
    os_info=${os_info:-$(grep . /etc/issue 2>/dev/null | cut -d '\' -f1 | sed '/^[ ]*$/d')}
    
    local os_lower=$(echo "$os_info" | tr '[:upper:]' '[:lower:]')
    case "$os_lower" in
        *debian*) echo "Debian";;
        *ubuntu*) echo "Ubuntu";;
        *centos*|*red\ hat*|*kernel*|*oracle\ linux*|*alma*|*rocky*) echo "CentOS";;
        *amazon\ linux*) echo "CentOS";;
        *alpine*) echo "Alpine";;
        *) echo "Unknown";;
    esac
}

# ==================== 功能模块 ====================
root_user() {
    local os=$(detect_os)
    if [[ "$os" == "Unknown" ]]; then
        red "不支持当前系统，请使用主流操作系统"
        return 1
    fi
    
    local pkg_update=""
    local pkg_install=""
    case "$os" in
        Debian|Ubuntu) pkg_update="apt -y update"; pkg_install="apt -y install";;
        CentOS) pkg_update="yum -y update"; pkg_install="yum -y install";;
        Alpine) pkg_update="apk update -f"; pkg_install="apk add -f";;
    esac
    
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        sudo $pkg_update && sudo $pkg_install openssh-server
    fi
    if [[ -z $(type -P curl) ]]; then
        sudo $pkg_update && sudo $pkg_install curl
    fi
    
    sudo chattr -i /etc/passwd /etc/shadow 2>/dev/null
    sudo chattr -a /etc/passwd /etc/shadow 2>/dev/null
    
    local sshport=22
    read -p "输入SSH端口（默认22）: " input_port
    if [[ -n "$input_port" ]] && validate_port "$input_port"; then
        sshport="$input_port"
    else
        [[ -n "$input_port" ]] && yellow "端口无效，使用默认22端口"
    fi
    
    local password=$(generate_password)
    read -p "输入root密码（留空自动生成）: " input_pass
    [[ -n "$input_pass" ]] && password="$input_pass"
    
    echo "root:$password" | sudo chpasswd root || {
        red "密码设置失败！"
        return 1
    }
    
    sudo sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config
    sudo sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
    sudo sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
    
    sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || \
    sudo service ssh restart 2>/dev/null || sudo service sshd restart 2>/dev/null
    
    local ip=$(get_public_ip)
    green "VPS登录信息："
    green "地址: $ip:$sshport"
    green "用户: root"
    green "密码: $password"
    yellow "请妥善保存！"
    
    back_to_menu
}

open_ports() {
    systemctl stop firewalld 2>/dev/null && systemctl disable firewalld 2>/dev/null
    ufw disable 2>/dev/null
    setenforce 0 2>/dev/null
    
    for table in filter nat mangle; do
        iptables -t $table -F 2>/dev/null
        iptables -t $table -X 2>/dev/null
    done
    
    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null
    
    netfilter-persistent save 2>/dev/null
    
    green "防火墙已完全放行！"
    back_to_menu
}

tcp_bbr_optimize() {
    cat > /etc/sysctl.d/99-optimize.conf << 'EOF'
# 文件系统优化
fs.file-max=1000000
fs.inotify.max_user_instances=65536

# 网络转发
net.ipv4.conf.all.route_localnet=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.lo.forwarding=1

# TCP优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_max_tw_buckets=32768
net.ipv4.tcp_max_syn_backlog=131072
net.core.netdev_max_backlog=131072
net.core.somaxconn=32768
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_fastopen=3

# 内存缓冲区
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# BBR拥塞控制
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    
    sysctl -p /etc/sysctl.d/99-optimize.conf >/dev/null 2>&1
    sysctl --system >/dev/null 2>&1
    
    green "TCP/BBR优化已完成！"
    yellow "$(lsmod | grep bbr || echo 'BBR未加载，可能需要重启')"
    back_to_menu
}

# ==================== 下载脚本函数 ====================
run_script() {
    local url="$1"
    local name="${2:-script.sh}"
    local args="${3:-}"
    
    if ! wget -N --no-check-certificate -q "$url" -O "$name"; then
        red "下载失败: $url"
        return 1
    fi
    chmod +x "$name"
    bash "$name" $args
}

# ==================== 菜单 ====================
menu() {
    clear
    echo -e "${RED}=================================="
    echo -e "${GREEN}          cc tool              "
    echo -e "${RED}        cc Linux一键运行脚本    "
    echo -e "                                   "
    echo -e "${RED}=================================="
    echo -e "                                   "
    echo -e "${GREEN} 1. root/SSH登录/改密码/端口"
    echo -e "${GREEN} 2. 开启端口/禁用防火墙"
    echo -e "${GREEN} 3. TCP/BBR优化"
    echo -e "${GREEN} 4. 安装Hysteria2"
    echo -e "${GREEN} 5. 安装Alist"
    echo -e "${GREEN} 6. 安装x-ui"
    echo -e "${GREEN} 7. 自动SSL证书"
    echo -e "${GREEN} 8. 性能测试"
    echo -e "${GREEN} 9. 青龙面板"
    echo -e "${GREEN} a. 3X-UI面板"
    echo -e "${GREEN} b. BBR3加速"
    echo -e "${GREEN} c. aria2安装"
    echo -e "${GREEN} d. CD2安装"
    echo -e "${GREEN} e. Rclone安装"
    echo -e "${GREEN} f. CasaOS安装"
    echo -e "${GREEN} g. YAML下载"
    echo -e "${GREEN} i. Pve-Debian"
    echo -e "${GREEN} j. Kejilion脚本"
    echo -e "${GREEN} k. Warp加速"
    echo -e "${GREEN} l. LXC容器"
    echo -e "${GREEN} n. 1Panel面板"
    echo -e "${GREEN} m. Milivpn"
    echo -e "${GREEN} u. 脚本更新"
    echo -e "${GREEN} x. 一键换源"
    echo -e "${GREEN} z. Docker安装"
    echo -e "${RED}dd. DD系统"
    echo -e "${PLAIN}"
    
    read -p "请输入选项: " choice
    case "$choice" in
        1) root_user ;;
        2) open_ports ;;
        3) tcp_bbr_optimize ;;
        4) run_script "https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh" "hysteria.sh" ;;
        5) curl -fsSL https://res.oplist.org/script/v4.sh | sudo bash ;;
        6) bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh) ;;
        7) apt update -y && apt upgrade -y && apt install git -y && bash <(curl -fsSL https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh) ;;
        8) bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh) ;;
        9) run_script "https://raw.githubusercontent.com/yanyuwangluo/VIP/main/Scripts/sh/ql.sh" "ql.sh" ;;
        a) bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ;;
        b) bash <(curl -fsSL https://raw.githubusercontent.com/byJoey/Actions-bbr-v3/main/install.sh) ;;
        c) run_script "https://git.io/aria2.sh" "aria2.sh" ;;
        d) bash <(curl -sSLf https://ailg.ggbond.org/cd2.sh) ;;
        e) curl https://rclone.org/install.sh | sudo bash ;;
        f) wget -qO- https://get.casaos.io | sudo bash ;;
        g) rm -rf toolbox && git clone https://gh-proxy.cn/https://github.com/f1161291/toolbox && cd toolbox && chmod +x tool.sh && bash tool.sh ;;
        i) bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh)" ;;
        j) bash <(curl -sL kejilion.sh) ;;
        k) run_script "https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh" "warp.sh" ;;
        l) bash -c "$(curl -sSL https://www.linkease.com/rd/fastpve/)" ;;
        n) bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)" ;;
        m) bash <(curl -Ls https://raw.githubusercontent.com/baoweise-bot/aimili-vpngate/main/install.sh) ;;
        u) run_script "https://gh-proxy.cn/https://raw.githubusercontent.com/f1161291/toolbox/main/tool.sh" "tool.sh" && bash tool.sh ;;
        x) bash <(curl -sSL https://linuxmirrors.cn/main.sh) ;;
        z) curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun ;;
        0) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ;;
        dd) run_script "https://raw.githubusercontent.com/f1161291/other/refs/heads/main/dd.sh" "dd.sh" && bash dd.sh ;;
        *) red "无效选项！" && sleep 1 && menu ;;
    esac
}

# ==================== 启动 ====================
menu
