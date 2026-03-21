#!/bin/bash
# ====================================================================
# 天网系统 V22 终极大一统版 (单入口 tw + 物理启停 + 双轨 SLA)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网 V22 大一统版】全量创世重筑...\033[0m"

# 0. 强力拔除 HAX 废弃源
sed -i '/virtuozzo/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null

# 1. 深度环境清理 (清除所有旧版垃圾指令)
systemctl stop psiphon1 psiphon2 psiphon3 psiphon4 sing-box w_master warp-go wg-quick@wgcf 2>/dev/null
killall -9 w_master 2>/dev/null
rm -rf /etc/s-box /usr/bin/c /usr/bin/ss /usr/bin/u /usr/bin/v /usr/bin/s[1-4] /usr/bin/l[1-4] /usr/bin/sl[1-4] /usr/bin/c[1-4] /usr/bin/tw
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget socat net-tools psmisc jq unzip tar openssl cron nano >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# ====================================================================
# 2. 网络干预：仅针对 wget 开启 IPv6
# ====================================================================
echo "prefer-family = IPv6" > ~/.wgetrc
sed -i '/precedence ::ffff:0:0\/96  10/d' /etc/gai.conf 2>/dev/null
echo -e "\033[1;32m✅ 已配置 wget 的 IPv6 防卡死补丁\033[0m"

# ====================================================================
# 3. WARP 部署
# ====================================================================
echo -e "\033[1;32m🌐 第一阶段：正在拉取勇哥 WARP 引擎...\033[0m"
rm -f /root/CFwarp.sh
curl -sL -o /root/CFwarp.sh https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh
chmod +x /root/CFwarp.sh
echo -e "\n\033[1;45;37m ⏸️ 主脚本已挂起！即将唤出勇哥 WARP 菜单... \033[0m"
echo -e "\033[1;36m👉 请根据机器情况手动安装 (纯v6机建议装双栈 或 单栈IPv4)。\033[0m"
echo -e "\033[1;33m⚠️ 关键：安装成功并看到 WARP IP 后，请在菜单输入 0 退出！\033[0m"
sleep 5
bash /root/CFwarp.sh

echo -e "\n\033[1;32m▶️ WARP 菜单已关闭，天网主程序恢复执行！\033[0m"
echo -e "\033[1;33m⏳ 正在校验 WARP IPv4 连通性...\033[0m"
V4_READY=false
for i in {1..6}; do
    WARP_IP=$(curl -s4 -m 5 api.ipify.org 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    if [ -n "$WARP_IP" ]; then
        echo -e "\033[1;32m✅ WARP IPv4 获取成功！出站 IP: $WARP_IP\033[0m"
        V4_READY=true; break
    else
        echo -e "\033[1;35m⚠️ 未检测到 IPv4，重试中...\033[0m"; sleep 5
    fi
done

if [ "$V4_READY" = false ]; then echo -e "\n\033[1;41;37m 💀 致命错误：WARP 未获取到 IPv4！部署熔断。\033[0m"; exit 1; fi

# ====================================================================
# 4. 打捞核心组件
# ====================================================================
echo -e "\033[1;33m📦 第二阶段：拉取底层核心引擎...\033[0m"
curl -sL -A "Mozilla/5.0" -o /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

S_URL=$(curl -sL --connect-timeout 5 -A "Mozilla/5.0" "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep -o 'https://[^"]*linux-amd64\.tar\.gz' | head -n 1)
[ -z "$S_URL" ] && S_URL="https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz"
curl -sL --connect-timeout 15 -A "Mozilla/5.0" -o /tmp/sbox.tar.gz "$S_URL"
if [ -s /tmp/sbox.tar.gz ] && tar -tzf /tmp/sbox.tar.gz >/dev/null 2>&1; then
    tar -xzf /tmp/sbox.tar.gz -C /tmp/ 2>/dev/null
    mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box 2>/dev/null
    chmod +x /etc/s-box/sing-box
else
    echo -e "\n\033[1;41;37m 💀 Sing-box 解压失败！\033[0m"; exit 1
fi

# ====================================================================
# 5. 配置核心路由与气闸
# ====================================================================
cat << 'CONFIG_EOF' > /etc/s-box/sing-box.json
{
  "log": {"level": "fatal"},
  "inbounds": [
    { "type": "hysteria2", "tag": "hy2-in-1", "listen": "::", "listen_port": 8443, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-2", "listen": "::", "listen_port": 8444, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "hysteria2", "tag": "hy2-in-3", "listen": "::", "listen_port": 8445, "users": [{"password": "PsiphonUS_2026"}], "tls": {"enabled": true, "server_name": "bing.com", "certificate_path": "/etc/s-box/hy2.crt", "key_path": "/etc/s-box/hy2.key"} },
    { "type": "vmess", "tag": "vmess-in-1", "listen": "127.0.0.1", "listen_port": 10001, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s1"} },
    { "type": "vmess", "tag": "vmess-in-2", "listen": "127.0.0.1", "listen_port": 10002, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s2"} },
    { "type": "vmess", "tag": "vmess-in-3", "listen": "127.0.0.1", "listen_port": 10003, "users": [{"uuid": "d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a", "alterId": 0}], "transport": {"type": "ws", "path": "/s3"} }
  ],
  "outbounds": [
    { "type": "socks", "tag": "out-s1", "server": "127.0.0.1", "server_port": 1081 },
    { "type": "socks", "tag": "out-s2", "server": "127.0.0.1", "server_port": 1082 },
    { "type": "socks", "tag": "out-s3", "server": "127.0.0.1", "server_port": 1083 }
  ],
  "route": {"rules": [ 
    {"inbound": ["hy2-in-1", "vmess-in-1"], "outbound": "out-s1"}, 
    {"inbound": ["hy2-in-2", "vmess-in-2"], "outbound": "out-s2"}, 
    {"inbound": ["hy2-in-3", "vmess-in-3"], "outbound": "out-s3"} 
  ]}
}
CONFIG_EOF
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
cat > /etc/systemd/system/sing-box.service << 'SVC_EOF'
[Unit]
Description=Sing-box Service
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
systemctl daemon-reload && systemctl enable --now sing-box >/dev/null 2>&1

# ====================================================================
# 6. 初始化沙盒底层引擎
# ====================================================================
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN=2081; DIR="/etc/s-box"; REG="US"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN=2082; DIR="/etc/s-box/sub2"; REG="GB"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN=2083; DIR="/etc/s-box/sub3"; REG="JP"; SVC="psiphon3"; }
    [ "$NODE" == "4" ] && { IN=2084; DIR="/etc/s-box/sub4"; REG="SG"; SVC="psiphon4"; }
    cp /etc/s-box/psiphon-tunnel-core "$DIR/" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{"LocalHttpProxyPort":$((IN+16000)),"LocalSocksProxyPort":$IN,"PropagationChannelId":"FFFFFFFFFFFFFFFF","SponsorId":"FFFFFFFFFFFFFFFF","EgressRegion": "$REG","DataRootDirectory":"$DIR","RemoteServerListDownloadFilename":"remote_server_list","RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=","RemoteServerListUrl":"https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed","UseIndistinguishableTLS":true}
P_EOF
    cat > /etc/systemd/system/${SVC}.service << SVC_EOF
[Unit]
Description=Psiphon $NODE
After=network.target
[Service]
WorkingDirectory=$DIR
ExecStart=$DIR/psiphon-tunnel-core -config base.config
Restart=always
[Install]
WantedBy=multi-user.target
SVC_EOF
    systemctl enable --now ${SVC} >/dev/null 2>&1
done

# ====================================================================
# 7. 隐蔽猎犬引擎 (sl1 ~ sl3) -> 藏入 /etc/s-box/ 防冲突
# ====================================================================
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; SVC="psiphon3"; }
    
    cat << EOF > /etc/s-box/sl${NODE}
#!/bin/bash
NODE="${NODE}"; IN_PORT="${IN_PORT}"; OUT_PORT="${OUT_PORT}"; DIR="${DIR}"; SVC="${SVC}"; SLA_LOG="/etc/s-box/stability.log"
TARGET=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null); [ -z "\$TARGET" ] && exit 0
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
ATTEMPTS=0; CHASE_START=\$(date +%s)
echo "\$(date '+[%m-%d %H:%M:%S]') [🕵️ 寻回] S\${NODE} 启动智能洗牌夺回，目标：\$TARGET" >> "\$SLA_LOG"
while true; do
    ((ATTEMPTS++))
    if [ -f "\$DIR/s\${NODE}.manual" ] || [ -f "\$DIR/s\${NODE}.disabled" ]; then exit 0; fi
    if [ \$((\$(date +%s) - CHASE_START)) -ge 1200 ]; then
        echo "\$(date '+[%m-%d %H:%M:%S]') [🌙 休眠] S\${NODE} 追捕20分钟无果，防爆休眠！" >> "\$SLA_LOG"
        touch "\$DIR/s\${NODE}.hibernating"; systemctl stop "\$SVC" 2>/dev/null; exit 0
    fi
    systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    IP=""
    for i in {1..5}; do
        sleep 3; API=\${APIS[\$RANDOM % \${#APIS[@]}]}
        IP=\$(curl -s4 -m 3 --socks5 127.0.0.1:\$IN_PORT \$API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "\$IP" ] && break
    done
    if [ "\$IP" == "\$TARGET" ]; then
        rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null
        COST=\$((\$(date +%s) - CHASE_START))
        echo "\$(date '+[%m-%d %H:%M:%S]') [🟢 恢复] S\${NODE} 耗时 \$COST 秒，洗牌 \$ATTEMPTS 次复苏目标：\$IP" >> "\$SLA_LOG"
        fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        [ ! -f "\$DIR/s\${NODE}.session" ] && date +%s > "\$DIR/s\${NODE}.session"
        exit 0
    fi
done
EOF
    chmod +x /etc/s-box/sl${NODE}
done

# ====================================================================
# 8. 大后台哨兵引擎 (w_master)
# ====================================================================
cat > /usr/bin/w_master << 'EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")
# ⚠️ 开机物理大清洗：毁灭所有的幽灵状态
find /etc/s-box -name "*.manual" -o -name "*.session" -o -name "*.hibernating" | xargs rm -f 2>/dev/null
echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 开机/重置！天网哨兵已就绪，幽灵状态已清洗。" >> "$SLA_LOG"

get_node_ip() {
    local PORT=$1; local IP=""; local RAND_API=${APIS[$RANDOM % ${#APIS[@]}]}
    IP=$(curl -s4 -m 6 --socks5 127.0.0.1:$PORT $RAND_API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
    [ -n "$IP" ] && { echo "$IP"; return; }
    sleep 2
    for api in "${APIS[@]}"; do
        [ "$api" == "$RAND_API" ] && continue
        IP=$(curl -s4 -m 6 --socks5 127.0.0.1:$PORT $api 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        [ -n "$IP" ] && { echo "$IP"; return; }
    done
    echo ""
}

while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        
        # 如果人工介入、深度休眠、防爆休眠，哨兵绝对不干预
        if [ -f "$WORK/s${NODE}.manual" ] || [ -f "$WORK/s${NODE}.disabled" ] || [ -f "$WORK/s${NODE}.hibernating" ]; then continue; fi
        
        LOCK="$WORK/s${NODE}.lock"; [ ! -f "$LOCK" ] && continue
        TARGET=$(cat "$LOCK" | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        CURRENT=$(get_node_ip $IN_PORT)
        
        if [[ -n "$CURRENT" && "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then
                socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT &
                echo "$(date '+[%m-%d %H:%M:%S]') [🟢 恢复] S${NODE} 利用底层缓存秒连，气闸开启！" >> "$SLA_LOG"
                [ ! -f "$WORK/s${NODE}.session" ] && date +%s > "$WORK/s${NODE}.session"
            fi
        elif ! pgrep -f "/etc/s-box/sl${NODE}" > /dev/null; then
            if [[ -n "$CURRENT" && "$CURRENT" != "$TARGET" ]]; then
                fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
                echo "$(date '+[%m-%d %H:%M:%S]') [🚨 漂移] S${NODE} 漂移至($CURRENT)！Session清零，斩断气闸呼叫猎犬！" >> "$SLA_LOG"
                rm -f "$WORK/s${NODE}.session" 2>/dev/null
                nohup /etc/s-box/sl${NODE} >/dev/null 2>&1 &
                sleep 15
            elif [ -z "$CURRENT" ]; then
                fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
                echo "$(date '+[%m-%d %H:%M:%S]') [🟡 假死] S${NODE} 深度断网！斩断气闸(保留Session)，移交猎犬复苏！" >> "$SLA_LOG"
                nohup /etc/s-box/sl${NODE} >/dev/null 2>&1 &
                sleep 15
            fi
        fi
    done
    sleep 20
done
EOF
chmod +x /usr/bin/w_master
cat > /etc/systemd/system/w_master.service << 'EOF'
[Unit]
Description=Skynet Master Sentinel
[Service]
ExecStart=/usr/bin/w_master
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable --now w_master >/dev/null 2>&1

# ====================================================================
# 9. 核心！【tw】天网大一统总控台 
# ====================================================================
cat << 'EOF' > /usr/bin/tw
#!/bin/bash
# ===================== 全局 Trap 护城河 =====================
cleanup_manual() {
    rm -f /etc/s-box/s*.manual /etc/s-box/sub*/s*.manual 2>/dev/null
}
trap 'cleanup_manual; echo -e "\n\033[1;31m[安全中断] 退出天网总控台...\033[0m"; exit 0' INT TERM QUIT HUP

APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip" "http://ident.me" "http://checkip.amazonaws.com")

get_node_vars() {
    case $1 in
        1) N_IN=2081; N_OUT=1081; N_DIR="/etc/s-box"; N_REG="US"; N_SVC="psiphon1" ;;
        2) N_IN=2082; N_OUT=1082; N_DIR="/etc/s-box/sub2"; N_REG="GB"; N_SVC="psiphon2" ;;
        3) N_IN=2083; N_OUT=1083; N_DIR="/etc/s-box/sub3"; N_REG="JP"; N_SVC="psiphon3" ;;
    esac
}

draw_dashboard() {
    clear
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    echo -e "\033[1;37m                                  🛡️ 天网系统 V22 (全局大一统中控中心) 🛡️\033[0m"
    echo -e "\033[1;36m=========================================================================================================\033[0m"
    printf " %-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\n" "通道" "战区" "锁定目标 IP" "当前真实 IP" "对外气闸" "总存活" "未漂移" "健康状态及行动指示"
    echo "---------------------------------------------------------------------------------------------------------"
    for N in 1 2 3; do
        get_node_vars $N
        REG=$(grep -oP '"EgressRegion"\s*:\s*"\K[A-Z]+' $N_DIR/base.config 2>/dev/null || echo "$N_REG")
        TAR=$(cat "$N_DIR/s$N.lock" 2>/dev/null)
        CUR=$(curl -s4 -m 3 --socks5 127.0.0.1:$N_IN ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if netstat -tlnp 2>/dev/null | grep -q ":$N_OUT "; then G_R="🟢开启"; else G_R="🔴截断"; fi
        
        UP_TOT="--:--:--"; UP_SES="--:--:--"
        NW=$(date +%s)
        if [ -n "$TAR" ]; then
            if [ -f "$N_DIR/s$N.uptime" ]; then ST_TOT=$(cat "$N_DIR/s$N.uptime" 2>/dev/null); DF=$((NW - ST_TOT)); [ $DF -gt 0 ] && UP_TOT=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
            if [ -f "$N_DIR/s$N.session" ]; then ST_SES=$(cat "$N_DIR/s$N.session" 2>/dev/null); DF=$((NW - ST_SES)); [ $DF -gt 0 ] && UP_SES=$(printf "%02d:%02d:%02d" $((DF/3600)) $((DF%3600/60)) $((DF%60))); fi
        fi

        if [ -f "$N_DIR/s$N.disabled" ]; then C="\033[1;90m"; G_R="⚫关闭"; S="💤 深度休眠 (资源已释放)"; CUR=""
        elif [ -f "$N_DIR/s$N.manual" ]; then C="\033[1;35m"; G_R="🛑截断"; S="🛑 人工调优防泄露中"
        elif [ -z "$CUR" ]; then C="\033[1;33m"; G_R="🔴截断"; S="🟡 假死网络断流中"
        elif [ "$CUR" == "$TAR" ]; then C="\033[1;32m"; G_R="🟢开启"; S="✅ 稳定零泄漏"
        else C="\033[1;31m"; G_R="🔴截断"; S="🚨 IP漂移！夺回中"; fi
        printf " ${C}%-4s | %-4s | %-15s | %-15s | %-8s | %-8s | %-8s | %s\033[0m\n" "S$N" "$REG" "$TAR" "${CUR:-空}" "$G_R" "$UP_TOT" "$UP_SES" "$S"
    done
    echo -e "\033[1;36m=========================================================================================================\033[0m"
}

action_toggle() {
    local N=$1; get_node_vars $N
    if [ -f "$N_DIR/s$N.disabled" ]; then
        rm -f "$N_DIR/s$N.disabled" "$N_DIR/s$N.hibernating"
        systemctl enable --now "$N_SVC" >/dev/null 2>&1
        echo -e "\033[1;32m✅ 成功：S$N 通道已唤醒，哨兵即将接管！\033[0m"
    else
        touch "$N_DIR/s$N.disabled"
        systemctl disable --now "$N_SVC" >/dev/null 2>&1
        pkill -f "/etc/s-box/sl$N" 2>/dev/null
        fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
        echo -e "\033[1;33m💤 成功：S$N 通道已物理休眠，防复活机制生效！\033[0m"
    fi
    sleep 2
}

action_toggle_all() {
    local STATE=$1
    echo -e "\033[1;36m⏳ 正在执行全局调度...\033[0m"
    for N in 1 2 3; do
        get_node_vars $N
        if [ "$STATE" == "ON" ]; then
            rm -f "$N_DIR/s$N.disabled" "$N_DIR/s$N.hibernating"
            systemctl enable --now "$N_SVC" >/dev/null 2>&1
        else
            touch "$N_DIR/s$N.disabled"
            systemctl disable --now "$N_SVC" >/dev/null 2>&1
            pkill -f "/etc/s-box/sl$N" 2>/dev/null
            fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
        fi
    done
    sleep 2
}

action_draw() {
    local N=$1; get_node_vars $N
    # 物理防呆：强行解除休眠
    rm -f "$N_DIR/s$N.disabled" 2>/dev/null; systemctl enable --now "$N_SVC" >/dev/null 2>&1
    # 绝对防泄露：斩断气闸
    fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
    echo $$ > "$N_DIR/s$N.manual"
    echo "$(date '+[%m-%d %H:%M:%S]') [🛑 人为] 主人介入 S$N 抽卡，已斩断对外气闸防泄露！" >> /etc/s-box/stability.log
    
    clear
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "              🐺 [S$N] 天网安全抽卡引擎"
    echo -e "\033[1;36m========================================================\033[0m"
    echo -e "  [1] 🇺🇸 美国  [2] 🇬🇧 英国  [3] 🇯🇵 日本  [4] 🇸🇬 新加坡"
    echo -ne "\033[1;33m👉 选择目标战区 (默认当前): \033[0m"; read r
    case "$r" in 1) TR="US";; 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; esac
    [ -n "$TR" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"$TR\"/g" $N_DIR/base.config

    while true; do
        systemctl stop "$N_SVC" 2>/dev/null; rm -rf "$N_DIR/ca.psiphon"* 2>/dev/null; systemctl start "$N_SVC"
        echo -ne "\r\033[K\033[1;36m⏳ 正在盲抽洗牌中...\033[0m"; sleep 8
        API=${APIS[$RANDOM % ${#APIS[@]}]}
        IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$N_IN $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        if [ -z "$IP" ]; then
            sleep 3; API=${APIS[$RANDOM % ${#APIS[@]}]}
            IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$N_IN $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
        fi
        [ -z "$IP" ] && continue
        echo -e "\n\033[1;32m🎯 命中 IP: \033[1;37m$IP\033[0m"
        echo -ne "\033[1;33m✨ 满意按 [Y] 挂锁保存，按回车重抽: \033[0m"; read k
        if [[ "$k" == "y" || "$k" == "Y" ]]; then
            echo "$IP" > "$N_DIR/s$N.lock"; date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
            rm -f "$N_DIR/s$N.hibernating" 2>/dev/null
            echo -e "\033[1;32m✅ 极品已挂锁！监控引擎已同步。\033[0m"; sleep 2; break
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

action_force() {
    local N=$1; get_node_vars $N
    rm -f "$N_DIR/s$N.disabled" 2>/dev/null; systemctl enable --now "$N_SVC" >/dev/null 2>&1
    fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
    echo $$ > "$N_DIR/s$N.manual"
    echo "$(date '+[%m-%d %H:%M:%S]') [🛑 人为] 主人介入 S$N 死磕，已斩断气闸防泄露！" >> /etc/s-box/stability.log
    
    clear
    TARGET=$(cat "$N_DIR/s$N.lock" 2>/dev/null)
    echo -e "\033[1;35m========================================================\033[0m"
    echo -e "              🐺 [S$N] 狂暴死磕引擎"
    echo -e "\033[1;35m========================================================\033[0m"
    echo -ne "\033[1;32m👉 输入新目标IP (直接回车则死磕旧IP $TARGET): \033[0m"; read i
    if [ -n "$i" ]; then
        TARGET="$i"; echo "$TARGET" > "$N_DIR/s$N.lock"
        date +%s > "$N_DIR/s$N.uptime"; date +%s > "$N_DIR/s$N.session"
        echo -e "  [1] 🇺🇸 US  [2] 🇬🇧 GB  [3] 🇯🇵 JP  [4] 🇸🇬 SG"
        echo -ne "👉 \033[1;33m请为新 IP 匹配战区: \033[0m"; read r
        case "$r" in 1) TR="US";; 2) TR="GB";; 3) TR="JP";; 4) TR="SG";; esac
        [ -n "$TR" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"$TR\"/g" $N_DIR/base.config
    fi
    echo -e "\033[1;90m────────────────────────────────────────────────────────\033[0m"
    a=0
    while true; do
        ((a++)); echo -ne "\r\033[K\033[1;35m⏳ [第 $a 次]\033[0m 字节级强行夺回中..."
        systemctl stop "$N_SVC" 2>/dev/null; rm -rf "$N_DIR/ca.psiphon"* 2>/dev/null; systemctl start "$N_SVC"
        IP=""
        for i in {1..5}; do
            sleep 3; API=${APIS[$RANDOM % ${#APIS[@]}]}
            IP=$(curl -s4 -m 3 --socks5 127.0.0.1:$N_IN $API 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            [ -n "$IP" ] && break
        done
        if [ "$IP" == "$TARGET" ]; then
            date +%s > "$N_DIR/s$N.session"; rm -f "$N_DIR/s$N.hibernating" 2>/dev/null
            fuser -k -9 "$N_OUT/tcp" >/dev/null 2>&1
            socat TCP4-LISTEN:$N_OUT,fork,reuseaddr TCP4:127.0.0.1:$N_IN &
            echo -e "\n\033[1;32m🎉 命中目标！死磕成功，监控大盘已同步！\033[0m"; sleep 2; break
        fi
    done
    rm -f "$N_DIR/s$N.manual" 2>/dev/null
}

manage_node() {
    local N=$1
    while true; do
        clear
        echo -e "\033[1;36m>>> 正在管控 S$N 战区 <<<\033[0m"
        echo -e "  [1] 🎯 安全抽卡 (盲抽极品新IP)"
        echo -e "  [2] 🐺 狂暴死磕 (强行夺回旧IP或指定IP)"
        echo -e "  [3] 🔄 切换通道启停 (物理断连/开启)"
        echo -e "  [0] 🔙 返回上级大盘"
        read -p "👉 请选择: " sub_cmd
        case "$sub_cmd" in
            1) action_draw $N; break ;;
            2) action_force $N; break ;;
            3) action_toggle $N; break ;;
            0) break ;;
        esac
    done
}

action_s4() {
    DIR="/etc/s-box/sub4"; BLACKLIST_FILE="/etc/s-box/blacklist/bad_ips.txt"; SVC="psiphon4"; IN_PORT=2084; touch "$BLACKLIST_FILE"
    clear; echo -e "\033[1;36m   👻 [S4] 幽灵斥候 - 旁路洗号引擎 \033[0m\n   当前黑名单拦截库: $(wc -l < $BLACKLIST_FILE 2>/dev/null || echo 0) 条\n"
    echo -e "  [1] 🌊 启动深海打捞      [2] 📥 批量导入黑名单"
    echo -e "  [3] 📜 查看当前黑名单    [4] 🗑️ 清空全部黑名单"
    echo -e "  [0] 🚪 退出"
    read -p "👉 请选择 (默认 1): " c; [ -z "$c" ] && c=1
    if [ "$c" == "3" ]; then echo -e "\n\033[1;36m📜 黑名单:\033[0m"; cat "$BLACKLIST_FILE" | column; sleep 3; return; fi
    if [ "$c" == "4" ]; then > "$BLACKLIST_FILE"; echo -e "\n\033[1;31m💥 清空完毕！\033[0m"; sleep 2; return; fi
    if [ "$c" == "2" ]; then echo -e "💡 粘贴IP(回车完成): "; read INPUT; for BAD_IP in $INPUT; do echo "$BAD_IP" >> "$BLACKLIST_FILE"; done; return; fi
    if [ "$c" == "1" ]; then
        echo "  [1] 🇺🇸 US   [2] 🇬🇧 GB   [3] 🇯🇵 JP"; read -p "战区 (默认 1): " rc
        [ "$rc" == "1" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"US\"/g" $DIR/base.config
        [ "$rc" == "2" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"GB\"/g" $DIR/base.config
        [ "$rc" == "3" ] && sed -i "s/\"EgressRegion\"[[:space:]]*:[[:space:]]*\"[A-Z]*\"/\"EgressRegion\": \"JP\"/g" $DIR/base.config
        read -p "打捞次数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
        A=0; VALID=()
        while [ $A -lt $SCAN_MAX ]; do
            ((A++)); echo -ne "\r\033[K🔍 [$A/$SCAN_MAX] 下网..."
            systemctl stop "$SVC" >/dev/null 2>&1; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* >/dev/null 2>&1; systemctl start "$SVC"; sleep 8
            IP=$(curl -s4 -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
            if [ -n "$IP" ]; then
                if grep -q "^${IP}$" "$BLACKLIST_FILE" 2>/dev/null; then echo -e "\n  ├─ 🚫 触发黑名单: $IP"
                else echo -e "\n  └─ 🌟 捕获纯净极品: \033[1;32m$IP\033[0m"; VALID+=("$IP"); fi
            else echo -e "\n  ├─ \033[1;31m❌ 节点寻路超时\033[0m"; fi
        done
        echo -e "\n\033[1;33m📊 打捞获得 ${#VALID[@]} 个极品。\033[0m"
        if [ ${#VALID[@]} -gt 0 ]; then
            printf "%s\n" "${VALID[@]}" | sort -V | uniq -c | sort -nr
            echo "  [1] 全部绞杀 (打入黑名单)   [0] 退出"; read -p "请裁决: " ec
            if [ "$ec" == "1" ]; then printf "%s\n" "${VALID[@]}" | sort -u >> "$BLACKLIST_FILE"; echo "✅ 已送入黑名单。"; sleep 2; fi
        fi
    fi
}

action_nodes() {
    IP=$(curl -s6 -m 5 api64.ipify.org 2>/dev/null || curl -s6 -m 5 icanhazip.com 2>/dev/null)
    [ -z "$IP" ] && IP=$(ip -6 addr show dev eth0 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | head -n 1)
    [ -z "$IP" ] && IP="[获取IPv6失败_请手动替换]"
    UUID="d3b2a1a1-5f2a-4a2a-8c2a-1a2a3a4a5a6a"; PW="PsiphonUS_2026"
    clear
    echo -e "\033[1;36m=================================================================\033[0m"
    echo -e "\n\033[1;35m【第一部分】Cloudflare Zero Trust 网页端隧道映射\033[0m"
    echo -e "👉 子域名 1 (接管 S1) -> URL: \033[1;32mlocalhost:10001\033[0m"
    echo -e "👉 子域名 2 (接管 S2) -> URL: \033[1;32mlocalhost:10002\033[0m"
    echo -e "👉 子域名 3 (接管 S3) -> URL: \033[1;32mlocalhost:10003\033[0m"
    echo -e "\n\033[1;35m【第二部分】Argo 隧道 VMess 节点 (需替换 CF 域名)\033[0m"
    gen_vmess() { echo "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$1\",\"add\":\"你的专属CF子域名\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"你的专属CF子域名\",\"path\":\"$2\",\"tls\":\"tls\"}" | base64 -w 0)"; }
    echo -e "🇺🇸 S1 战区: \033[40;32m $(gen_vmess "Skynet-CF-S1" "/s1") \033[0m"
    echo -e "🇬🇧 S2 战区: \033[40;32m $(gen_vmess "Skynet-CF-S2" "/s2") \033[0m"
    echo -e "🇯🇵 S3 战区: \033[40;32m $(gen_vmess "Skynet-CF-S3" "/s3") \033[0m"
    echo -e "\n\033[1;35m【第三部分】直连 Hysteria2 节点 (IPv6 原生直通)\033[0m"
    echo -e "🇺🇸 S1: \033[40;32m hysteria2://$PW@[$IP]:8443/?sni=bing.com&insecure=1#Skynet-HY2-S1 \033[0m"
    echo -e "🇬🇧 S2: \033[40;32m hysteria2://$PW@[$IP]:8444/?sni=bing.com&insecure=1#Skynet-HY2-S2 \033[0m"
    echo -e "🇯🇵 S3: \033[40;32m hysteria2://$PW@[$IP]:8445/?sni=bing.com&insecure=1#Skynet-HY2-S3 \033[0m"
    echo -e "\n\033[1;36m=================================================================\033[0m"
    echo "请按回车键返回..."
    read
}

action_uninstall() {
    clear; echo -e "\033[1;31m⚠️ 正在启动【天网自毁回滚程序】\033[0m\n👉 确定要彻底焚毁天网吗？(输入 y 确认): \c"; read confirm
    [ "$confirm" != "y" ] && return
    systemctl stop w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 warp-go wg-quick@wgcf >/dev/null 2>&1
    systemctl disable w_master sing-box psiphon1 psiphon2 psiphon3 psiphon4 >/dev/null 2>&1
    rm -f /etc/systemd/system/w_master.service /etc/systemd/system/sing-box.service /etc/systemd/system/psiphon*.service
    systemctl daemon-reload; pkill -9 -f psiphon-tunnel-core; pkill -9 -f sing-box; pkill -9 -f w_master; pkill -9 -f sl
    [ -f "/root/CFwarp.sh" ] && echo -e "\033[1;33m👉 请在弹出的菜单中选择卸载 WARP\033[0m" && bash /root/CFwarp.sh
    rm -rf /etc/s-box /usr/bin/tw /root/CFwarp.sh
    crontab -l 2>/dev/null | grep -v "stability.log" | crontab -
    sed -i '/prefer-family = IPv6/d' ~/.wgetrc 2>/dev/null
    echo "🎉 物理超度完毕！"
    exit 0
}

# --- 天网主循环 ---
while true; do
    draw_dashboard
    echo -e "  \033[1;33m⚙️ 【天网矩阵调度中心】\033[0m"
    echo -e "  [1] 🇺🇸 S1 战区管理 (抽卡/死磕/启停)    [4] 👻 S4 旁路打捞引擎"
    echo -e "  [2] 🇬🇧 S2 战区管理 (抽卡/死磕/启停)    [5] 🔗 提取节点配置信息"
    echo -e "  [3] 🇯🇵 S3 战区管理 (抽卡/死磕/启停)    [6] 📜 追踪实时运行史记"
    echo -e "  ------------------------------------------------------------"
    echo -e "  [7] 🟢 一键全部开启 (唤醒所有通道)     [9] ⚠️ 终极自毁卸载"
    echo -e "  [8] 🔴 一键全部休眠 (释放所有资源)     [0] 🚪 退出总控台"
    echo ""
    read -t 10 -p "👉 请输入指令 (10秒无操作将自动刷新大盘): " cmd
    if [ $? -gt 128 ]; then continue; fi # 捕捉超时，继续循环刷新
    
    case "$cmd" in
        1) manage_node 1 ;;
        2) manage_node 2 ;;
        3) manage_node 3 ;;
        4) action_s4 ;;
        5) action_nodes ;;
        6) clear; echo -e "\033[1;36m📜 正在追踪史记 (按 Ctrl+C 返回大盘)...\033[0m\n"; tail -f /etc/s-box/stability.log ;;
        7) action_toggle_all "ON" ;;
        8) action_toggle_all "OFF" ;;
        9) action_uninstall ;;
        0) clear; echo "🔰 已安全退出天网界面，后台哨兵持续守护中。"; exit 0 ;;
    esac
done
EOF
chmod +x /usr/bin/tw

# 10. 凌晨 4 点重启任务
(crontab -l 2>/dev/null | grep -v "stability.log"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重置，开启新史记 ===\" > /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V22 终极版部署完毕！所有模块已大一统！\033[0m"
echo -e "\033[1;37m👉 请在终端输入 \033[1;36mtw\033[1;37m 唤醒天网总控台！\033[0m"
