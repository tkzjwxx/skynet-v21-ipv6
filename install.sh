#!/bin/bash
# ====================================================================
# 天网系统 V10.5 | HAX 专属“暴力注入”版 (解决 DNS 解析与 WARP 菜单)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网 V10.5】全量重筑 (HAX 特供注入版)...\033[0m"

# 1. 第一步：暴力修复 HAX 的 DNS 解析 (解决 Could not resolve 问题)
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf 2>/dev/null # 锁定 DNS 防止被系统改回去

# 2. 环境清理
systemctl stop psiphon1 psiphon2 psiphon3 psiphon4 sing-box w_master warp-go 2>/dev/null
rm -rf /etc/s-box /usr/bin/s[1-3] /usr/bin/l[1-3] /usr/bin/sl[1-3] /usr/bin/c /usr/bin/ss

# 3. 基础依赖
apt-get update -y && apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3

# 4. 核心下载 (利用镜像站，防止 HAX 连 GitHub 慢)
echo -e "\033[1;33m📦 正在打捞核心组件 (多源加速模式)...\033[0m"
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

# 下载 Sing-box (使用 FastGit 镜像)
S_VER="1.11.0"
S_URL="https://gh-proxy.com/https://github.com/SagerNet/sing-box/releases/download/v${S_VER}/sing-box-${S_VER}-linux-amd64.tar.gz"
wget -q --show-progress -O /tmp/sbox.tar.gz "$S_URL"
tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box && chmod +x /etc/s-box/sing-box

# 5. 【重头戏】解决 WARP 菜单问题 (强制按键注入)
echo -e "\033[1;32m🌐 正在对 WARP 菜单进行“暴力注入”安装...\033[0m"
wget -qN https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh

# 针对图 2 的菜单，直接用 printf 将动作流推入
# 动作序列：2(双栈) -> 回车 -> y(确定) -> 回车
(printf "2\n"; sleep 2; printf "y\n"; sleep 2; printf "y\n") | bash warp-go.sh chinese

# 6. 配置核心路由 (Sing-box)
cat << 'CONFIG_EOF' > /etc/s-box/sing-box.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-1", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "vmess", "tag": "vm-1", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s1"} },
    { "type": "vmess", "tag": "vm-2", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s2"} },
    { "type": "vmess", "tag": "vm-3", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s3"} }
  ],
  "outbounds": [
    { "type": "socks", "tag": "out-1", "server": "127.0.0.1", "server_port": 1081 },
    { "type": "socks", "tag": "out-2", "server": "127.0.0.1", "server_port": 1082 },
    { "type": "socks", "tag": "out-3", "server": "127.0.0.1", "server_port": 1083 }
  ],
  "route": {"rules": [ {"inbound": ["hy2-1", "vm-1"], "outbound": "out-1"}, {"inbound": ["vm-2"], "outbound": "out-2"}, {"inbound": ["vm-3"], "outbound": "out-3"} ]}
}
CONFIG_EOF
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
cat > /etc/systemd/system/sing-box.service << 'SVC_EOF'
[Unit]
Description=Sing-box
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

# 7. 写入唯一指挥官 c (静态史记/动态实时)
cat << 'EOF' > /usr/bin/c
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
T=$(date '+%m-%d')
draw() {
    clear; echo -e "\033[1;36m=======================================================================================================================\033[0m"
    echo -e "\033[1;37m                                   🛡️ 天网系统 V10.5 (唯一指挥官·HAX 特供) 🛡️\033[0m"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
    printf "%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\n" "通道" "国家" "锁定 IP (目标)" "当前真实 IP" "对外气闸" "持续存活时长" "健康状态及行动指示"
    echo "-----------------------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        [ "$N" == "1" ] && { I=2081; O=1081; W="/etc/s-box"; R="S1"; }
        [ "$N" == "2" ] && { I=2082; O=1082; W="/etc/s-box/sub2"; R="S2"; }
        [ "$N" == "3" ] && { I=2083; O=1083; W="/etc/s-box/sub3"; R="S3"; }
        RE=$(grep -oP '"EgressRegion": "\K[A-Z]+' $W/base.config 2>/dev/null || echo "US")
        TA=$(cat "$W/s$N.lock" 2>/dev/null); CU=$(curl -s -m 4 --socks5 127.0.0.1:$I api.ipify.org 2>/dev/null)
        UP="--:--:--"; if [ -f "$W/s$N.uptime" ] && [ -n "$TA" ]; then ST=$(cat "$W/s$N.uptime"); DF=$(($(date +%s) - ST)); [ $DF -gt 0 ] && UP=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        G=$(netstat -tlnp 2>/dev/null | grep -q ":$O " && echo "🟢开启" || echo "🔴熔断")
        if [ -f "$W/s$N.manual" ]; then C="\033[1;35m"; S="🛑 手动介入"; elif [ -z "$CU" ]; then C="\033[1;33m"; S="🟡 探测假死"; elif [ "$CU" == "$TA" ]; then C="\033[1;32m"; S="✅ 稳定锁定"; else C="\033[1;31m"; S="🚨 漂移判定"; fi
        printf "${C}%-6s | %-6s | %-16s | %-16s | %-10s | %-14s | %s\033[0m\n" "$R" "$RE" "$TA" "${CU:-空}" "$G" "$UP" "$S"
    done
}
if [[ "$1" == "--live" || "$1" == "ss" ]]; then
    while true; do draw; grep "^\[$T" $SLA_LOG | grep -vE "介入|退出" | tail -n 20; sleep 2; done
else
    draw; LOG=$(grep "^\[$T" $SLA_LOG | grep -vE "TRACE|介入|退出"); echo "${LOG:-等待凌晨4点重启后的首笔史记...}"
    echo -e "\033[1;36m=======================================================================================================================\033[0m"
fi
EOF
chmod +x /usr/bin/c; ln -sf /usr/bin/c /usr/bin/ss

# 8. 凌晨 4 点重启逻辑
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重启，开启新史记 ===\" >> /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V10.5 HAX 版部署完毕！\033[0m"
