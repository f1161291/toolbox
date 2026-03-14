#!/usr/bin/env bash

# 当前脚本版本号和新增功能
VERSION='1.3.2'

# 环境变量用于在Debian或Ubuntu操作系统中设置非交互式（noninteractive）安装模式
export DEBIAN_FRONTEND=noninteractive

# Github 反代加速代理
GITHUB_PROXY=('' 'https://gh.130401.xyz/'  'https://v6.gh-proxy.org/' 'https://gh-proxy.com/' 'https://hub.glowp.xyz/' 'https://proxy.vvvv.ee/' 'https://ghproxy.lvedong.eu.org/')

trap cleanup_resources EXIT INT TERM

E[0]="Language:\n  1.English (default) \n  2.简体中文"
C[0]="${E[0]}"
E[1]="Use fixed IP endpoints on IPv4-only / IPv6-only hosts"
C[1]="为 IPv4 / IPv6 only 主机使用固定 IP 端点"
E[2]="warp-go h (help)\n warp-go o (temporary warp-go switch)\n warp-go u (uninstall WARP web interface and warp-go)\n warp-go v (sync script to latest version)\n warp-go i (replace IP with Netflix support)\n warp-go 4/6 ( WARP IPv4/IPv6 single-stack)\n warp-go d (WARP dual-stack)\n warp-go n (WARP IPv4 non-global)\n warp-go g (WARP global/non-global switching)\n warp-go e (output wireguard and sing-box configuration file)\n warp-go s 4/6/d (Set stack proiority: IPv4 / IPv6 / VPS default)\n"
C[2]="warp-go h (帮助）\n warp-go o (临时 warp-go 开关)\n warp-go u (卸载 WARP 网络接口和 warp-go)\n warp-go v (同步脚本至最新版本)\n warp-go i (更换支持 Netflix 的IP)\n warp-go 4/6 (WARP IPv4/IPv6 单栈)\n warp-go d (WARP 双栈)\n warp-go n (WARP IPv4 非全局)\n warp-go g (WARP 全局 / 非全局相互切换)\n warp-go e (输出 wireguard 和 sing-box 配置文件)\n warp-go s 4/6/d (优先级: IPv4 / IPv6 / VPS default)\n"
E[3]="This project is designed to add WARP network interface for VPS, using warp-go core, using various interfaces of CloudFlare-WARP, integrated wireguard-go, can completely replace WGCF. Save Hong Kong, Toronto and other VPS, can also get WARP IP. Thanks again @CoiaPrant and his team. Project address: https://gitlab.com/ProjectWARP/warp-go/-/tree/master/"
C[3]="本项目专为 VPS 添加 WARP 网络接口，使用 wire-go 核心程序，利用CloudFlare-WARP 的各类接口，集成 wireguard-go，可以完全替代 WGCF。 救活了香港、多伦多等 VPS 也可以获取 WARP IP。再次感谢 @CoiaPrant 及其团队。项目地址: https://gitlab.com/ProjectWARP/warp-go/-/tree/master/"
E[4]="Choose:"
C[4]="请选择:"
E[5]="You must run the script as root. You can type sudo -i and then download and run it again. Feedback:[https://github.com/fscarmen/warp-sh/issues]"
C[5]="必须以root方式运行脚本，可以输入 sudo -i 后重新下载运行，问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[6]="This script only supports Debian, Ubuntu, CentOS, Arch or Alpine systems, Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[6]="本脚本只支持 Debian、Ubuntu、CentOS、Arch 或 Alpine 系统,问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[7]="global"
C[7]="全局"
E[8]="Install dependence-list:"
C[8]="安装依赖列表:"
E[9]="Best MTU found."
C[9]="已找到最佳 MTU"
E[10]="No suitable solution was found for modifying the warp-go configuration file warp.conf and the script aborted. When you see this message, please send feedback on the bug to:[https://github.com/fscarmen/warp-sh/issues]"
C[10]="没有找到适合的方案用于修改 warp-go 配置文件 warp.conf，脚本中止。当你看到此信息，请把该 bug 反馈至:[https://github.com/fscarmen/warp-sh/issues]"
E[11]="Warp-go is not installed yet."
C[11]="还没有安装 warp-go"
E[12]="To install, press [y] and other keys to exit:"
C[12]="如需安装，请按[y]，其他键退出:"
E[13]="\$(date +'%F %T') Try \${i}. Failed. IPv\$NF: \$WAN  \$COUNTRY  \$ASNORG. Retry after \${l} seconds. Brush ip runing time:\$DAY days \$HOUR hours \$MIN minutes \$SEC seconds"
C[13]="\$(date +'%F %T') 尝试第\${i}次，解锁失败，IPv\$NF: \$WAN  \$COUNTRY  \$ASNORG，\${l}秒后重新测试，刷 IP 运行时长: \$DAY 天 \$HOUR 时 \$MIN 分 \$SEC 秒"
E[14]="1. Brush WARP IPv4\n 2. Brush WARP IPv6 (default)"
C[14]="1. 刷 WARP IPv4\n 2. 刷 WARP IPv6 (默认)"
E[15]="The current Netflix region is:\$REGION. To unlock the current region please press [y]. For other addresses please enter two regional abbreviations \(e.g. hk,sg, default:\$REGION\):"
C[15]="当前 Netflix 地区是:\$REGION，需要解锁当前地区请按 y , 如需其他地址请输入两位地区简写 \(如 hk ,sg，默认:\$REGION\):"
E[16]="\$(date +'%F %T') Region: \$REGION Done. IPv\$NF: \$WAN  \$COUNTRY  \$ASNORG. Retest after 1 hour. Brush ip runing time:\$DAY days \$HOUR hours \$MIN minutes \$SEC seconds"
C[16]="\$(date +'%F %T') 区域 \$REGION 解锁成功，IPv\$NF: \$WAN  \$COUNTRY  \$ASNORG，1 小时后重新测试，刷 IP 运行时长: \$DAY 天 \$HOUR 时 \$MIN 分 \$SEC 秒"
E[17]="WARP network interface and warp-go have been completely removed!"
C[17]="WARP 网络接口及 warp-go 已彻底删除!"
E[18]="Successfully synchronized the latest version"
C[18]="成功！已同步最新脚本，版本号"
E[19]="New features"
C[19]="功能新增"
E[20]="Maximum \${j} attempts to get WARP IP..."
C[20]="后台获取 WARP IP 中, 最大尝试\${j}次……"
E[21]="IPv\$PRIO priority"
C[21]="IPv\$PRIO 优先"
E[22]="Current Teams account is not available. Switch back to free account automatically."
C[22]="当前 Teams 账户不可用，自动切换回免费账户"
E[23]="Failed more than \${j} times, script aborted. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[23]="失败已超过\${j}次，脚本中止，问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[24]="non-"
C[24]="非"
E[25]="Successfully got WARP \$ACCOUNT_TYPE network.\\\n Running in \${GLOBAL_TYPE}global mode."
C[25]="已成功获取 WARP \$ACCOUNT_TYPE 网络\\\n 运行在 \${GLOBAL_TYPE}全局 模式"
E[83]="Cannot detect any IPv4 or IPv6. The script is aborted. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[83]="检测不到任何 IPv4 或 IPv6。脚本中止，问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[27]="WARP is turned off. It could be turned on again by [warp-go o]"
C[27]="已暂停 WARP，再次开启可以用 warp-go o"
E[28]="WARP Non-global mode cannot switch between single and double stacks."
C[28]="WARP 非全局模式下不能切换单双栈"
E[29]="To switch to global mode, press [y] and other keys to exit:"
C[29]="如需更换为全局模式，请按[y]，其他键退出:"
E[30]="Cannot switch to the same form as the current one."
C[30]="不能切换为当前一样的形态"
E[31]="Switch \${WARP_BEFORE[m]} to \${WARP_AFTER1[m]}"
C[31]="\${WARP_BEFORE[m]} 转为 \${WARP_AFTER1[m]}"
E[32]="Switch \${WARP_BEFORE[m]} to \${WARP_AFTER2[m]}"
C[32]="\${WARP_BEFORE[m]} 转为 \${WARP_AFTER2[m]}"
E[33]="WARP network interface can be switched as follows:\\\n 1. \${OPTION[1]}\\\n 2. \${OPTION[2]}\\\n 0. Exit script"
C[33]="WARP 网络接口可以切换为以下方式:\\\n 1. \${OPTION[1]}\\\n 2. \${OPTION[2]}\\\n 0. 退出脚本"
E[34]="Please enter the correct number"
C[34]="请输入正确数字"
E[35]="Checking VPS infomation..."
C[35]="检查环境中……"
E[36]="The TUN module is not loaded. You should turn it on in the control panel. Ask the supplier for more help. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[36]="没有加载 TUN 模块，请在管理后台开启或联系供应商了解如何开启，问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[37]="Curren architecture \$(uname -m) is not supported. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[37]="当前架构 \$(uname -m) 暂不支持,问题反馈:[https://github.com/fscarmen/warp-sh/issues]"
E[38]="Version"
C[38]="脚本版本"
E[39]="New features"
C[39]="功能新增"
E[40]="System infomation"
C[40]="系统信息"
E[41]="Operating System"
C[41]="当前操作系统"
E[42]="Kernel"
C[42]="内核"
E[43]="Architecture"
C[43]="处理器架构"
E[44]="Virtualization"
C[44]="虚拟化"
E[45]="WARP \$TYPE Interface is on"
C[45]="WARP \$TYPE 网络接口已开启"
E[46]="Running in \${GLOBAL_TYPE}global mode"
C[46]="运行在 \${GLOBAL_TYPE}全局 模式"
E[47]="WARP network interface is not turned on"
C[47]="WARP 网络接口未开启"
E[48]="Native dualstack"
C[48]="原生双栈"
E[49]="Run again with warp-go [option] [lisence], such as"
C[49]="再次运行用 warp-go [option] [lisence]，如"
E[50]="Registration of WARP account failed, script aborted. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[50]="注册 WARP 账户失败，脚本中止，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[51]="Warp-go not yet installed. No account registered. Script aborted. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[51]="warp-go 还没有安装，没有注册账户，脚本中止，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[52]="Wireguard configuration file: /opt/warp-go/wgcf.conf\n"
C[52]="Wireguard 配置文件: /opt/warp-go/wgcf.conf\n"
E[53]="Warp-go installed. Script aborted. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[53]="warp-go 已安装，脚本中止，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[54]="Sing-box configuration file: /opt/warp-go/singbox.json\n"
C[54]="Sing-box 配置文件: /opt/warp-go/singbox.json\n"
E[55]="Please choose the priority:\n  1. IPv4\n  2. IPv6\n  3. Use initial settings (default)"
C[55]="请选择优先级别:\n  1. IPv4\n  2. IPv6\n  3. 使用 VPS 初始设置 (默认)"
E[56]="Download warp-go zip file unsuccessful. Script exits. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[56]="下载 warp-go 压缩文件不成功，脚本退出，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[57]="Warp-go file does not exist, script exits. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[57]="Warp-go 文件不存在，脚本退出，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[58]="Attempts to register WARP account..."
C[58]="注册 WARP 账户中……"
E[59]="Try \${i}"
C[59]="第\${i}次尝试"
E[60]="Non-global"
C[60]="非全局"
E[61]="Install warp-go..."
C[61]="已安装 warp-go"
E[62]="Congratulations! WARP \$ACCOUNT_TYPE has been turn on. Total time spent:\$(( end - start )) seconds.\\\n Number of script runs in the day: \$TODAY. Total number of runs: \$TOTAL."
C[62]="恭喜！WARP \$ACCOUNT_TYPE 已开启，总耗时: \$(( end - start ))秒\\\n 脚本当天运行次数: \$TODAY，累计运行次数: \$TOTAL"
E[63]="Warp-go installation failed. Feedback: [https://github.com/fscarmen/warp-sh/issues]"
C[63]="warp-go 安装失败，问题反馈: [https://github.com/fscarmen/warp-sh/issues]"
E[64]="Add WARP IPv4 global network interface for \${NATIVE[n]}, IPv4 priority \(bash warp-go.sh 4\)"
C[64]="为 \${NATIVE[n]} 添加 WARP IPv4 全局 网络接口，IPv4 优先 \(bash warp-go.sh 4\)"
E[65]="Add WARP IPv4 global network interface for \${NATIVE[n]}, IPv6 priority \(bash warp-go.sh 4\)"
C[65]="为 \${NATIVE[n]} 添加 WARP IPv4 全局 网络接口，IPv6 优先 \(bash warp-go.sh 4\)"
E[66]="Add WARP IPv6 global network interface for \${NATIVE[n]}, IPv4 priority \(bash warp-go.sh 6\)"
C[66]="为 \${NATIVE[n]} 添加 WARP IPv6 全局 网络接口，IPv4 优先 \(bash warp-go.sh 6\)"
E[67]="Add WARP IPv6 global network interface for \${NATIVE[n]}, IPv6 priority \(bash warp-go.sh 6\)"
C[67]="为 \${NATIVE[n]} 添加 WARP IPv6 全局 网络接口，IPv6 优先 \(bash warp-go.sh 6\)"
E[68]="Add WARP dual-stacks global network interface for \${NATIVE[n]}, IPv4 priority \(bash warp-go.sh d\)"
C[68]="为 \${NATIVE[n]} 添加 WARP 双栈 全局 网络接口，IPv4 优先 \(bash warp-go.sh d\)"
E[69]="Add WARP dual-stacks global network interface for \${NATIVE[n]}, IPv6 priority \(bash warp-go.sh d\)"
C[69]="为 \${NATIVE[n]} 添加 WARP 双栈 全局 网络接口，IPv6 优先 \(bash warp-go.sh d\)"
E[70]="Add WARP dual-stacks non-global network interface for \${NATIVE[n]}, IPv4 priority \(bash warp-go.sh n\)"
C[70]="为 \${NATIVE[n]} 添加 WARP 双栈 非全局 网络接口，IPv4 优先 \(bash warp-go.sh n\)"
E[71]="Add WARP dual-stacks non-global network interface for \${NATIVE[n]}, IPv6 priority \(bash warp-go.sh n\)"
C[71]="为 \${NATIVE[n]} 添加 WARP 双栈 非全局 网络接口，IPv6 优先 \(bash warp-go.sh n\)"
E[72]="Turn off warp-go (warp-go o)"
C[72]="关闭 warp-go (warp-go o)"
E[73]="Turn on warp-go (warp-go o)"
C[73]="打开 warp-go (warp-go o)"
E[74]="\${WARP_BEFORE[m]} switch to \${WARP_AFTER1[m]} \${SHORTCUT1[m]}"
C[74]="\${WARP_BEFORE[m]} 转为 \${WARP_AFTER1[m]} \${SHORTCUT1[m]}"
E[75]="\${WARP_BEFORE[m]} switch to \${WARP_AFTER2[m]} \${SHORTCUT2[m]}"
C[75]="\${WARP_BEFORE[m]} 转为 \${WARP_AFTER2[m]} \${SHORTCUT2[m]}"
E[76]="Switch to WARP \${GLOBAL_AFTER}global network interface  \(warp-go g\)"
C[76]="转为 WARP \${GLOBAL_AFTER}全局 网络接口  \(warp-go g\)"
E[77]="WAN interface network protocol must be [static] on OpenWrt."
C[77]="OpenWrt 系统的 WAN 接口的网络传输协议必须为 [静态地址]"
E[78]="Change the WARP IP to support Netflix (warp-go i)"
C[78]="更换支持 Netflix 的 IP (warp-go i)"
E[79]="Export wireguard and sing-box configuration file (warp-go e)"
C[79]="输出 wireguard 和 sing-box 配置文件 (warp-go e)"
E[80]="Uninstall the WARP interface and warp-go (warp-go u)"
C[80]="卸载 WARP 网络接口和 warp-go (warp-go u)"
E[81]="Exit"
C[81]="退出脚本"
E[82]="Sync the latest version (warp-go v)"
C[82]="同步最新版本 (warp-go v)"
E[83]="dualstack"
C[83]="双栈"

# 自定义字体彩色，read 函数
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }  # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m"; rm -f /tmp/warp-go*; exit 1; }  # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }   # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }   # 黄色
reading() { read -rp "$(info "$1")" "$2"; }
text() { eval echo "\${${L}[$*]}"; }
text_eval() { eval echo "\$(eval echo "\${${L}[$*]}")"; }

# 清理函数
cleanup_resources() {
  rm -f /tmp/{statistics,warp-go*} 2>/dev/null; exit 0
}

# 检测是否需要启用 Github CDN，如能直接连通，则不使用
check_cdn() {
  # GITHUB_PROXY 数组第一个元素为空，相当于直连
  for PROXY_URL in "${GITHUB_PROXY[@]}"; do
    local PROXY_STATUS_CODE=$(wget --server-response --spider --quiet --timeout=3 --tries=1 ${PROXY_URL}https://raw.githubusercontent.com/fscarmen/warp-sh/main/README.md 2>&1 | awk '/HTTP\//{last_field = $2} END {print last_field}')
    [ "$PROXY_STATUS_CODE" = "200" ] && GH_PROXY="$PROXY_URL" && break
  done
}

# 脚本当天及累计运行次数统计
statistics_of_run-times() {
  local UPDATE_OR_GET=$1
  local SCRIPT=$2
  if grep -q 'update' <<< "$UPDATE_OR_GET"; then
    { wget --no-check-certificate -qO- --timeout=3 "https://stat.cloudflare.now.cc/api/updateStats?script=${SCRIPT}" > /tmp/statistics; }&
  elif grep -q 'get' <<< "$UPDATE_OR_GET"; then
    [ -s /tmp/statistics ] && [[ $(cat /tmp/statistics) =~ \"todayCount\":([0-9]+),\"totalCount\":([0-9]+) ]] && TODAY="${BASH_REMATCH[1]}" && TOTAL="${BASH_REMATCH[2]}" && rm -f /tmp/statistics
  fi
}

# 选择语言，先判断 /opt/warp-go/language 里的语言选择，没有的话再让用户选择，默认英语。处理中文显示的问题
select_language() {
  UTF8_LOCALE=$(locale -a 2>/dev/null | grep -iEm1 "UTF-8|utf8")
  [ -n "$UTF8_LOCALE" ] && export LC_ALL="$UTF8_LOCALE" LANG="$UTF8_LOCALE" LANGUAGE="$UTF8_LOCALE"

  if [ -s /opt/warp-go/language ]; then
    L=$(cat /opt/warp-go/language)
  else
    L=E && [[ -z "$OPTION" || "$OPTION" = [ahvi46d] ]] && hint " $(text 0) \n" && reading " $(text 4) " LANGUAGE
    [ "$LANGUAGE" = 2 ] && L=C
  fi
}

# 必须以root运行脚本
check_root_virt() {
  [ "$(id -u)" != 0 ] && error " $(text 5) "

  # 判断虚拟化，选择 Wireguard内核模块 还是 Wireguard-Go
  if [ "$1" = Alpine ]; then
    VIRT=$(virt-what)
  else
    [ $(type -p systemd-detect-virt) ] && VIRT=$(systemd-detect-virt)
    [[ -z "$VIRT" && $(type -p hostnamectl) ]] && VIRT=$(hostnamectl | awk '/Virtualization:/{print $NF}')
  fi
}

# 多方式判断操作系统，试到有值为止。只支持 Debian 9/10/11、Ubuntu 18.04/20.04/22.04 或 CentOS 7/8 ,如非上述操作系统，退出脚本
check_operating_system() {
  if [ -s /etc/os-release ]; then
    SYS="$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2);print $2;exit}' /etc/os-release)"
  elif [ -x "$(type -p hostnamectl)" ]; then
    SYS="$(awk -F: '/System/{sub(/^[ \t]+/,"",$2);print $2;exit}' < <(hostnamectl))"
  elif [ -x "$(type -p lsb_release)" ]; then
    SYS="$(lsb_release -sd)"
  elif [ -s /etc/lsb-release ]; then
    SYS="$(awk -F= '/^DISTRIB_DESCRIPTION=/{gsub(/"/,"",$2);print $2;exit}' /etc/lsb-release)"
  elif [ -s /etc/redhat-release ]; then
    SYS="$(awk '{print;exit}' /etc/redhat-release)"
  elif [ -s /etc/issue ]; then
    SYS="$(awk '{print;exit}' /etc/issue)"
  fi

  # 自定义 Alpine 系统若干函数
  alpine_warp_restart() {
    kill -15 $(pgrep warp-go) 2>/dev/null
    /opt/warp-go/warp-go --config=/opt/warp-go/warp.conf 2>&1 &
  }

  alpine_warp-go_enable() {
    echo -e "/opt/warp-go/tun.sh\n/opt/warp-go/warp-go --config=/opt/warp-go/warp.conf 2>&1 &" > /etc/local.d/warp-go.start
    chmod +x /etc/local.d/warp-go.start
    rc-update add local
  }

  REGEX=("debian" "ubuntu"  "armbian" "centos|red hat|kernel|alma|rocky|amazon linux" "alpine" "arch linux" "openwrt")
  RELEASE=("Debian" "Ubuntu"  "Armbian" "CentOS" "Alpine" "Arch" "OpenWrt")
  PACKAGE_UPDATE=("apt -y update" "apt -y update" "apt -y update" "yum -y update" "apk update -f" "pacman -Sy" "opkg update")
  PACKAGE_INSTALL=("apt -y install" "apt -y install" "apt -y install" "yum -y install" "apk add -f" "pacman -S --noconfirm" "opkg install")
  PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "apk del -f" "pacman -Rcnsu --noconfirm" "opkg remove --force-depends")
  SYSTEMCTL_START=("systemctl start warp-go" "systemctl start warp-go" "systemctl start warp-go" "systemctl start warp-go" "/opt/warp-go/warp-go --config=/opt/warp-go/warp.conf" "systemctl start warp-go" "/opt/warp-go/warp-go --config=/opt/warp-go/warp.conf")
  SYSTEMCTL_STOP=("systemctl stop warp-go" "systemctl stop warp-go" "systemctl stop warp-go" "systemctl stop warp-go" "kill -15 $(pgrep warp-go)" "systemctl stop warp-go" "kill -15 $(pgrep warp-go)")
  SYSTEMCTL_RESTART=("systemctl restart warp-go" "systemctl restart warp-go" "systemctl restart warp-go" "systemctl restart warp-go" "alpine_warp_restart" "systemctl restart wg-quick@wgcf" "alpine_warp_restart")
  SYSTEMCTL_ENABLE=("systemctl enable --now warp-go" "systemctl enable --now warp-go" "systemctl enable --now warp-go" "systemctl enable --now warp-go" "alpine_warp-go_enable" "systemctl enable --now warp-go")

  for int in "${!REGEX[@]}"; do
    [[ "${SYS,,}" =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && break
  done

  # 针对各厂运的订制系统
  if [ -z "$SYSTEM" ]; then
    [ $(type -p yum) ] && int=2 && SYSTEM='CentOS' || error " $(text 6) "
  fi

  [ "$SYSTEM" = OpenWrt ] && [[ ! $(uci show network.wan.proto 2>/dev/null | cut -d \' -f2)$(uci show network.lan.proto 2>/dev/null | cut -d \' -f2) =~ 'static' ]] && error " $(text 77) "
}

check_arch() {
  # 判断处理器架构
  case "$(uname -m)" in
    aarch64 )
      ARCHITECTURE=arm64
      ;;
    x86)
      ARCHITECTURE=386
      ;;
    x86_64 )
      CPU_FLAGS=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
      case "$CPU_FLAGS" in
        *avx512* )
          ARCHITECTURE=amd64v4
          ;;
        *avx2* )
          ARCHITECTURE=amd64v3
          ;;
        *sse3* )
          ARCHITECTURE=amd64v2
          ;;
        * )
          ARCHITECTURE=amd64
      esac
      ;;
    s390x )
      ARCHITECTURE=s390x
      ;;
    * )
      error " $(text_eval 37) "
  esac
}

# 安装系统依赖及定义 ping 指令
check_dependencies() {
  # 对于 Alpine 和 OpenWrt 系统，升级库并重新安装依赖
  if [[ "$SYSTEM" =~ Alpine|OpenWrt ]]; then
    DEPS_CHECK=("ping" "curl" "wget" "grep" "bash" "ip" "tar" "virt-what")
    DEPS_INSTALL=("iputils-ping" "curl" "wget" "grep" "bash" "iproute2" "tar" "virt-what")
  else
    # 对于三大系统需要的依赖
    [ "${SYSTEM}" = 'CentOS' ] && DEPS_INSTALL+=("vim-common") && DEPS_CHECK+=("vim")
    DEPS_CHECK=("ping" "wget" "curl" "systemctl" "ip")
    DEPS_INSTALL=("iputils-ping" "wget" "curl" "systemctl" "iproute2")
  fi

  # 根据系统添加特定的依赖
  case "$SYSTEM" in
    Alpine )
      DEPS_CHECK+=("openrc")
      DEPS_INSTALL+=("openrc")
      ;;
    Arch )
      DEPS_CHECK+=("resolvconf")
      DEPS_INSTALL+=("openresolv")
  esac

  for c in "${!DEPS_CHECK[@]}"; do
    [ ! $(type -p ${DEPS_CHECK[c]}) ] && [[ ! "${DEPS[@]}" =~ "${DEPS_INSTALL[c]}" ]] && DEPS+=(${DEPS_INSTALL[c]})
  done

  if [ "${#DEPS[@]}" -ge 1 ]; then
    info "\n $(text 8) ${DEPS[@]} \n"
    ${PACKAGE_UPDATE[int]} >/dev/null 2>&1
    ${PACKAGE_INSTALL[int]} ${DEPS[@]} >/dev/null 2>&1
  fi

  PING6='ping -6' && [ $(type -p ping6) ] && PING6='ping6'
}

# 获取 warp 账户信息
warp_api(){
  local RUN=$1
  local FILE_PATH=$2

  if [ -s "$FILE_PATH" ]; then
    # Teams 账户文件
    if grep -q 'xml version' $FILE_PATH; then
      local WARP_DEVICE_ID=$(grep 'correlation_id' $FILE_PATH | sed "s#.*>\(.*\)<.*#\1#")
      local WARP_TOKEN=$(grep 'warp_token' $FILE_PATH | sed "s#.*>\(.*\)<.*#\1#")
      local WARP_CLIENT_ID=$(grep 'client_id' $FILE_PATH | sed "s#.*client_id&quot;:&quot;\([^&]\{4\}\)&.*#\1#")

    # 官方 api 文件
    elif grep -q 'client_id' $FILE_PATH; then
      local WARP_DEVICE_ID=$(grep -m1 '"id' "$FILE_PATH" | cut -d\" -f4)
      local WARP_TOKEN=$(grep '"token' "$FILE_PATH" | cut -d\" -f4)
      local WARP_CLIENT_ID=$(grep 'client_id' "$FILE_PATH" | cut -d\" -f4)

    # client 文件，默认存放路径为 /var/lib/cloudflare-warp/reg.json
    elif grep -q 'registration_id' $FILE_PATH; then
      local WARP_DEVICE_ID=$(cut -d\" -f4 "$FILE_PATH")
      local WARP_TOKEN=$(cut -d\" -f8 "$FILE_PATH")

    # wgcf 文件，默认存放路径为 /etc/wireguard/wgcf-account.toml
    elif grep -q 'access_token' $FILE_PATH; then
      local WARP_DEVICE_ID=$(grep 'device_id' "$FILE_PATH" | cut -d\' -f2)
      local WARP_TOKEN=$(grep 'access_token' "$FILE_PATH" | cut -d\' -f2)

    # warp-go 文件，默认存放路径为 /opt/warp-go/warp.conf
    elif grep -q 'PrivateKey' $FILE_PATH; then
      local WARP_DEVICE_ID=$(awk -F' *= *' '/^Device/{print $2}' "$FILE_PATH")
      local WARP_TOKEN=$(awk -F' *= *' '/^Token/{print $2}' "$FILE_PATH")
    fi
  fi

  case "$RUN" in
    register )
      local ACCOUNT=$(curl --retry 500 --retry-delay 1 --max-time 2 --silent --location --fail "https://warp.cloudflare.nyc.mn/?run=register")
      grep -q '"id"' <<< "$ACCOUNT" && echo "$ACCOUNT"
      ;;
    cancel )
      # 只保留 Teams 或者预设账户，删除其他账户
      if ! grep -oqE '"id":[ ]+("(t.[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12})|b0fe9b24-3396-486e-a12d-c194dbbb7bfb")' $FILE_PATH; then
        curl --request DELETE "https://api.cloudflareclient.com/v0a2158/reg/${WARP_DEVICE_ID}" \
            --head \
            --silent \
            --location \
            --header 'User-Agent: okhttp/3.12.1' \
            --header 'CF-Client-Version: a-6.10-2158' \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer ${WARP_TOKEN}" | awk '/HTTP/{print $(NF-1)}'
      fi
      ;;
  esac
}

# 检测 warp-go 的安装状态。STATUS: 0-未安装; 1-已安装未启动; 2-已安装启动中; 3-脚本安装中
check_install() {
  if [ -s /opt/warp-go/warp.conf ]; then
    [[ "$(ip link show | awk -F': ' '{print $2}')" =~ "WARP" ]] && STATUS=2 || STATUS=1
  else
    STATUS=0
    {
      # 预下载 warp-go，并添加执行权限，如因 gitlab 接口问题未能获取，默认 v1.0.8
      latest=$(wget -qO- -T2 -t1 https://gitlab.com/api/v4/projects/ProjectWARP%2Fwarp-go/releases | awk -F '"' '{for (i=0; i<NF; i++) if ($i=="tag_name") {print $(i+2); exit}}' | sed "s/v//")
      latest=${latest:-'1.0.8'}
      wget --no-check-certificate -T5 -qO- https://gitlab.com/fscarmen/warp/-/raw/main/warp-go/warp-go_"$latest"_linux_"$ARCHITECTURE".tar.gz | tar xz -C /tmp/ warp-go
      chmod +x /tmp/warp-go
    }&
  fi
}

# 检测 IPv4 IPv6 信息，WARP Ineterface 开启，普通还是 Plus账户 和 IP 信息。由于 ip.sb 会对某些 ip 访问报 error code: 1015，所以使用备用 IP api: ifconfig.co
ip4_info() {
  unset IP4_JSON COUNTRY4 ASNORG4 TRACE4 IS_UNINSTALL
  IS_UNINSTALL="$1"
  grep -q 'is_uninstall' <<< "$IS_UNINSTALL" && unset INTERFACE_4
  [ "$L" = 'C' ] && IS_CHINESE=${IS_CHINESE:-'?lang=zh-CN'}
  local IP_JSON=$(curl --retry 2 -ks4m2 $INTERFACE_4 http://ip.cloudflare.nyc.mn${IS_CHINESE}) &&
  TRACE4=$(awk -F '"' '/"warp"/{print $4}' <<< "$IP_JSON") &&
  WAN4=$(awk -F '"' '/"ip"/{print $4}' <<< "$IP_JSON") &&
  COUNTRY4=$(awk -F '"' '/"country"/{print $4}' <<< "$IP_JSON") &&
  ASNORG4=$(awk -F '"' '/"isp"/{print $4}' <<< "$IP_JSON")
}

ip6_info() {
  unset IP6_JSON COUNTRY6 ASNORG6 TRACE6 IS_UNINSTALL
  IS_UNINSTALL="$1"
  grep -q 'is_uninstall' <<< "$IS_UNINSTALL" && unset INTERFACE_6
  [ "$L" = 'C' ] && IS_CHINESE=${IS_CHINESE:-'?lang=zh-CN'}
  local IP_JSON=$(curl --retry 2 -ks6m2 $INTERFACE_6 http://ip.cloudflare.nyc.mn${IS_CHINESE}) &&
  TRACE6=$(awk -F '"' '/"warp"/{print $4}' <<< "$IP_JSON") &&
  WAN6=$(awk -F '"' '/"ip"/{print $4}' <<< "$IP_JSON") &&
  COUNTRY6=$(awk -F '"' '/"country"/{print $4}' <<< "$IP_JSON") &&
  ASNORG6=$(awk -F '"' '/"isp"/{print $4}' <<< "$IP_JSON")
}

# 帮助说明
help() { hint " $(text 2) "; }

# IPv4 / IPv6 优先设置
stack_priority() {
  if [ "$SYSTEM" != OpenWrt ]; then
    [ "$OPTION" = s ] && case "$PRIORITY_SWITCH" in
      4 )
        PRIORITY=1
        ;;
      6 )
        PRIORITY=2
        ;;
      d )
        :
        ;;
      * )
        hint "\n $(text 55) \n" && reading " $(text 4) " PRIORITY
    esac

    [ -s /etc/gai.conf ] && sed -i '/^precedence \:\:ffff\:0\:0/d;/^label 2002\:\:\/16/d' /etc/gai.conf
    case "$PRIORITY" in
      1 )
        echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
        ;;
      2 )
        echo "label 2002::/16   2" >> /etc/gai.conf
    esac
  fi
}

# IPv4 / IPv6 优先结果
result_priority() {
  PRIO=(0 0)
  if [ -s /etc/gai.conf ]; then
    grep -qsE "^precedence[ ]+::ffff:0:0/96[ ]+100" /etc/gai.conf && PRIO[0]=1
    grep -qsE "^label[ ]+2002::/16[ ]+2" /etc/gai.conf && PRIO[1]=1
  fi
  case "${PRIO[*]}" in
    '1 0' )
      PRIO=4
      ;;
    '0 1' )
      PRIO=6
      ;;
    * )
      [[ "$(curl -ksm8 http://ip.cloudflare.nyc.mn | awk -F '"' '/"ip"/{print $4}')" =~ ^([0-9]{1,3}\.){3} ]] && PRIO=4 || PRIO=6
  esac
  PRIORITY_NOW=$(text_eval 21)

  # 如是快捷方式切换优先级别的话，显示结果
  [ "$OPTION" = s ] && hint "\n $PRIORITY_NOW \n"
}

need_install() {
  [ "$STATUS" = 0 ] && warning " $(text 11) " && reading " $(text 12) " TO_INSTALL
  [[ $TO_INSTALL = [Yy] ]] && install
}

# 更换支持 Netflix WARP IP 改编自 [luoxue-bot] 的成熟作品，地址[https://github.com/luoxue-bot/warp_auto_change_ip]
change_ip() {
  need_install

  # 设置时区，让时间戳时间准确，显示脚本运行时长，中文为 GMT+8，英文为 UTC; 设置 UA
  ip_start=$(date +%s)
  echo "$SYSTEM" | grep -qE "Alpine" && ( [ "$L" = C ] && timedatectl set-timezone Asia/Shanghai || timedatectl set-timezone UTC )

  # 检测 WARP 单双栈服务
  unset T4 T6
  if grep -q "#AllowedIPs" /opt/warp-go/warp.conf; then
    T4=1; T6=1
  else
    grep -q "0\.\0\/0" 2>/dev/null /opt/warp-go/warp.conf && T4=1 || T4=0
    grep -q "\:\:\/0" 2>/dev/null /opt/warp-go/warp.conf && T6=1 || T6=0
  fi
  case "$T4$T6" in
    01 )
      NF='6'
      ;;
    10 )
      NF='4'
      ;;
    11 )
      hint "\n $(text 14) \n" && reading " $(text 4) " NETFLIX
      [ "$NETFLIX" = 1 ] && NF='4' || NF='6'
  esac

  # 更换 Netflix IP 时确认期望区域
  if [ -z "$EXPECT" ]; then
    [ -n "$NF" ] && REGION=$(curl --user-agent "${UA_Browser}" -$NF $GLOBAL -fs --max-time 10 http://www.cloudflare.com/cdn-cgi/trace | awk -F '=' '/^loc/{print $NF}')
    REGION=${REGION:-'US'}
    reading " $(text_eval 15) " EXPECT
    until [[ -z "$EXPECT" || "${EXPECT,,}" = 'y' || "${EXPECT,,}" =~ ^[a-z]{2}$ ]]; do
      reading " $(text_eval 15) " EXPECT
    done
    [[ -z "$EXPECT" || "${EXPECT,,}" = 'y' ]] && EXPECT="${REGION^^}"
  fi

  # 定义测试的两个 URL
  # 81280792 通常是全球自制剧 (Netflix Original)
  # 70143836 通常是非全球授权剧 (如 Breaking Bad)，用于检测是否全解锁
  local URL_ORIGINAL="https://www.netflix.com/title/81280792"
  local URL_REGIONAL="https://www.netflix.com/title/70143836"
  local UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
  local ARGS="--interface WARP -$NF"

  # 解锁检测程序。 i=尝试次数; b=当前账户注册次数; j=注册账户失败的最大次数; l=账户注册失败后等待重试时间;
  local i=0 j=10 l=8
  while true; do
    (( i++ )) || true
    ip_now=$(date +%s); RUNTIME=$((ip_now - ip_start)); DAY=$(( RUNTIME / 86400 )); HOUR=$(( (RUNTIME % 86400 ) / 3600 )); MIN=$(( (RUNTIME % 86400 % 3600) / 60 )); SEC=$(( RUNTIME % 86400 % 3600 % 60 ))
    ip${NF}_info
    WAN=$(eval echo \$WAN$NF) && ASNORG=$(eval echo \$ASNORG$NF)
    COUNTRY=$(eval echo \$COUNTRY$NF)
    unset RESULT REGION
    RESULT=$({
      curl $ARGS --user-agent "${UA_Browser}" --include -SsL --max-time 10 --tlsv1.3 "$URL_ORIGINAL";
      curl $ARGS --user-agent "${UA_Browser}" --include -SsL --max-time 10 --tlsv1.3 "$URL_REGIONAL";
    } 2>&1 | awk '
      # NR==1 表示处理第一行数据，设置 u 为 1 表示开始处理第一个 URL 的结果
      NR==1 { u=1 }

      # 如果检测到 HTTP/2 200 且 c 尚未设置，说明第一个测试页面连接成功
      /HTTP\/2 200/ && u && !c { c=1 }

      # 如果页面源码中包含 og:video 标签，说明可以播放该视频 (v=1 代表全解锁)
      /og:video/ { v=1 }

      # 匹配页面源码中的 "requestCountry" 字段，提取区域 ID (如 HK, US, TW)
      {
        if (u && !r && match($0, /"requestCountry":\{"supportedLocales":\[[^]]+\],"id":"[^"]+"/)) {
          s = substr($0, RSTART, RLENGTH);
          sub(/.*"id":"*/, "", s);
          sub(/".*/, "", s);
          r = s
        }
      }

      # 打印最终的 JSON 结果
      END {
        print "{";
        print "  \"connect\": " (c ? "true" : "false") ",";
        if (c) {
          print "  \"Netflix\": \"" (v ? "Yes" : "Originals Only") "\",";
          print "  \"region\": \"" r "\""
        };
        print "}"
      }
    ')

    local REGION=$(awk -F '"' '/region/{print $4}' <<< "${RESULT}")
    REGION=${REGION:-'US'}

    if grep -q '"Yes"' <<< "${RESULT}" && grep -qi "$EXPECT" <<< "$REGION"; then
      info " $(text_eval 16) "
      rm -f /opt/warp-go/warp.conf.tmp1
      i=0
      sleep 1h
    else
      warning " $(text_eval 13) "
      cp -f /opt/warp-go/warp.conf{,.tmp1}
      register_api warp.conf.tmp2
      sed -i '1,6!d' /opt/warp-go/warp.conf.tmp2
      tail -n +7 /opt/warp-go/warp.conf.tmp1 >> /opt/warp-go/warp.conf.tmp2
      mv /opt/warp-go/warp.conf.tmp2 /opt/warp-go/warp.conf
      warp_api "cancel" "/opt/warp-go/warp.conf.tmp1" >/dev/null 2>&1
      rm -f /opt/warp-go/warp.conf.tmp*
      ${SYSTEMCTL_RESTART[int]}
      sleep $l
    fi
  done
}

# 关闭 WARP 网络接口，并删除 warp-go
uninstall() {
  unset IP4 IP6 WAN4 WAN6 COUNTRY4 COUNTRY6 ASNORG4 ASNORG6 INTERFACE_4 INTERFACE_6

  # 如已安装 warp_unlock 项目，先行卸载
  [ -s /usr/bin/warp_unlock.sh ] && bash <(curl -sSL https://gitlab.com/fscarmen/warp_unlock/-/raw/main/unlock.sh) -U -$L

  # 卸载
  systemctl disable --now warp-go >/dev/null 2>&1
  kill -15 $(pgrep warp-go) >/dev/null 2>&1
  warp_api "cancel" "/opt/warp-go/warp.conf" >/dev/null 2>&1
  rm -rf /opt/warp-go /lib/systemd/system/warp-go.service /usr/bin/warp-go /tmp/warp-go*
  [ -s /opt/warp-go/tun.sh ] && rm -f /opt/warp-go/tun.sh && sed -i '/tun.sh/d' /etc/crontab

  # 显示卸载结果
  ip4_info is_uninstall
  ip6_info is_uninstall
  info " $(text 17)\n IPv4: $WAN4 $COUNTRY4 $ASNORG4\n IPv6: $WAN6 $COUNTRY6 $ASNORG6 "
}

# 同步脚本至最新版本
ver() {
  mkdir -p /tmp; rm -f /tmp/warp-go.sh
  wget -T2 -O /tmp/warp-go.sh https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh
  if [ -s /tmp/warp-go.sh ]; then
    mv /tmp/warp-go.sh /opt/warp-go/
    chmod +x /opt/warp-go/warp-go.sh
    ln -sf /opt/warp-go/warp-go.sh /usr/bin/warp-go
    info " $(text 18): $(grep ^VERSION /opt/warp-go/warp-go.sh | sed "s/.*=//g")  $(text 19): $(grep "${L}\[1\]" /opt/warp-go/warp-go.sh | cut -d \" -f2) "
  fi
  exit
}

# i=当前尝试次数，j=要尝试的次数
net() {
  unset IP4 IP6 WAN4 WAN6 COUNTRY4 COUNTRY6 ASNORG4 ASNORG6
  i=1; j=5
  grep -qE "^AllowedIPs[ ]+=.*0\.\0\/0|#AllowedIPs" 2>/dev/null /opt/warp-go/warp.conf && INTERFACE_4='--interface WARP'
  grep -qE "^AllowedIPs[ ]+=.*\:\:\/0|#AllowedIPs" 2>/dev/null /opt/warp-go/warp.conf && INTERFACE_6='--interface WARP'
  hint " $(text_eval 20)\n $(text_eval 59) "
  [ "$KEEP_FREE" != 1 ] && ${SYSTEMCTL_RESTART[int]}
  grep -q "#AllowedIPs" /opt/warp-go/warp.conf && sleep 8 || sleep 1
  ip4_info; ip6_info
  until [[ "$TRACE4$TRACE6" =~ on|plus ]]; do
    (( i++ )) || true
    hint " $(text_eval 59) "
    ${SYSTEMCTL_RESTART[int]}
    grep -q "#AllowedIPs" /opt/warp-go/warp.conf && sleep 8 || sleep 1
    ip4_info; ip6_info
      if [[ "$i" = "$j" ]]; then
        if [ -s /opt/warp-go/warp.conf.tmp1 ]; then
          i=0 && info " $(text 22) " &&
          mv -f /opt/warp-go/warp.conf.tmp1 /opt/warp-go/warp.conf
      else
          ${SYSTEMCTL_STOP[int]} >/dev/null 2>&1
          error " $(text_eval 23) "
        fi
      fi
  done

  ACCOUNT_TYPE=$(grep "Type" /opt/warp-go/warp.conf | cut -d= -f2 | sed "s# ##g")
  grep -q '#AllowedIPs' /opt/warp-go/warp.conf && GLOBAL_TYPE="$(text 24)"

  info " $(text_eval 25) "
  [ "$OPTION" = o ] && info " IPv4: $WAN4 $COUNTRY4 $ASNORG4\n IPv6: $WAN6 $COUNTRY6 $ASNORG6 "
}

# api 注册账户, 使用官方 api 脚本
register_api() {
  local REGISTER_FILE="$1"
  local i=0 j=5
  [ -n "$2" ] && hint " $(text_eval $2) "
  until [ -s /opt/warp-go/$REGISTER_FILE ]; do
    ((i++)) || true
    [ "$i" -gt "$j" ] && rm -f /opt/warp-go/warp.conf.tmp* && error " $(text_eval 50) "
    if ! grep -sq 'PrivateKey' /opt/warp-go/$REGISTER_FILE; then
      unset CF_API_REGISTER API_DEVICE_ID API_ACCESS_TOKEN API_PRIVATEKEY API_TYPE
      rm -f /opt/warp-go/$REGISTER_FILE
      CF_API_REGISTER="$(warp_api "register" 2>/dev/null)"

      if grep -q 'private_key' <<< "$CF_API_REGISTER"; then
        local API_DEVICE_ID=$(expr "$CF_API_REGISTER " | grep -m1 'id' | cut -d\" -f4)
        local API_ACCESS_TOKEN=$(expr "$CF_API_REGISTER " | grep '"token' | cut -d\" -f4)
        local API_PRIVATEKEY=$(expr "$CF_API_REGISTER " | grep 'private_key' | cut -d\" -f4)
        local API_TYPE=$(expr "$CF_API_REGISTER " | grep 'account_type' | cut -d\" -f4)

        cat > /opt/warp-go/$REGISTER_FILE << EOF
[Account]
Device = $API_DEVICE_ID
PrivateKey = $API_PRIVATEKEY
Token = $API_ACCESS_TOKEN
Type = $API_TYPE

[Device]
Name = WARP
MTU  = 1280

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
Endpoint = engage.cloudflareclient.com:2408
KeepAlive = 30
# AllowedIPs = 0.0.0.0/0
# AllowedIPs = ::/0

EOF
      fi
    fi

    if grep -sq 'Account' /opt/warp-go/$REGISTER_FILE; then
      echo -e "\n[Script]\nPostUp =\nPostDown =" >> /opt/warp-go/$REGISTER_FILE && sed -i 's/\r//' /opt/warp-go/$REGISTER_FILE
    else
      rm -f /opt/warp-go/$REGISTER_FILE
    fi
 done
}

# WARP 开关，先检查是否已安装，再根据当前状态转向相反状态
onoff() {
  case "$STATUS" in
    0 )
      need_install
      ;;
    1 )
      net
      ;;
    2 )
      ${SYSTEMCTL_STOP[int]}; info " $(text 27) "
  esac
}

# 检查系统 WARP 单双栈情况。为了速度，先检查 warp-go 配置文件里的情况，再判断 trace
check_stack() {
  if [ -s /opt/warp-go/warp.conf ]; then
    if grep -q "^#AllowedIPs" /opt/warp-go/warp.conf; then
      T4=2
    else
      grep -q ".*0\.\0\/0" 2>/dev/null /opt/warp-go/warp.conf && T4=1 || T4=0
      grep -q ".*\:\:\/0" 2>/dev/null /opt/warp-go/warp.conf && T6=1 || T6=0
    fi
  else
    case "$TRACE4" in
      off )
        T4='0'
        ;;
      'on'|'plus' )
        T4='1'
    esac
    case "$TRACE6" in
      off )
        T6='0'
        ;;
      'on'|'plus' )
        T6='1'
    esac
  fi
  CASE=("@0" "0@" "0@0" "@1" "0@1" "1@" "1@0" "1@1" "2@" "@")
  for m in ${!CASE[@]}; do
    [ "$T4@$T6" = "${CASE[m]}" ] && break
  done
  WARP_BEFORE=("" "" "" "WARP $(text 7) IPv6 only" "WARP $(text 7) IPv6" "WARP $(text 7) IPv4 only" "WARP $(text 7) IPv4" "WARP $(text 7) $(text 83)" "WARP $(text 60) $(text 83)")
  WARP_AFTER1=("" "" "" "WARP $(text 7) IPv4" "WARP $(text 7) IPv4" "WARP $(text 7) IPv6" "WARP $(text 7) IPv6" "WARP $(text 7) IPv4" "WARP $(text 7) IPv4")
  WARP_AFTER2=("" "" "" "WARP $(text 7) $(text 83)" "WARP $(text 7) $(text 83)" "WARP $(text 7) $(text 83)" "WARP $(text 7) $(text 83)" "WARP $(text 7) IPv6" "WARP $(text 7) $(text 83)")
  TO1=("" "" "" "014" "014" "106" "106" "114" "014")
  TO2=("" "" "" "01D" "01D" "10D" "10D" "116" "01D")
  SHORTCUT1=("" "" "" "(warp-go 4)" "(warp-go 4)" "(warp-go 6)" "(warp-go 6)" "(warp-go 4)" "(warp-go 4)")
  SHORTCUT2=("" "" "" "(warp-go d)" "(warp-go d)" "(warp-go d)" "(warp-go d)" "(warp-go 6)" "(warp-go d)")

  # 判断用于检测 NAT VSP，以选择正确配置文件
  if [ "$m" -le 3 ]; then
    NAT=("0@1@" "1@0@1" "1@1@1" "0@1@1")
    for n in ${!NAT[@]}; do [ "$IPV4@$IPV6@$INET4" = "${NAT[n]}" ] && break; done
    NATIVE=("IPv6 only" "IPv4 only" "$(text 48)" "NAT IPv4")
    CONF1=("014" "104" "114" "11N4")
    CONF2=("016" "106" "116" "11N6")
    CONF3=("01D" "10D" "11D" "11ND")
  elif [ "$m" = 9 ]; then
    error "\n $(text 26) \n"
  fi
}

# 检查全局状态
check_global() {
  [ -s /opt/warp-go/warp.conf ] && grep -q '#AllowedIPs' /opt/warp-go/warp.conf && NON_GLOBAL=1
}

# 单双栈在线互换。先看菜单是否有选择，再看传参数值，再没有显示2个可选项
stack_switch() {
  need_install
  check_global
  if [ "$NON_GLOBAL" = 1 ]; then
    if [[ "$CHOOSE" != [12] ]]; then
      warning " $(text 28) " && reading " $(text 29) " TO_GLOBAL
      [[ "$TO_GLOBAL" != [Yy] ]] && exit 0 || global_switch
    else
      global_switch
    fi
  fi

  # WARP 单双栈切换选项
  SWITCH014="s#AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g"
  SWITCH01D="s#AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g"
  SWITCH106="s#AllowedIPs.*#AllowedIPs = ::/0#g"
  SWITCH10D="s#AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g"
  SWITCH114="s#AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g"
  SWITCH116="s#AllowedIPs.*#AllowedIPs = ::/0#g"

  check_stack

  if [[ "$CHOOSE" = [12] ]]; then
    TO=$(eval echo \${TO$CHOOSE[m]})
  elif [[ "$SWITCHCHOOSE" = [46D] ]]; then
    if [[ "$TO_GLOBAL" = [Yy] ]]; then
      if [[ "$T4@$T6@$SWITCHCHOOSE" =~ '1@0@4'|'0@1@6'|'1@1@D' ]]; then
        grep -q "^AllowedIPs.*0\.\0\/0" 2>/dev/null /opt/warp-go/warp.conf || unset INTERFACE_4 INTERFACE_6
        OPTION=o && net
        exit 0
      else
        TO="$T4$T6$SWITCHCHOOSE"
      fi
    else
      [[ "$T4@$T6@$SWITCHCHOOSE" =~ '1@0@4'|'0@1@6'|'1@1@D' ]] && error " $(text 30) " || TO="$T4$T6$SWITCHCHOOSE"
    fi
  else
    STACK_OPTION[1]="$(text_eval 31)"; STACK_OPTION[2]="$(text_eval 32)"
    hint "\n $(text_eval 33) \n" && reading " $(text 4) " SWITCHTO
    case "$SWITCHTO" in
      1 )
        TO=${TO1[m]}
        ;;
      2 )
        TO=${TO2[m]}
        ;;
      0 )
        exit
        ;;
      * )
        warning " $(text 34) [0-2] "; sleep 1; stack_switch
    esac
  fi

  [ "${#TO}" != 3 ] && error " $(text 10) " || sed -i "$(eval echo "\$SWITCH$TO")" /opt/warp-go/warp.conf
  case "$TO" in
    014|114 )
      INTERFACE_4='--interface WARP'; unset INTERFACE_6
      ;;
    106|116 )
      INTERFACE_6='--interface WARP'; unset INTERFACE_4
      ;;
    01D|10D )
      INTERFACE_4='--interface WARP'; INTERFACE_6='--interface WARP'
  esac

  OPTION=o && net
}

# 全局 / 非全局在线互换
global_switch() {
  # 如状态不是安装中，则检测是否已安装 warp-go，如已安装，则停止 systemd
  if [ "$STATUS" != 3 ]; then
    need_install
    ${SYSTEMCTL_STOP[int]}
  fi

  if grep -q "^Allowed" /opt/warp-go/warp.conf; then
    sed -i "s/^#//g; s/^AllowedIPs.*/#&/g" /opt/warp-go/warp.conf
    sleep 2
  else
    sed -i "s/^#//g; s/.*NonGlobal/#&/g" /opt/warp-go/warp.conf
    unset GLOBAL_TYPE
  fi

  # 如状态不是安装中，不是非全局转换到全局时的快捷或菜单选择情况。则开始 systemd,
  if [[ "$STATUS" != 3 && "$TO_GLOBAL" != [Yy] && "$CHOOSE" != [12] ]]; then
    ${SYSTEMCTL_START[int]}
    OPTION=o && net
  fi
}

# 检测系统信息
check_system_info() {
  info " $(text 35) "

  # 由于 warp-go 内置了 wireguard-go ，而 wireguard-go 运行时会先判断 tun 设备，如果文件不存在，则马上退出
  [ ! -e /dev/net/tun ] && error " $(text 36) "

  # 必须加载 TUN 模块，先尝试在线打开 TUN。尝试成功放到启动项，失败作提示并退出脚本
  TUN=$(cat /dev/net/tun 2>&1 | tr 'A-Z' 'a-z')
  if [[ ! "$TUN" =~ 'in bad state'|'处于错误状态' ]]; then
    mkdir -p /opt/warp-go/ >/dev/null 2>&1
    cat >/opt/warp-go/tun.sh << EOF
#!/usr/bin/env bash
mkdir -p /dev/net
mknod /dev/net/tun c 10 200 2>/dev/null
[ ! -e /dev/net/tun ] && exit 1
chmod 0666 /dev/net/tun
EOF
    bash /opt/warp-go/tun.sh
    TUN=$(cat /dev/net/tun 2>&1 | tr 'A-Z' 'a-z')
    if [[ ! "$TUN" =~ 'in bad state'|'处于错误状态' ]]; then
      rm -f /opt/warp-go/tun.sh && error " $(text 36) "
    else
      chmod +x /opt/warp-go/tun.sh
      echo "$SYSTEM" | grep -qvE "Alpine|OpenWrt" && echo "@reboot root bash /opt/warp-go/tun.sh" >> /etc/crontab
    fi
  fi

  if [ "$STATUS" != 0 ]; then
    if grep -qE "^AllowedIPs.*\.0/0,::/0|^#AllowedIPs" 2>/dev/null /opt/warp-go/warp.conf; then
      INTERFACE_4='--interface WARP'; INTERFACE_6='--interface WARP'; local IP_INTERFACE_4='dev WARP'; local IP_INTERFACE_6='dev WARP'; local PING_INTERFACE_4='-I WARP'; local PING_INTERFACE_6='-I WARP'
    elif grep -q '^AllowedIPs.*\.0/0$' 2>/dev/null /opt/warp-go/warp.conf; then
      INTERFACE_4='--interface WARP'; unset INTERFACE_6; local IP_INTERFACE_4='dev WARP'; unset IP_INTERFACE_6; local PING_INTERFACE_4='-I WARP'; unset PING_INTERFACE_6
    elif grep -q '^AllowedIPs.*::/0$' 2>/dev/null /opt/warp-go/warp.conf; then
      INTERFACE_6='--interface WARP'; unset INTERFACE_4; unset IP_INTERFACE_4; local IP_INTERFACE_6='dev WARP'; unset PING_INTERFACE_4; local PING_INTERFACE_6='-I WARP'
    fi
  fi

  # 判断机器原生状态类型
  IPV4=0; IPV6=0
  LAN4=$(ip route get 192.168.193.10 $IP_INTERFACE_4 2>/dev/null | awk '{for (i=0; i<NF; i++) if ($i=="src") {print $(i+1)}}')
  LAN6=$(ip route get 2606:4700:d0::a29f:c001 $IP_INTERFACE_6 2>/dev/null | awk '{for (i=0; i<NF; i++) if ($i=="src") {print $(i+1)}}')
  [[ "$LAN4" =~ ^([0-9]{1,3}\.){3} ]] && local INET4=1
  [[ "$LAN6" != "::1" && "$LAN6" =~ ^[a-f0-9:]+$ ]] && local INET6=1
  [ "$INET6" = 1 ] && $PING6 -c2 -w10 2606:4700:d0::a29f:c001 $PING_INTERFACE_4 >/dev/null 2>&1 && IPV6=1 && STACK=-6
  [ "$INET4" = 1 ] && ping -c2 -W3 162.159.192.1 $PING_INTERFACE_6 >/dev/null 2>&1 && IPV4=1 && STACK=-4

  [ "$IPV4" = 1 ] && ip4_info
  [ "$IPV6" = 1 ] && ip6_info
}

# 输出 wireguard 和 sing-box 配置文件
export_file() {
  if [ -s /opt/warp-go/warp-go ]; then
    [ ! -s /opt/warp-go/warp.conf ] && register_api warp.conf
    /opt/warp-go/warp-go --config=/opt/warp-go/warp.conf --export-wireguard=/opt/warp-go/wgcf.conf >/dev/null 2>&1
    /opt/warp-go/warp-go --config=/opt/warp-go/warp.conf --export-singbox=/opt/warp-go/singbox.json >/dev/null 2>&1
  else
    error " $(text 51) "
  fi

  info "\n $(text 52) "
  cat /opt/warp-go/wgcf.conf
  echo -e "\n\n"

  # 检查 JSON 格式化工具
  if [ -x "$(type -p python3)" ]; then
    local JSON_TOOL="| python3 -m json.tool"
  elif [ -x "$(type -p python)" ]; then
    local JSON_TOOL="| python -m json.tool"
  elif [ -x "$(type -p json_pp)" ]; then
    local JSON_TOOL="| json_pp"
  elif [ -x "$(type -p jq)" ]; then
    local JSON_TOOL="| jq"
  fi

  info " $(text 54) "
  eval "cat /opt/warp-go/singbox.json $JSON_TOOL"
  echo -e "\n\n"
}

# warp-go 安装
install() {
  # 已经状态码不为 0， 即已安装， 脚本退出
  [ "$STATUS" != 0 ] && error " $(text 53) "

  # CONF 参数如果不是3位或4位， 即检测不出正确的配置参数， 脚本退出
  [[ "${#CONF}" != [34] ]] && error " $(text 10) "

  # 先删除之前安装，可能导致失败的文件
  rm -rf /opt/warp-go/warp-go /opt/warp-go/warp.conf

  # 后台优选最佳 MTU
  {
    # 反复测试最佳 MTU。 Wireguard Header:IPv4=60 bytes,IPv6=80 bytes，1280 ≤ MTU ≤ 1420。 ping = 8(ICMP回显示请求和回显应答报文格式长度) + 20(IP首部) 。
    # 详细说明:<[WireGuard] Header / MTU sizes for Wireguard>:https://lists.zx2c4.com/pipermail/wireguard/2017-December/002201.html
    # MTU 初始范围（适用于 WireGuard 等封装，IPv4/IPv6 都保守选 1280-1420）
    local MIN_MTU=1280
    local MAX_MTU=1500
    local TEST_IP
    local PING_CMD
    local BEST_MTU=1280

    if [ "$IPV4$IPV6" = "01" ]; then
      TEST_IP="2606:4700:d0::a29f:c001"
      PING_CMD="$PING6"
    else
      TEST_IP="162.159.192.1"
      PING_CMD="ping"
    fi

    # 二分查找能 ping 通的最大 MTU（不碎片）
    while [ $((MIN_MTU <= MAX_MTU)) -eq 1 ]; do
      local MID_MTU=$(( (MIN_MTU + MAX_MTU) / 2 ))
      if $PING_CMD -c1 -W1 -s $MID_MTU -M do "$TEST_IP" >/dev/null 2>&1; then
        BEST_MTU=$MID_MTU
        MIN_MTU=$((MID_MTU + 1))  # 尝试更大值
      else
        MAX_MTU=$((MID_MTU - 1))  # 减小范围
      fi
    done

    # 最终微调确认 BEST_MTU 是最大可用值
    for (( i=BEST_MTU+1; i<=1420; i++ )); do
      if $PING_CMD -c1 -W1 -s $i -M do "$TEST_IP" >/dev/null 2>&1; then
        BEST_MTU=$i
      else
        break
      fi
    done

    # 返回最终 MTU（按需减包头）——可自定义减多少
    # WireGuard：+28 是 IP+UDP，-60 / -80 是安全包头（例如 wireguard + extra overhead）
    grep -q ':' <<< "$TEST_IP" && BEST_MTU=$((BEST_MTU + 28 - 80)) || BEST_MTU=$((BEST_MTU + 28 - 60))

    # 确保范围安全
    [ "$BEST_MTU" -lt 1280 ] && BEST_MTU=1280
    [ "$BEST_MTU" -lt 1280 ] && BEST_MTU=1280
    [ "$BEST_MTU" -gt 1420 ] && BEST_MTU=1420

    echo "$BEST_MTU" > /tmp/warp-go-mtu
  }&

  # 后台优选优选 WARP Endpoint
  {
    # Removed best endpoint feature to adapt to official adjustments
    # Use default endpoint: engage.cloudflareclient.com:2408
    echo "engage.cloudflareclient.com:2408" > /tmp/warp-go-endpoint
  }&

  # 选择优先使用 IPv4 /IPv6 网络
  [ -z "$PRIORITY" ] && hint "\n $(text 55) \n" && reading " $(text 4) " PRIORITY

  # 脚本开始时间
  start=$(date +%s)

  # 注册 Teams 账户 (将生成 warp 文件保存账户信息)
  {
    mkdir -p /opt/warp-go/ >/dev/null 2>&1
    wait
    [ ! -s /tmp/warp-go ] && error " $(text 56) " || mv -f /tmp/warp-go /opt/warp-go/
    [ ! -s /opt/warp-go/warp-go ] && error " $(text 57) "

    register_api warp.conf 58

    # 生成非全局执行文件并赋权
    cat > /opt/warp-go/NonGlobalUp.sh << EOF
sleep 5
ip -4 rule add oif WARP lookup 60000
ip -4 rule add table main suppress_prefixlength 0
ip -4 route add default dev WARP table 60000
ip -6 rule add oif WARP lookup 60000
ip -6 rule add table main suppress_prefixlength 0
ip -6 route add default dev WARP table 60000
EOF

cat > /opt/warp-go/NonGlobalDown.sh << EOF
ip -4 rule delete oif WARP lookup 60000
ip -4 rule delete table main suppress_prefixlength 0
ip -6 rule delete oif WARP lookup 60000
ip -6 rule delete table main suppress_prefixlength 0
EOF

    chmod +x /opt/warp-go/NonGlobalUp.sh /opt/warp-go/NonGlobalDown.sh

    info "\n $(text 61) \n"
  }

  # 对于 IPv4 only VPS 开启 IPv6 支持
  {
    [ "$IPV4$IPV6" = 10 ] && [[ $(sysctl -a 2>/dev/null | grep 'disable_ipv6.*=.*1') || $(grep -s "disable_ipv6.*=.*1" /etc/sysctl.{conf,d/*} ) ]] &&
    (sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
    echo 'net.ipv6.conf.all.disable_ipv6 = 0' >/etc/sysctl.d/ipv6.conf
    sysctl -w net.ipv6.conf.all.disable_ipv6=0)
  }&

  # 优先使用 IPv4 /IPv6 网络
  { stack_priority; }&

  wait
  info "\n $(text 9) \n"

  # 如有所有 endpoint 都不能连通的情况，脚本中止
  [ ! -s /tmp/warp-go-endpoint ] && error " $(text 114) "

  # warp-go 配置修改，其中用到的 162.159.192.1 和 2606:4700:d0::a29f:c001 均是 engage.cloudflareclient.com 的 IP; 172.17.0.0/24 这段是用于 Docker 的
  MTU=$(cat /tmp/warp-go-mtu) && rm -f /tmp/warp-go-mtu
  MODIFY014="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g; s#.*PostUp.*#PostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#[2606:4700:d0::a29f:c001]#"
  MODIFY016="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = ::/0#g; s#.*PostUp.*#PostUp   = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#[2606:4700:d0::a29f:c001]#"
  MODIFY01D="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g; s#.*PostUp.*#PostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#[2606:4700:d0::a29f:c001]#"
  MODIFY104="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#162.159.192.1#"
  MODIFY106="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = ::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#162.159.192.1#"
  MODIFY10D="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g; s#engage.cloudflareclient.com#162.159.192.1#"
  MODIFY114="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"
  MODIFY116="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = ::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"
  MODIFY11D="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"
  MODIFY11N4="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"
  MODIFY11N6="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = ::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"
  MODIFY11ND="/Endpoint6/d; /PreUp/d; /::\/0/d; s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g; s#.*PostUp.*#PostUp = ip -4 rule add from $LAN4 lookup main\nPostUp = ip -6 rule add from $LAN6 lookup main#g; s#.*PostDown.*#PostDown = ip -4 rule delete from $LAN4 lookup main\nPostDown = ip -6 rule delete from $LAN6 lookup main\nPostUp = ip -4 rule add from 172.17.0.0\/24 lookup main\nPostDown = ip -4 rule delete from 172.17.0.0\/24 lookup main\n\#PostUp = /opt/warp-go/NonGlobalUp.sh\n\#PostDown = /opt/warp-go/NonGlobalDown.sh#g; s#\(MTU.*\)1280#\1$MTU#g"

  sed -i "$(eval echo "\$MODIFY$CONF")" /opt/warp-go/warp.conf

  # 如为 WARP IPv4 非全局，修改配置文件，在路由表插入规则
  [ "$OPTION" = n ] && STATUS=3 && global_switch

  # 创建 warp-go systemd 进程守护(Alpine 系统除外)
  if echo "$SYSTEM" | grep -qvE "Alpine|OpenWrt"; then
    cat > /lib/systemd/system/warp-go.service << EOF
[Unit]
Description=warp-go service
After=network.target
Documentation=https://github.com/fscarmen/warp-sh
Documentation=https://gitlab.com/ProjectWARP/warp-go

[Service]
RestartSec=2s
WorkingDirectory=/opt/warp-go/
ExecStart=/opt/warp-go/warp-go --config=/opt/warp-go/warp.conf
Environment="LOG_LEVEL=verbose"
RemainAfterExit=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  fi

  # 运行 warp-go
  net

  # 设置开机启动
  ${SYSTEMCTL_ENABLE[int]} >/dev/null 2>&1

  # 创建软链接快捷方式，再次运行可以用 warp-go 指令，设置默认语言
  mv $0 /opt/warp-go/warp-go.sh
  chmod +x /opt/warp-go/warp-go.sh
  ln -sf /opt/warp-go/warp-go.sh /usr/bin/warp-go
  echo "$L" > /opt/warp-go/language

  # 结果提示，脚本运行时间，次数统计，IPv4 / IPv6 优先级别
  [ "$(curl -ksm8 http://ip.cloudflare.nyc.mn | awk -F '"' '/"ip"/{print $4}')" = "$WAN6" ] && PRIO=6 || PRIO=4
  end=$(date +%s)
  ACCOUNT_TYPE=$(grep "Type" /opt/warp-go/warp.conf | cut -d= -f2 | sed "s# ##g")
  result_priority

  # 获取运行次数
  statistics_of_run-times get

  echo -e "\n==============================================================\n"
  info " IPv4: $WAN4 $COUNTRY4  $ASNORG4 "
  info " IPv6: $WAN6 $COUNTRY6  $ASNORG6 "
  info " $(text_eval 62) "
  info " $PRIORITY_NOW "
  echo -e "\n==============================================================\n"
  hint " $(text 49)\n " && help
  [ "$TRACE4$TRACE6" = offoff ] && warning " $(text 63) "
  exit
}

# 判断当前 WARP 网络接口及 Client 的运行状态，并对应的给菜单和动作赋值
menu_setting() {
  if [ "$STATUS" = 0 ]; then
    MENU_OPTION[1]="$(text_eval 64)"
    MENU_OPTION[2]="$(text_eval 65)"
    MENU_OPTION[3]="$(text_eval 66)"
    MENU_OPTION[4]="$(text_eval 67)"
    MENU_OPTION[5]="$(text_eval 68)"
    MENU_OPTION[6]="$(text_eval 69)"
    MENU_OPTION[7]="$(text_eval 70)"
    MENU_OPTION[8]="$(text_eval 71)"
    ACTION[1]() { CONF=${CONF1[n]}; PRIORITY=1; install; }
    ACTION[2]() { CONF=${CONF1[n]}; PRIORITY=2; install; }
    ACTION[3]() { CONF=${CONF2[n]}; PRIORITY=1; install; }
    ACTION[4]() { CONF=${CONF2[n]}; PRIORITY=2; install; }
    ACTION[5]() { CONF=${CONF3[n]}; PRIORITY=1; install; }
    ACTION[6]() { CONF=${CONF3[n]}; PRIORITY=2; install; }
    ACTION[7]() { CONF=${CONF3[n]}; PRIORITY=1; OPTION=n; install; }
    ACTION[8]() { CONF=${CONF3[n]}; PRIORITY=2; OPTION=n; install; }
  else
    [ "$NON_GLOBAL" = 1 ] || GLOBAL_AFTER="$(text 24)"
    [ "$STATUS" = 2 ] && ON_OFF="$(text 72)" || ON_OFF="$(text 73)"
    MENU_OPTION[1]="$(text_eval 74)"
    MENU_OPTION[2]="$(text_eval 75)"
    MENU_OPTION[3]="$(text_eval 76)"
    MENU_OPTION[4]="$ON_OFF"
    MENU_OPTION[5]="$(text 78)"
    MENU_OPTION[6]="$(text 79)"
    MENU_OPTION[7]="$(text 80)"

    ACTION[1]() { stack_switch; }
    ACTION[2]() { stack_switch; }
    ACTION[3]() { global_switch; }
    ACTION[4]() { OPTION=o; onoff; }
    ACTION[5]() { change_ip; }
    ACTION[6]() { export_file; }
    ACTION[7]() { uninstall; }
  fi

  MENU_OPTION[0]="$(text 81)"
  MENU_OPTION[8]="$(text 82)"
  ACTION[0]() { rm -f /tmp/warp-go*; exit; }
  ACTION[8]() { ver; }

  [ -s /opt/warp-go/warp.conf ] && TYPE=$(grep "Type" /opt/warp-go/warp.conf | cut -d= -f2 | sed "s# ##g")
}

# 显示菜单
menu() {
	clear
	hint " $(text 3) "
	echo -e "======================================================================================================================\n"
	info " $(text 38): $VERSION\n $(text 39): $(text 1)\n $(text 40):\n\t $(text 41): $SYS\n\t $(text 42): $(uname -r)\n\t $(text 43): $ARCHITECTURE\n\t $(text 44): $VIRT "
	info "\t IPv4: $WAN4 $COUNTRY4  $ASNORG4 "
	info "\t IPv6: $WAN6 $COUNTRY6  $ASNORG6 "
  if [ "$STATUS" = 2 ]; then
    info "\t $(text_eval 45) "
    grep -q '#AllowedIPs' /opt/warp-go/warp.conf && GLOBAL_TYPE="$(text 24)"
    info "\t $(text_eval 46) "
  else
    info "\t $(text 47) "
  fi
  [ -n "$PLUSINFO" ] && info "\t $PLUSINFO "
 	echo -e "\n======================================================================================================================\n"
	for ((d=1; d<=${#MENU_OPTION[*]}; d++)); do [ "$d" = "${#MENU_OPTION[*]}" ] && d=0 && hint " $d. ${MENU_OPTION[d]} " && break || hint " $d. ${MENU_OPTION[d]} "; done
  reading "\n $(text 4) " CHOOSE

  # 输入必须是数字且少于等于最大可选项
  if [[ "$CHOOSE" =~ ^[0-9]+$ ]] && (( $CHOOSE >= 0 && $CHOOSE < ${#MENU_OPTION[*]} )); then
    ACTION[$CHOOSE]
  else
    warning " $(text 34) [0-$((${#MENU_OPTION[*]}-1))] " && sleep 1 && menu
  fi
}

# 传参选项 OPTION：1=为 IPv4 或者 IPv6 补全另一栈WARP; 2=安装双栈 WARP; u=卸载 WARP
[ "$1" != '[option]' ] && OPTION=$(tr 'A-Z' 'a-z' <<< "$1")

# 不同选项的逻辑
case "$OPTION" in
  s )
    [[ "${2,,}" = [46d] ]] && PRIORITY_SWITCH=PRIORITY_SWITCH="${2,,}"
    ;;
  i )
    [[ "${2,,}" =~ ^[a-z]{2}$ ]] && EXPECT="${2,,}"
esac

# 自定义 WARP+ 设备名
NAME="$3"

# 主程序运行 1/3
check_cdn
statistics_of_run-times update warp-go.sh 2>/dev/null
select_language
check_operating_system
check_arch
[[ "$OPTION" != "u" ]] && check_dependencies
check_install

# 设置部分后缀 1/3
case "$OPTION" in
  h )
    help; exit 0
    ;;
  i )
    change_ip; exit 0
    ;;
  e )
    export_file; exit 0
    ;;
  s )
    stack_priority; result_priority; exit 0
esac

# 主程序运行 2/3
check_root_virt $SYSTEM

# 设置部分后缀 2/3
case "$OPTION" in
  u )
    uninstall; exit 0
    ;;
  v )
    ver; exit 0
    ;;
  o )
    onoff; exit 0
    ;;
  g )
    global_switch; exit 0
esac

# 主程序运行 3/3
check_system_info
check_global
check_stack
menu_setting

# 设置部分后缀 3/3
case "$OPTION" in
  [46dn] )
    if [[ $STATUS != 0 ]]; then
      SWITCHCHOOSE="$(tr 'a-z' 'A-Z' <<< "$OPTION")"
      stack_switch
    else
      case "$OPTION" in
        4 ) CONF=${CONF1[n]} ;;
        6 ) CONF=${CONF2[n]} ;;
        d|n ) CONF=${CONF3[n]} ;;
      esac
      install
    fi
    ;;
  * ) menu
esac