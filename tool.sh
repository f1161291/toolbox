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

# 设置 sshd 选项：删除旧配置行并插入到首个 Match 块之前（若存在）
# 仅在系统不支持 sshd_config.d Include 时作为回退使用
sshd_set_option() {
    local conf="$1" key="$2" value="$3" line="$2 $3"
    local tmp="${conf}.tmp.$$"
    awk -v key="$key" -v line="$line" '
        {
            tok = $1
            sub(/=.*/, "", tok)
            if (tok == key) next
            if (!done && tok == "Match") { print line; done = 1 }
            print
        }
        END { if (!done) print line }
    ' "$conf" > "$tmp" || { rm -f "$tmp"; return 1; }
    cat "$tmp" > "$conf" && rm -f "$tmp"
}

# 应用 sshd 配置：优先写入 drop-in 文件（00- 前缀保证 first-value 优先，
# 避免被 /etc/ssh/sshd_config.d/*.conf 中的 cloud-init 等配置覆盖），
# 并在重启前校验语法与实际生效值，任何一步失败都回滚。
sshd_apply_options() {
    local conf=/etc/ssh/sshd_config
    local dropin_dir=/etc/ssh/sshd_config.d
    local dropin="$dropin_dir/00-cc-tool.conf"
    local port="$1"
    local bak dropin_bak
    bak=$(mktemp 2>/dev/null || echo "/tmp/sshd_config.bak.$$")
    dropin_bak=$(mktemp 2>/dev/null || echo "/tmp/sshd_dropin.bak.$$")

    if ! cp -f "$conf" "$bak" 2>/dev/null; then
        red "备份 SSH 配置失败"
        return 1
    fi
    : > "$dropin_bak"
    [[ -f "$dropin" ]] && cp -f "$dropin" "$dropin_bak" 2>/dev/null

    if grep -qE '^[[:space:]]*Include[[:space:]].*sshd_config\.d' "$conf" 2>/dev/null; then
        mkdir -p "$dropin_dir" 2>/dev/null
        cat > "$dropin" <<EOF
# 由 cc tool 生成，请勿手动修改
Port $port
PermitRootLogin yes
PasswordAuthentication yes
EOF
    else
        rm -f "$dropin"
        sshd_set_option "$conf" "Port" "$port"
        sshd_set_option "$conf" "PermitRootLogin" "yes"
        sshd_set_option "$conf" "PasswordAuthentication" "yes"
    fi

    local sshd_bin
    sshd_bin=$(type -P sshd 2>/dev/null || echo /usr/sbin/sshd)
    if [[ -x "$sshd_bin" ]]; then
        local ok=1
        "$sshd_bin" -t >/dev/null 2>&1 || ok=0
        if [[ $ok -eq 1 ]]; then
            local eff_port eff_root eff_pw
            eff_port=$("$sshd_bin" -T 2>/dev/null | awk '$1=="port"{print $2; exit}')
            eff_root=$("$sshd_bin" -T 2>/dev/null | awk '$1=="permitrootlogin"{print $2; exit}')
            eff_pw=$("$sshd_bin" -T 2>/dev/null | awk '$1=="passwordauthentication"{print $2; exit}')
            if [[ "$eff_port" != "$port" || "$eff_root" != "yes" || "$eff_pw" != "yes" ]]; then
                yellow "实际生效值与预期不符: port=$eff_port, root=$eff_root, password=$eff_pw"
                ok=0
            fi
        fi
        if [[ $ok -ne 1 ]]; then
            red "sshd 配置校验失败，已回滚！"
            cat "$bak" > "$conf"
            if [[ -s "$dropin_bak" ]]; then
                cat "$dropin_bak" > "$dropin"
            else
                rm -f "$dropin"
            fi
            rm -f "$bak" "$dropin_bak"
            return 1
        fi
    fi
    rm -f "$bak" "$dropin_bak"
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
# 安全约定：保留 TLS 证书校验，禁止中间人替换待执行的 root 脚本
# 用法: download_script <url> <本地文件>
download_script() {
    local url="$1"
    local file="$2"
    rm -f "$file"
    local ok=1
    if type -P curl >/dev/null 2>&1; then
        curl -fsSL --retry 2 -o "$file" "$url" || ok=0
    elif type -P wget >/dev/null 2>&1; then
        wget -q --tries=2 "$url" -O "$file" || ok=0
    else
        red "curl 和 wget 均不可用"
        return 1
    fi
    if [[ $ok -ne 1 || ! -s "$file" ]]; then
        red "下载失败或文件为空: $url"
        rm -f "$file"
        return 1
    fi
    chmod +x "$file"
    return 0
}

# 下载并运行脚本，自动处理非终端 stdin
# 用法: run_script <url> <本地名> [参数] [解释器]
run_script() {
    local url="$1"
    local name="${2:-script.sh}"
    local args="${3:-}"
    local interp="${4:-bash}"

    mkdir -p "$WORK_DIR"
    local target="$WORK_DIR/$name"
    download_script "$url" "$target" || return 1

    local ret=0
    # args 有意不加引号，用于支持多个参数
    # shellcheck disable=SC2086
    if [[ -t 0 ]]; then
        $interp "$target" $args
        ret=$?
    elif [[ -r /dev/tty ]]; then
        $interp "$target" $args < /dev/tty
        ret=$?
    else
        $interp "$target" $args
        ret=$?
    fi
    rm -f "$target"
    return $ret
}

# ==================== 依赖安装 ====================
# 只需 curl 或 wget 任一即可（download_script 优先使用 curl）
ensure_deps() {
    if type -P curl >/dev/null 2>&1 || type -P wget >/dev/null 2>&1; then
        return 0
    fi
    yellow "未检测到 curl/wget，正在安装 curl..."
    local os
    os=$(detect_os)
    case "$os" in
        Debian|Ubuntu)
            apt -y update >/dev/null 2>&1
            apt -y install curl >/dev/null 2>&1
            ;;
        CentOS)
            yum -y install curl >/dev/null 2>&1
            ;;
        Alpine)
            apk add --no-cache curl >/dev/null 2>&1
            ;;
        *)
            red "无法识别系统，请手动安装 curl 或 wget"
            return 1
            ;;
    esac
    if ! type -P curl >/dev/null 2>&1 && ! type -P wget >/dev/null 2>&1; then
        red "依赖安装失败: 需要 curl 或 wget"
        return 1
    fi
    green "依赖安装完成"
    return 0
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
        *armbian*) echo "Debian";;
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

    if [[ ! -f /etc/ssh/sshd_config ]]; then
        yellow "未检测到 sshd 配置，正在安装 openssh-server..."
        case "$os" in
            Debian|Ubuntu) apt -y update >/dev/null 2>&1; apt -y install openssh-server >/dev/null 2>&1 ;;
            CentOS) yum -y install openssh-server >/dev/null 2>&1 ;;
            Alpine) apk add --no-cache openssh-server >/dev/null 2>&1 ;;
        esac
    fi

    local sshport=22
    read -r -p "输入SSH端口（默认22）: " input_port
    if [[ -n "$input_port" ]] && validate_port "$input_port"; then
        sshport="$input_port"
    else
        [[ -n "$input_port" ]] && yellow "端口无效，使用默认22端口"
    fi

    local password
    password=$(generate_password)
    read -r -p "输入root密码（留空自动生成16位随机密码）: " input_pass
    [[ -n "$input_pass" ]] && password="$input_pass"

    # 仅在文件确实带不可变/只追加属性时解除，操作结束后恢复
    local attr_lock=""
    if type -P lsattr >/dev/null 2>&1; then
        local flags
        flags=$(lsattr /etc/passwd 2>/dev/null | awk '{print $1}')
        [[ "$flags" == *i* ]] && attr_lock="${attr_lock} i"
        [[ "$flags" == *a* ]] && attr_lock="${attr_lock} a"
    fi
    [[ -n "$attr_lock" ]] && chattr -i -a /etc/passwd /etc/shadow 2>/dev/null

    local pass_ok=1
    printf 'root:%s\n' "$password" | chpasswd 2>/dev/null || pass_ok=0
    for a in $attr_lock; do
        chattr "+$a" /etc/passwd /etc/shadow 2>/dev/null
    done
    if [[ $pass_ok -ne 1 ]]; then
        red "密码设置失败！"
        pause_return
        return 1
    fi

    # 配置校验与回滚在 sshd_apply_options 内部完成
    if ! sshd_apply_options "$sshport"; then
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
    yellow "请妥善保存！建议登录后立即修改密码，并限制 SSH 来源 IP。"

    pause_return
}

# 放行指定端口：不清空现有规则、不改默认策略、不动 Docker 链
open_ports() {
    check_root || { pause_return; return 1; }

    yellow "本选项只放行指定端口，不清空现有规则、不影响容器网络"
    read -r -p "输入要放行的端口（空格分隔，留空默认仅放行22）: " port_input

    local ports="" p
    for p in $port_input; do
        if validate_port "$p"; then
            ports="$ports $p"
        else
            yellow "忽略无效端口: $p"
        fi
    done
    ports="${ports:- 22}"

    local ok=1
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        for p in $ports; do
            firewall-cmd --permanent --add-port="${p}/tcp" >/dev/null 2>&1 || ok=0
        done
        firewall-cmd --reload >/dev/null 2>&1 || ok=0
    elif type -P ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q '^Status: active'; then
        for p in $ports; do
            ufw allow "${p}/tcp" >/dev/null 2>&1 || ok=0
        done
    elif type -P iptables >/dev/null 2>&1; then
        iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null \
            || iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
        for p in $ports; do
            if ! iptables -C INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null; then
                iptables -I INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null || ok=0
            fi
        done
        if type -P netfilter-persistent >/dev/null 2>&1; then
            netfilter-persistent save >/dev/null 2>&1
        elif [[ -d /etc/sysconfig ]]; then
            iptables-save > /etc/sysconfig/iptables 2>/dev/null
        fi
    else
        yellow "未检测到 firewalld/ufw/iptables，未做任何更改"
        pause_return
        return 1
    fi

    if [[ $ok -eq 1 ]]; then
        green "已放行端口:${ports}"
        yellow "现有规则、默认策略与 Docker 链均未改动"
    else
        yellow "部分规则添加失败，请手动检查"
    fi
    pause_return
}

tcp_bbr_optimize() {
    check_root || { pause_return; return 1; }

    mkdir -p /etc/sysctl.d
    local conf=/etc/sysctl.d/99-cc-tool.conf
    local bak
    bak=$(mktemp 2>/dev/null || echo "/tmp/sysctl.bak.$$")
    if [[ -f "$conf" ]]; then
        cp -f "$conf" "$bak" 2>/dev/null || : > "$bak"
    else
        : > "$bak"
    fi

    cat > "$conf" << 'EOF'
# 由 cc tool 生成
# 文件系统
fs.file-max=65535
fs.inotify.max_user_instances=1024
# 网络转发（容器/代理需要）
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
# TCP 基础优化
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_max_syn_backlog=8192
net.core.netdev_max_backlog=8192
net.core.somaxconn=4096
net.ipv4.tcp_keepalive_time=300
# 缓冲区
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 16384 16777216
# BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

    if ! sysctl -p "$conf" >/dev/null 2>&1; then
        yellow "部分参数应用失败（内核可能不支持），正在回滚该文件"
        cat "$bak" > "$conf" 2>/dev/null || rm -f "$conf"
        rm -f "$bak"
        pause_return
        return 1
    fi
    rm -f "$bak"

    green "TCP/BBR 优化已完成！"
    if [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]]; then
        green "BBR 已加载"
    else
        yellow "BBR 未加载，可能需要重启或内核不支持"
    fi
    pause_return
}

# ==================== Frp ====================
install_frp() {
    local frp_type="$1"
    banner "正在安装 ${frp_type}..."

    mkdir -p "$WORK_DIR"
    if [[ "$frp_type" == "frps" ]]; then
        run_script "https://raw.githubusercontent.com/mvscode/frps-onekey/master/install-frps.sh" "install-frps.sh" "install"
    else
        if ! type -P curl >/dev/null 2>&1 && ! type -P wget >/dev/null 2>&1; then
            red "frpc 安装需要 curl 或 wget"
        else
            run_script "https://atusu.cn/frp/install_frpc.sh" "install_frpc.sh"
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
            1) if check_root; then install_frp "frps"; fi; pause_return; return ;;
            2) install_frp "frpc"; pause_return; return ;;
            0) return ;;
            *) red "无效选项！"; sleep 1 ;;
        esac
    done
}

# ==================== Docker 安装辅助函数 ====================
install_docker_aliyun() {
    local os_name
    os_name=$(detect_os)
    local os_path="debian"
    [[ "$os_name" == "Ubuntu" ]] && os_path="ubuntu"

    local script_url=""
    local script_file="$WORK_DIR/get-docker.sh"
    local urls=(
        "https://mirrors.aliyun.com/docker-ce/linux/${os_path}/get-docker.sh"
        "https://mirrors.azure.cn/docker-ce/linux/${os_path}/get-docker.sh"
        "https://raw.githubusercontent.com/docker/docker-install/master/install.sh"
    )

    mkdir -p "$WORK_DIR"
    for url in "${urls[@]}"; do
        yellow "正在尝试从以下地址下载安装脚本: $url"
        if download_script "$url" "$script_file"; then
            script_url="$url"
            green "脚本下载成功！"
            break
        else
            red "下载失败，尝试下一个源..."
        fi
    done

    if [[ -z "$script_url" ]]; then
        red "所有镜像源均下载失败，建议选择【3】使用 LinuxMirrors 一键安装。"
        return 1
    fi

    if [[ -t 0 ]]; then
        bash "$script_file" --mirror Aliyun
    elif [[ -r /dev/tty ]]; then
        bash "$script_file" --mirror Aliyun < /dev/tty
    else
        bash "$script_file" --mirror Aliyun
    fi
    local ret=$?
    rm -f "$script_file"
    return $ret
}

# ==================== 主菜单 ====================
menu() {
    while true; do
        clear 2>/dev/null
        echo -e "${RED}=================================="
        echo -e "${GREEN}          cc tool              "
        echo -e "${RED}        cc Linux一键运行脚本    "
        echo -e "                                   "
        echo -e "${RED}=================================="
        echo -e "                                   "
        echo -e "${GREEN} 1. root/SSH修改"
        echo -e "${GREEN} 2. 放行指定端口"
        echo -e "${GREEN} 3. TCP/BBR优化"
        echo -e "${GREEN} 4. PVE优化"
        echo -e "${GREEN} 5. 安装Alist"
        echo -e "${GREEN} 6. 安装x-ui"
        echo -e "${GREEN} 7. 自动SSL证书"
        echo -e "${GREEN} 8. 性能测试"
        echo -e "${GREEN} a. 3X-UI面板"
        echo -e "${GREEN} b. BBR3加速"
        echo -e "${GREEN} c. aria2安装"
        echo -e "${GREEN} d. CD2安装"
        echo -e "${GREEN} e. Rclone"
        echo -e "${GREEN} f. Frp安装"
        echo -e "${GREEN} g. YAML下载"
        echo -e "${GREEN} h. Caddy安装"
        echo -e "${GREEN} i. Pve-Debian"
        echo -e "${GREEN} j. Docker加速"
        echo -e "${GREEN} l. LXC容器"
        echo -e "${GREEN} n. 1Panel面板"
        echo -e "${GREEN} m. Milivpn"
        echo -e "${GREEN} H. Mihomo"
        echo -e "${GREEN} u. 脚本更新"
        echo -e "${GREEN} x. 一键换源"
        echo -e "${GREEN} z. Docker"
        echo -e "${RED}dd. DD系统"
        echo -e "${GREEN} q. 退出脚本"
        echo -e "${PLAIN}"

        read -r -p "请输入选项: " choice
        case "$choice" in
            1) root_user ;;
            2) open_ports ;;
            3) tcp_bbr_optimize ;;
            4) banner "PVE 优化"; run_script "https://pve.u3u.icu/PVE-Tools.sh" "pve-tools.sh"; pause_return ;;
            5) banner "安装 Alist"
               run_script "https://res.oplist.org/script/v4.sh" "alist.sh"
               pause_return ;;
            6) banner "安装 x-ui"
               run_script "https://raw.githubusercontent.com/f1161291/x-ui/master/install.sh" "x-ui.sh"
               pause_return ;;
            7) banner "自动 SSL 证书"
               if ! type -P git >/dev/null 2>&1; then
                   case "$(detect_os)" in
                       Debian|Ubuntu) apt -y install git >/dev/null 2>&1 ;;
                       CentOS) yum -y install git >/dev/null 2>&1 ;;
                       Alpine) apk add --no-cache git >/dev/null 2>&1 ;;
                   esac
               fi
               run_script "https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh" "acme.sh"
               pause_return ;;
            8) banner "性能测试"
               run_script "https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh" "oalive.sh"
               pause_return ;;
            a) banner "安装 3X-UI"
               run_script "https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh" "3x-ui.sh"
               pause_return ;;
            b) banner "BBR3 加速"
               run_script "https://raw.githubusercontent.com/byJoey/Actions-bbr-v3/main/install.sh" "bbr3.sh"
               pause_return ;;
            c) banner "安装 aria2"
               run_script "https://raw.githubusercontent.com/P3TERX/aria2.sh/master/aria2.sh" "aria2.sh"
               pause_return ;;
            d) banner "安装 CD2"
               run_script "https://ailg.ggbond.org/cd2.sh" "cd2.sh"
               pause_return ;;
            e) banner "安装 Rclone"
               check_root && run_script "https://rclone.org/install.sh" "rclone.sh"
               pause_return ;;
            f) frp_menu ;;
            g) banner "YAML 下载"
               if type -P git >/dev/null 2>&1; then
                   ( rm -rf /tmp/cc-tool/toolbox \
                     && git clone --depth 1 https://github.com/f1161291/toolbox /tmp/cc-tool/toolbox \
                     && green "已下载到 /tmp/cc-tool/toolbox" ) \
                       || red "克隆失败，请检查网络"
               else
                   red "未安装 git，无法下载"
               fi
               pause_return ;;
            h) banner "安装 Caddy (caddy_emby)"
               run_script "https://raw.githubusercontent.com/AiLi1337/caddy_emby/main/install_caddy_emby.sh" "caddy_emby.sh"
               pause_return ;;
            i) banner "Pve-Debian"
               run_script "https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh" "pve-debian.sh"
               pause_return ;;
            j) banner "Docker 加速"
               run_script "https://raw.githubusercontent.com/sky22333/hubproxy/main/install.sh" "hubproxy.sh" "" sh
               pause_return ;;
            l) banner "LXC 容器"
               run_script "https://www.linkease.com/rd/fastpve/" "fastpve.sh"
               pause_return ;;
            n) banner "安装 1Panel"
               run_script "https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh" "1panel.sh"
               pause_return ;;
            m) banner "安装 Milivpn"
               run_script "https://raw.githubusercontent.com/baoweise-bot/aimili-vpngate/main/install.sh" "milivpn.sh"
               pause_return ;;
            H|h2) banner "安装 Mihomo"
               if ! type -P git >/dev/null 2>&1; then
                   case "$(detect_os)" in
                       Debian|Ubuntu) apt -y install git >/dev/null 2>&1 ;;
                       CentOS) yum -y install git >/dev/null 2>&1 ;;
                       Alpine) apk add --no-cache git >/dev/null 2>&1 ;;
                   esac
               fi
               case "$(detect_os)" in
                   Debian|Ubuntu) apt -y install unzip >/dev/null 2>&1 ;;
                   CentOS) yum -y install unzip >/dev/null 2>&1 ;;
                   Alpine) apk add --no-cache unzip >/dev/null 2>&1 ;;
               esac
               rm -rf "$WORK_DIR/clash-for-linux-install"
               if git clone --branch master --depth 1 https://github.com/nelvko/clash-for-linux-install.git "$WORK_DIR/clash-for-linux-install" 2>/dev/null; then
                   if [[ -t 0 ]]; then
                       bash "$WORK_DIR/clash-for-linux-install/install.sh"
                   elif [[ -r /dev/tty ]]; then
                       bash "$WORK_DIR/clash-for-linux-install/install.sh" < /dev/tty
                   else
                       bash "$WORK_DIR/clash-for-linux-install/install.sh"
                   fi
               else
                   red "克隆失败，请检查网络或 git 是否已安装"
               fi
               pause_return ;;
            u) banner "脚本更新（下载并运行最新版）"
               run_script "https://raw.githubusercontent.com/f1161291/toolbox/refs/heads/main/tool.sh" "tool-latest.sh"
               pause_return ;;
            x) banner "一键换源"
               run_script "https://linuxmirrors.cn/main.sh" "mirrors.sh"
               pause_return ;;
            z) banner "安装 Docker"
               echo -e "  ${GREEN}1.${PLAIN} 使用官方源安装"
               echo -e "  ${GREEN}2.${PLAIN} 使用 LinuxMirrors 一键安装 (推荐国内环境)"
               echo -e "  ${YELLOW}0.${PLAIN} 取消"
               echo -e "${YELLOW}============================================${PLAIN}"
               read -r -p "请选择 [1/2/0]: " docker_choice
               case "$docker_choice" in
                   1) run_script "https://get.docker.com" "get-docker.sh" "" ;;
                   2) run_script "https://linuxmirrors.cn/docker.sh" "docker-mirrors.sh" "" ;;
                   0) yellow "已取消安装 Docker" ;;
                   *) red "无效选项，已取消" ;;
               esac
               pause_return ;;
            dd) banner "DD 系统（不可逆操作，请确认已备份数据）"
                read -r -p "确认继续请输入 yes: " dd_confirm
                if [[ "$dd_confirm" == "yes" ]]; then
                    run_script "https://raw.githubusercontent.com/f1161291/other/refs/heads/main/dd.sh" "dd.sh"
                else
                    yellow "已取消 DD 系统"
                fi
                pause_return ;;
            q|Q) green "已退出脚本"; exit 0 ;;
            *) red "无效选项！"; sleep 1 ;;
        esac
    done
}

# ==================== 启动 ====================
mkdir -p "$WORK_DIR"

# 若通过管道运行（curl | bash），把 stdin 切回终端，避免菜单和子脚本读不到输入
if [[ ! -t 0 ]] && [[ -r /dev/tty ]]; then
    exec < /dev/tty
fi

# 依赖检查：明确输出，不再静默吞掉错误
if ! ensure_deps; then
    red "依赖检查未通过，脚本无法继续运行"
    exit 1
fi

# 本工具箱绝大多数选项需要 root，非 root 直接退出，避免静默失败
if [[ $EUID -ne 0 ]]; then
    red "请以 root 用户运行本脚本（例如: sudo bash tool.sh）"
    exit 1
fi

menu
