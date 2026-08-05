menu() {
    while true; do
        clear

        red "=========================================="
        green "              CC Tool 一键脚本"
        red "=========================================="

        cat <<EOF
 1. Root/SSH 登录设置          2. 开启端口/关闭防火墙
 3. Oracle DD 系统             4. 安装 Hysteria2
 5. 安装 Alist                 6. 安装 x-ui
 7. 自动申请证书               8. VPS 性能测试
 9. 青龙面板                  10. TCP 调优

 a. 3X-UI                     b. Tailscale
 c. Aria2                     d. cd2
 e. Rclone                    f. CasaOS
 g. Toolbox                   h. X-UI
 i. PVE-Debian                j. Kejilion
 k. WARP 加速                 l. LXC 容器
 m. MiliVPN                   n. 1Panel
 x. 一键换源                  z. Docker

 0. 极光面板                 dd. 更新脚本
 q. 退出脚本
EOF

        echo
        read -rp "请输入选项: " NumberInput

        case "$NumberInput" in
            1)
                root_user
                ;;
            2)
                open_ports
                ;;
            3)
                bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh) -d 11 -v 64 -p 123456789
                ;;
            4)
                wget -N --no-check-certificate https://gh.130401.xyz/https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh
                bash hysteria.sh
                ;;
            5)
                curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh
                sudo bash install-openlist-v4.sh
                ;;
            6)
                bash <(curl -Ls https://gh.130401.xyz/https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
                ;;
            7)
                apt update -y
                apt upgrade -y
                apt install git -y
                bash <(curl -fsSL https://raw.githubusercontent.com/slobys/SSL-Renewal/main/acme.sh)
                ;;
            8)
                bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh)
                ;;
            9)
                wget -q https://gh.130401.xyz/https://raw.githubusercontent.com/yanyuwangluo/VIP/main/Scripts/sh/ql.sh -O ql.sh
                bash ql.sh
                ;;
            10)
                tcp_up
                ;;
            a)
                bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
                ;;
            b)
                curl -fsSL https://tailscale.com/install.sh | sh
                ;;
            c)
                wget -N git.io/aria2.sh
                chmod +x aria2.sh
                bash aria2.sh
                ;;
            d)
                bash <(curl -sSLf https://ailg.ggbond.org/cd2.sh)
                ;;
            e)
                curl https://rclone.org/install.sh | sudo bash
                ;;
            f)
                wget -qO- https://get.casaos.io | sudo bash
                ;;
            g)
                rm -rf toolbox
                git clone https://gh.130401.xyz/https://github.com/f1161291/toolbox
                cd toolbox || exit
                chmod +x tool.sh
                bash tool.sh
                ;;
            h)
                bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
                ;;
            i)
                bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/vm/debian-vm.sh)"
                ;;
            j)
                bash <(curl -sL kejilion.sh)
                ;;
            k)
                wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
                bash menu.sh
                ;;
            l)
                bash -c "$(curl -sSL https://www.linkease.com/rd/fastpve/)"
                ;;
            m)
                bash <(curl -Ls https://raw.githubusercontent.com/baoweise-bot/aimili-vpngate/main/install.sh)
                ;;
            n)
                bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
                ;;
            x)
                bash <(curl -sSL https://linuxmirrors.cn/main.sh)
                ;;
            z)
                curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
                ;;
            0)
                bash <(curl -fsSL https://gh.130401.xyz/https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)
                ;;
            dd)
                wget -N --no-check-certificate https://gh.130401.xyz/https://raw.githubusercontent.com/f1161291/toolbox/main/tool.sh
                chmod +x tool.sh
                bash tool.sh
                ;;
            q | Q)
                green "感谢使用 CC Tool，再见！"
                exit 0
                ;;
            *)
                red "输入有误，请重新选择！"
                sleep 1
                ;;
        esac
    done
}
