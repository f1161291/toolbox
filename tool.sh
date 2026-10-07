#!/bin/bash
# ==================== 颜色定义 ====================
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly PLAIN='\033[0m'

readonly WORK_DIR="/tmp/cc-tool"

# ==================== 颜色输出函数 ====================
color_echo() {
    echo -e "${1}${2}${PLAIN}"
}
red() { color_echo "$RED" "$1"; }
green() { color_echo "$GREEN" "$1"; }
yellow() { color_echo "$YELLOW" "$1"; }

banner() {
    echo -e "${YELLOW}============================================${PLAIN}"
    echo -e "${YELLOW}        ${1}${PLAIN}"
    echo -e "${YELLOW}============================================${PLAIN}"
}

# 执行完任何操作后调用，确保用户看到结果再返回菜单
pause_return() {
    echo
    read -r -p "按回车键返回主菜单..." _
}

# ==================== 权限检查 ====================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        red "此操作需要 root 权限，请使用 sudo 或 root 用户运行"
        return 1
    fi
    return 0
}

# ==================== 工具函数 ====================
get_public_ip() {
    local ip=""
    local url
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
    tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 16 2>/dev/null
}

# 下载远程脚本到本地，成功返回 0
# 用法: download_script <url> <本地文件>
download_script() {
    local url="$1"
    local file="$2"
    rm -f "$file"
    if type -P wget >/dev/null 2>&1; then
        wget -N --no-check-certificate -q "$url" -O "$file"
    elif type -P curl >/dev/null 2>&1; then
        curl -fsSL --insecure -o "$file" "$url"
    else
        red "wget 和 curl 均不可用"
        return 1
    fi
    if [[ ! -s "$file" ]]; then
        red "下载失败或文件为空: $url"
        rm -f "$file"
        return 1
    fi
    chmod +x "$file"
    return 0
}

# 运行下载的脚本文件
run_script() {
    local url="$1"
    local name="${2:-script.sh}"
    local args="${3:-}"

    mkdir -p "$WORK_DIR"
    local target="$WORK_DIR/$name"
    download_script "$url" "$target" || return 1
    bash "$target" $args
    local ret=$?
    rm -f "$target"
    return $ret
}

# ==================== 依赖安装 ====================
ensure_deps() {
    local missing=()
    type -P curl >/dev/null 2>&1 || missing+=(curl)
    type -P wget >/dev/null 2>&1 || missing+=(wget)
    [[ ${#missing[@]} -eq 0 ]] && return 0

    local os
    os=$(detect_os)
    yellow "正在安装依赖: ${missing[*]}"
    case "$os" in
        Debian|Ubuntu)
            apt -y update >/dev/null 2>&1
            apt -y install "${missing[@]}" >/dev/null 2>&1
            ;;
        CentOS)
            yum -y install epel-release >/dev/null 2>&1
            yum -y install "${missing[@]}" >/dev/null 2>&1
            ;;
        Alpine)
            apk update -f >/dev/null 2>&1
            apk add -f "${missing[@]}" >/dev/null 2>&1
            ;;
    esac

    for pkg in "${missing[@]}"; do
        if ! type -P "$pkg" >/dev/null 2>&1; then
            red "依赖安装失败: $pkg"
            return 1
        fi
    done
    green "依赖安装完成"
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

    local os_lower
    os_lower=$(echo "$os_info" | tr '[:upper:]' '[:lower:]')
    case "$os_lower" in
        *debian*) echo "Debian";;
        *ubuntu*) echo "Ubuntu";;
        *centos*|*red\ hat*|*kernel*|*oracle\ linux*|*alma*|*rocky*) echo "CentOS";;
        *amazon\ linux*) echo "CentOS";;
        *alpine*) echo "Alpine";;
        *) echo "Unknown";;
    esac
}

restart_ssh() {
    systemctl restart ssh 2>/dev/null && return 0
    systemctl restart sshd 2>/dev/null && return 0
    service ssh restart 2>/dev/null && return 0
    service sshd restart 2>/dev/null && return 0
    rc-service sshd restart 2>/dev/null && return 0
    /etc/init.d/sshd restart 2>/dev/null && return 0
    return 1
}

# ==================== 功能模块 ====================
root_user() {
    check_root || { pause_return; return 1; }

    local os
    os=$(detect_os)
    if [[ "$os" == "Unknown" ]]; then
        red "不支持当前系统，请使用主流操作系统"
        pause_return
        return 1
    fi

    ensure_deps || { pause_return; return 1; }

    local pkg_update="" pkg_install=""
    case "$os" in
        Debian|Ubuntu) pkg_update="apt -y update"; pkg_install="apt -y install";;
        CentOS) pkg_update="yum -y update"; pkg_install="yum -y install";;
        Alpine) pkg_update="apk update -f"; pkg_install="apk add -f";;
    esac

    if [[ ! -f /etc/ssh/sshd_config ]]; then
        $pkg_update && $pkg_install openssh-server
    fi

    chattr -i /etc/passwd /etc/shadow 2>/dev/null
    chattr -a /etc/passwd /etc/shadow 2>/dev/null

    local sshport=22
    read -r -p "输入SSH端口（默认22）: " input_port
    if [[ -n "$input_port" ]] && validate_port "$input_port"; then
        sshport="$input_port"
    else
        [[ -n "$input_port" ]] && yellow "端口无效，使用默认22端口"
    fi

    local password
    password=$(generate_password)
    read -r -p "输入root密码（留空自动生成）: " input_pass
    [[ -n "$input_pass" ]] && password="$input_pass"

    if ! echo "root:$password" | chpasswd; then
        red "密码设置失败！"
        pause_return
        return 1
    fi

    local conf=/etc/ssh/sshd_config
    cp -n "$conf" "$conf.bak" 2>/dev/null
    # 清除旧的 Port 配置，避免重复行冲突
    sed -i -E 's/^[#[:space:]]*Port[[:space:]]+.*/#&/' "$conf"
    if grep -qE '^#?Port[[:space:]]+' "$conf"; then
        sed -i -E "0,/^[#]?Port.*/s//Port $sshport/" "$conf"
    else
        echo "Port $sshport" >> "$conf"
    fi
    sed -i -E 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' "$conf"
    grep -qE '^PermitRootLogin' "$conf" || echo "PermitRootLogin yes" >> "$conf"
    sed -i -E 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' "$conf"
    grep -qE '^PasswordAuthentication' "$conf" || echo "PasswordAuthentication yes" >> "$conf"

    # 配置校验失败则回滚，避免重启后无法连接
    if type -P sshd >/dev/null 2>&1 && ! sshd -t 2>/dev/null; then
        red "sshd 配置校验失败，已回滚！"
        [[ -f "$conf.bak" ]] && mv -f "$conf.bak" "$conf"
        pause_return
        return 1
    fi

    if ! restart_ssh; then
        red "SSH 服务重启失败，请手动检查！"
        pause_return
        return 1
    fi

    local ip
    ip=$(get_public_ip)
    green "VPS登录信息："
    green "地址: $ip:$sshport"
    green "用户: root"
    green "密码: $password"
    yellow "请妥善保存！"

    pause_return
}

open_ports() {
    check_root || { pause_return; return 1; }

    systemctl stop firewalld 2>/dev/null; systemctl disable firewalld 2>/dev/null
    ufw disable 2>/dev/null
    setenforce 0 2>/dev/null
    sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 2>/dev/null

    local table
    for table in filter nat mangle raw; do
        iptables -t "$table" -F 2>/dev/null
        iptables -t "$table" -X 2>/dev/null
    done

    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null

    netfilter-persistent save 2>/dev/null
    service iptables save 2>/dev/null
    ip6tables-save > /etc/sysconfig/ip6tables 2>/dev/null

    green "防火墙已完全放行！"
    pause_return
}

tcp_bbr_optimize() {
    check_root || { pause_return; return 1; }

    mkdir -p /etc/sysctl.d
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

    if ! sysctl -p /etc/sysctl.d/99-optimize.conf >/dev/null 2>&1; then
        yellow "部分参数应用失败（可能内核不支持），已忽略"
    fi
    sysctl --system >/dev/null 2>&1

    green "TCP/BBR优化已完成！"
    if lsmod 2>/dev/null | grep -q bbr; then
        green "BBR 已加载"
    else
        yellow "BBR未加载，可能需要重启"
    fi
    pause_return
}

# ==================== Frp ====================
install_frp() {
    local frp_type="$1"
    banner "正在安装 ${frp_type}..."

    mkdir -p "$WORK_DIR"
    if [[ "$frp_type" == "frps" ]]; then
        if download_script \
            "https://raw.githubusercontent.com/mvscode/frps-onekey/master/install-frps.sh" \
            "$WORK_DIR/install-frps.sh"; then
            green "frps 脚本下载成功，开始安装..."
            bash "$WORK_DIR/install-frps.sh" install
            rm -f "$WORK_DIR/install-frps.sh"
        else
            red "frps 脚本下载失败，请检查网络连接"
        fi
    else
        if ! type -P curl >/dev/null 2>&1; then
            red "frpc 安装需要 curl"
        else
            bash <(curl -sSL https://atusu.cn/frp/install_frpc.sh)
        fi
    fi
}

frp_menu() {
    while true; do
        banner "选择安装 Frp 服务端或客户端"
        echo -e "  ${GREEN}1.${PLAIN} 安装 Frp 服务端 (frps)"
        echo -e "  ${GREEN}2.${PLAIN} 安装 Frp 客户端 (frpc)"
        echo -e "  ${YELLOW}0.${PLAIN} 返回主菜单"
        echo -e "${YELLOW}============================================${PLAIN}"
        read -r -p "请选择 [1/2/0]: " frp_choice
        case "$frp_choice" in
            1) check_root || break; install_frp "frps"; pause_return; return ;;
            2) install_frp "frpc"; pause_return; return ;;
            0) return ;;
            *) red "无效选项！"; sleep 1 ;;
        esac
    done
}

# ==================== 主菜单 ====================
menu() {
    while true; do
        clear
        echo -e "${RED}=================================="
        echo -e "${GREEN}          cc tool              "
        echo -e "${RED}        cc Linux一键运行脚本    "
        echo -e "${RED}=================================="
        echo -e "${GREEN} --- 系统基础 ---"
        echo -e "${GREEN} 1. root/SSH修改${PLAIN}   ${GREEN}2. 禁用防火墙${PLAIN}   ${GREEN}3. TCP/BBR优化${PLAIN}"
        echo -e "${GREEN} x. 一键换源${PLAIN}       ${GREEN}b. BBR3加速${PLAIN}      ${GREEN}dd. DD系统${PLAIN}"
        echo -e "${GREEN} --- 面板/代理 ---"
        echo -e "${GREEN} 5. 安装Alist${PLAIN}      ${GREEN}6. 安装x-ui${PLAIN}       ${GREEN}a. 3X-UI面板${PLAIN}"
        echo -e "${GREEN} n. 1Panel面板${PLAIN}     ${GREEN}h. Mihomo${PLAIN}         ${GREEN}m. Milivpn${PLAIN}"
        echo -e "${GREEN} f. Frp安装${PLAIN}        ${GREEN}7. 自动SSL证书${PLAIN}"
        echo -e "${GREEN} --- 工具/其他 ---"
        echo -e "${GREEN} 8. 性能测试${PLAIN}       ${GREEN}c. aria2安装${PLAIN}      ${GREEN}d. CD2安装${PLAIN}"
        echo -e "${GREEN} e. Rclone${PLAIN}         ${GREEN}g. YAML下载${PLAIN}       ${GREEN}j. Docker加速${PLAIN}"
        echo -e "${GREEN} z. Docker${PLAIN}         ${GREEN}i. Pve-Debian${PLAIN}     ${GREEN}l. LXC容器${PLAIN}"
        echo -e "${GREEN} u. 脚本更新${PLAIN}"
        echo -e "${RED} q. 退出脚本${PLAIN}"
        echo

        read -r -p "请输入选项: " choice
        case "$choice" in
            1) root_user ;;
            2) open_ports ;;
            3) tcp_bbr_optimize ;;
            5) banner "安装 Alist"
               if curl -fsSL https://res.oplist.org/script/v4.sh -o "$WORK_DIR/alist.sh"; then
                   bash "$WORK_DIR/alist.sh"
                   rm -f "$WORK_DIR/alist.sh"
               else
                   red "Alist 安装脚本下载失败"
               fi
               pause_return ;;
            6) banner "安装 x-ui"
               bash -c 'bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)'
               pause_return ;;
            7) banner "自动 SSL 证书"
               apt install git -y >/dev/null 2>&1
               bash -c 'bash <(curl -fsSL https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh)'
               pause_return ;;
            8) banner "性能测试"
               bash -c 'bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh)'
               pause_return ;;
            a) banner "安装 3X-UI 面板"
               bash -c 'bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)'
               pause_return ;;
            b) banner "BBR3 加速"
               bash -c 'bash <(curl -fsSL https://raw.githubusercontent.com/byJoey/Actions-bbr-v3/main/install.sh)'
               pause_return ;;
            c) banner "安装 aria2"
               run_script "https://git.io/aria2.sh" "aria2.sh"
               pause_return ;;
            d) banner "安装 CD2"
               bash -c 'bash <(curl -sSLf https://ailg.ggbond.org/cd2.sh)'
               pause_return ;;
            e) banner "安装 Rclone"
               bash -c 'curl https://rclone.org/install.sh | sudo bash'
               pause_return ;;
            f) frp_menu ;;
            g) banner "YAML 下载工具"
               rm -rf "$WORK_DIR/toolbox"
               git clone https://github.com/f1161291/toolbox "$WORK_DIR/toolbox" 2>/dev/null \
                   && bash "$WORK_DIR/toolbox/tool.sh" \
                   || red "克隆仓库失败，请检查网络"
               pause_return ;;
            i) banner "Pve-Debian"
               bash -c 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh)"'
               pause_return ;;
            j) banner "Docker 加速"
               bash -c 'curl -fsSL https://raw.githubusercontent.com/sky22333/hubproxy/main/install.sh | sh'
               pause_return ;;
            l) banner "LXC 容器"
               bash -c 'bash -c "$(curl -sSL https://www.linkease.com/rd/fastpve/)"'
               pause_return ;;
            n) banner "安装 1Panel"
               bash -c 'bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"'
               pause_return ;;
            m) banner "安装 Milivpn"
               bash -c 'bash <(curl -Ls https://raw.githubusercontent.com/baoweise-bot/aimili-vpngate/main/install.sh)'
               pause_return ;;
            u) banner "脚本更新"
               apt update -y >/dev/null 2>&1
               download_script "https://js.xiray.cc.cd/https://raw.githubusercontent.com/f1161291/toolbox/refs/heads/main/tool.sh" tool.sh \
                   && bash tool.sh \
                   && rm -f tool.sh
               pause_return ;;
            x) banner "一键换源"
               bash -c 'bash <(curl -sSL https://linuxmirrors.cn/main.sh)'
               pause_return ;;
            h) banner "安装 Mihomo"
               apt install unzip -y >/dev/null 2>&1
               rm -rf "$WORK_DIR/clash-for-linux-install"
               git clone --branch master --depth 1 https://github.com/nelvko/clash-for-linux-install.git "$WORK_DIR/clash-for-linux-install" 2>/dev/null \
                   && bash "$WORK_DIR/clash-for-linux-install/install.sh" \
                   || red "克隆仓库失败，请检查网络"
               pause_return ;;
            z) banner "安装 Docker"
               bash -c 'curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun'
               pause_return ;;
            dd) banner "DD 系统"
                run_script "https://raw.githubusercontent.com/f1161291/other/refs/heads/main/dd.sh" "dd.sh"
                pause_return ;;
            q|Q) green "已退出脚本"; exit 0 ;;
            *) red "无效选项！"; sleep 1 ;;
        esac
    done
}

# ==================== 启动 ====================
mkdir -p "$WORK_DIR"
ensure_deps >/dev/null 2>&1
menu
