#!/bin/bash
# ====================================================================
# 天网系统 V9.6 终极真理版 (官方直连纯净版 + WARP双栈 + 绝对寿命)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网系统 V9.6】全量创世部署 (100% 官方直连纯净版)...\033[0m"

# 1. 基础环境与烦人的主机名修复
echo -e "\033[1;36m📦 1/7 正在修复系统环境与安装依赖...\033[0m"
MY_HOST=$(hostname)
echo "127.0.0.1 localhost $MY_HOST" > /etc/hosts
apt-get update -y >/dev/null 2>&1
apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl nano cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# 2. 部署 WARP-GO (打通全球双栈，为后续官方直连铺路)
echo -e "\033[1;36m🌐 2/7 正在植入 WARP-GO，获取全球 IPv4 访问权限...\033[0m"
wget -qN https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh
bash warp-go.sh 4 >/dev/null 2>&1
sleep 8

# 3. 核心引擎 100% 官方直连拉取 (零第三方代理)
echo -e "\033[1;36m⚙️ 3/7 正在直连官方主库下载核心引擎...\033[0m"
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

wget -q --show-progress -O /tmp/sbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.3/sing-box-1.9.3-linux-amd64.tar.gz
tar -xzf /tmp/sbox.tar.gz -C /tmp/
mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box
chmod +x /etc/s-box/sing-box
rm -rf /tmp/sbox.tar.gz /tmp/sing-box-*

# 4. 烧录 Sing-box 核心路由
echo -e "\033[1;36m🚦 4/7 正在烧录 Sing-box 路由与生成 TLS 证书...\033[0m"
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null

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
  "route": {"rules": [ {"inbound": ["hy2-in-1", "vmess-in-1"], "outbound": "out-s1"}, {"inbound": ["hy2-in-2", "vmess-in-2"], "outbound": "out-s2"}, {"inbound": ["hy2-in-3", "vmess-in-3"], "outbound": "out-s3"} ] }
}
CONFIG_EOF

cat > /etc/systemd/system/sing-box.service << 'SVC_EOF'
[Unit]
Description=Sing-box Core Router
After=network.target
[Service]
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sing-box.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
SVC_EOF
systemctl daemon-reload && systemctl enable sing-box >/dev/null 2>&1 && systemctl start sing-box

# 5. 开辟四大底层沙盒
echo -e "\033[1;36m🐺 5/7 正在开辟底层物理战区沙盒...\033[0m"
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; HTTP_PORT=18081; DIR="/etc/s-box"; REG="US"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; HTTP_PORT=18082; DIR="/etc/s-box/sub2"; REG="GB"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; HTTP_PORT=18083; DIR="/etc/s-box/sub3"; REG="JP"; }
    [ "$NODE" == "4" ] && { IN_PORT=2084; HTTP_PORT=18084; DIR="/etc/s-box/sub4"; REG="US"; }

    cp /etc/s-box/psiphon-tunnel-core "$DIR/psiphon-tunnel-core" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{
  "LocalHttpProxyPort": $HTTP_PORT,
  "LocalSocksProxyPort": $IN_PORT,
  "PropagationChannelId": "FFFFFFFFFFFFFFFF",
  "SponsorId": "FFFFFFFFFFFFFFFF",
  "EgressRegion": "$REG",
  "DataRootDirectory": "$DIR",
  "RemoteServerListDownloadFilename": "remote_server_list",
  "RemoteServerListSignaturePublicKey": "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
  "RemoteServerListUrl": "https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed",
  "UseIndistinguishableTLS": true
}
P_EOF
    cat > /etc/systemd/system/psiphon${NODE}.service << SVC2_EOF
[Unit]
Description=Psiphon Node $NODE
After=network.target
[Service]
WorkingDirectory=$DIR
ExecStart=$DIR/psiphon-tunnel-core -config base.config
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
SVC2_EOF
    systemctl enable psiphon${NODE} >/dev/null 2>&1 && systemctl start psiphon${NODE}
done

# 6. 注入 S/L/SL 引擎
echo -e "\033[1;36m🧠 6/7 正在注入 S/L/SL 解耦引擎与 S4 旁路程序...\033[0m"
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; DIR="/etc/s-box"; SVC="psiphon1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; DIR="/etc/s-box/sub2"; SVC="psiphon2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; DIR="/etc/s-box/sub3"; SVC="psiphon3"; }

cat << S_EOF > /usr/bin/s${NODE}
#!/bin/bash
NODE="$NODE"; IN_PORT="$IN_PORT"; OUT_PORT="$OUT_PORT"; DIR="$DIR"; SVC="$SVC"; SLA_LOG="/etc/s-box/stability.log"
echo \$\$ > "\$DIR/s\${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') 🛑 主人手动介入 S\${NODE} 模式！" >> "\$SLA_LOG"
trap 'echo "\$(date '+[%m-%d %H:%M:%S]') 🔰 主人退出 S\${NODE} 模式！" >> "\$SLA_LOG"; rm -f "\$DIR/s\${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT
clear; echo -e "\033[1;35m🐺 [S\$NODE] 安全抽卡引擎\033[0m"
OLD_LOCK=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null | tr -d '[:space:]')
[ -n "\$OLD_LOCK" ] && echo -e "🛡️ \033[1;32m当前保底 IP: \$OLD_LOCK\033[0m"
fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ATTEMPTS=0
while true; do
    ((ATTEMPTS++)); echo -ne "\r\033[K⏳ [\$ATTEMPTS 次] 盲抽中..."
    systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    sleep 6; IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN_PORT \${APIS[\$RANDOM % \${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    [ -z "\$IP" ] && continue
    echo -e "\n🎯 抽中 IP: \033[32m\$IP\033[0m"
    read -p "✨ 满意按 [Y] 锁定替换，按 [回车] 重抽: " k
    if [[ "\$k" == "y" || "\$k" == "Y" ]]; then
        echo "\$IP" > "\$DIR/s\${NODE}.lock"; date +%s > "\$DIR/s\${NODE}.uptime"
        echo -e "✅ \033[1;32m新极品已挂锁！\033[0m"; break
    fi
done
S_EOF

cat << L_EOF > /usr/bin/l${NODE}
#!/bin/bash
NODE="$NODE"; IN_PORT="$IN_PORT"; OUT_PORT="$OUT_PORT"; DIR="$DIR"; SVC="$SVC"; SLA_LOG="/etc/s-box/stability.log"
echo \$\$ > "\$DIR/s\${NODE}.manual"
echo "\$(date '+[%m-%d %H:%M:%S]') 🛑 主人手动介入 L\${NODE} 模式！" >> "\$SLA_LOG"
trap 'echo "\$(date '+[%m-%d %H:%M:%S]') 🔰 主人退出 L\${NODE} 模式！" >> "\$SLA_LOG"; rm -f "\$DIR/s\${NODE}.manual" 2>/dev/null; exit 0' INT TERM EXIT
clear; echo -e "\033[1;31m🐺 [L\$NODE] 人工狂暴死磕引擎\033[0m"
TARGET=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null | tr -d '[:space:]')
read -p "🎯 输入死磕IP (回车默认 \$TARGET): " INPUT_IP
if [[ -n "\$INPUT_IP" && "\$INPUT_IP" != "\$TARGET" ]]; then 
    TARGET="\$INPUT_IP"; echo "\$TARGET" > "\$DIR/s\${NODE}.lock"; date +%s > "\$DIR/s\${NODE}.uptime"
fi
fuser -k -9 "\$OUT_PORT/tcp" >/dev/null 2>&1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ATTEMPTS=0
while true; do
    ((ATTEMPTS++)); echo -ne "\r\033[K⏳ [\$ATTEMPTS 次] 死磕中..."
    systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    sleep 8; IP=\$(curl -s -m 5 --socks5 127.0.0.1:\$IN_PORT \${APIS[\$RANDOM % \${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    if [ "\$IP" == "\$TARGET" ]; then echo -e "\n🎉 \033[1;31m命中！\$IP\033[0m"; exit 0; fi
done
L_EOF

cat << SL_EOF > /usr/bin/sl${NODE}
#!/bin/bash
NODE="$NODE"; IN_PORT="$IN_PORT"; OUT_PORT="$OUT_PORT"; DIR="$DIR"; SVC="$SVC"
SLA_LOG="/etc/s-box/stability.log"
TARGET=\$(cat "\$DIR/s\${NODE}.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "\$TARGET" ] && exit 1
APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
ATTEMPTS=0; CHASE_START=\$(date +%s)
while true; do
    ((ATTEMPTS++))
    if [ -f "\$DIR/s\${NODE}.manual" ]; then rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null; exit 0; fi
    if [ \$((\$(date +%s) - CHASE_START)) -ge 1200 ]; then
        echo "\$(date '+[%m-%d %H:%M:%S]') 🌙 S\${NODE} 休眠(2小时)..." >> "\$SLA_LOG"
        touch "\$DIR/s\${NODE}.hibernating"; systemctl stop "\$SVC" 2>/dev/null; sleep 7200
        rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null; CHASE_START=\$(date +%s); ATTEMPTS=0; continue
    fi
    sleep \$((RANDOM % 6 + 3))
    systemctl stop "\$SVC" 2>/dev/null; fuser -k -9 "\$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "\$DIR/ca.psiphon"* 2>/dev/null; systemctl start "\$SVC"
    IP=""
    for i in {1..6}; do IP=\$(curl -s -m 3 --socks5 127.0.0.1:\$IN_PORT \${APIS[\$RANDOM % \${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]'); [ -n "\$IP" ] && break; sleep 1; done
    [ -z "\$IP" ] && continue
    if [ \$((ATTEMPTS % 3)) -eq 0 ]; then echo "\$(date '+[%m-%d %H:%M:%S]') ⚙️ SL 狂飙... S\${NODE} 第 \$ATTEMPTS 次 (\$IP)" >> "\$SLA_LOG"; fi
    if [ "\$IP" == "\$TARGET" ]; then
        rm -f "\$DIR/s\${NODE}.hibernating" 2>/dev/null
        echo "\$(date '+[%m-%d %H:%M:%S]') 🟢 S\${NODE} 夺回极品 IP！" >> "\$SLA_LOG"
        socat TCP4-LISTEN:\$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:\$IN_PORT &
        exit 0
    fi
done
SL_EOF
    chmod +x /usr/bin/s${NODE} /usr/bin/l${NODE} /usr/bin/sl${NODE}
done

cat > /usr/bin/s4 << 'S4_EOF'
#!/bin/bash
DIR="/etc/s-box/sub4"; SVC="psiphon4"; IN_PORT=2084; APIS=("http://api.ipify.org" "http://icanhazip.com")
read -p "打捞次数 (默认 20): " SCAN_MAX; [ -z "$SCAN_MAX" ] && SCAN_MAX=20
ATTEMPTS=0
while [ $ATTEMPTS -lt $SCAN_MAX ]; do
    ((ATTEMPTS++)); echo -ne "\r\033[K🔍 [$ATTEMPTS/$SCAN_MAX] 下网..."
    systemctl stop "$SVC" >/dev/null 2>&1; fuser -k -9 "$IN_PORT/tcp" >/dev/null 2>&1; rm -rf "$DIR/ca.psiphon"* >/dev/null 2>&1; systemctl start "$SVC"; sleep 8
    IP=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    [ -n "$IP" ] && echo -e "\n🌟 捕获: \033[1;32m$IP\033[0m"
done
S4_EOF
chmod +x /usr/bin/s4

# 7. 注入哨兵大管家
echo -e "\033[1;36m👁️ 7/7 正在组装真理监控大盘与系统守护进程...\033[0m"
cat > /usr/bin/w_master << 'W_EOF'
#!/bin/bash
SLA_LOG="/etc/s-box/stability.log"; APIS=("http://api.ipify.org" "http://icanhazip.com" "http://ifconfig.me/ip")
echo "$(date '+[%m-%d %H:%M:%S]') 🚀 VPS 系统开机！哨兵接管大盘！" >> "$SLA_LOG"
while true; do
    for NODE in 1 2 3; do
        [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; }
        [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; }
        [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; }
        if [ -f "$WORK/s${NODE}.manual" ]; then if kill -0 $(cat "$WORK/s${NODE}.manual" 2>/dev/null) 2>/dev/null; then continue; fi; rm -f "$WORK/s${NODE}.manual"; fi
        TARGET=$(cat "$WORK/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "$TARGET" ] && continue
        CURRENT=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$CURRENT" && "$CURRENT" == "$TARGET" ]]; then
            if ! netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT "; then socat TCP4-LISTEN:$OUT_PORT,fork,reuseaddr TCP4:127.0.0.1:$IN_PORT & fi
        elif [[ "$CURRENT" != "$TARGET" ]]; then
            fuser -k -9 "$OUT_PORT/tcp" >/dev/null 2>&1
            if ! pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then 
                echo "$(date '+[%m-%d %H:%M:%S]') 🔴 S${NODE} 断连！呼叫后台 SL 追捕！" >> "$SLA_LOG"
                nohup /usr/bin/sl${NODE} >/dev/null 2>&1 &
                sleep 15
            fi
        fi
    done
    sleep 20
done
W_EOF
chmod +x /usr/bin/w_master

cat > /etc/systemd/system/w_master.service << 'WSVC_EOF'
[Unit]
Description=Skynet Sentinel Master
After=network.target sing-box.service
[Service]
ExecStart=/usr/bin/w_master
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
WSVC_EOF
systemctl daemon-reload && systemctl enable w_master >/dev/null 2>&1 && systemctl start w_master

cat > /usr/bin/myip << 'MYIP_EOF'
#!/bin/bash
clear; echo -e "\033[1;36m======================================================================================================\033[0m"
echo -e "\033[1;37m                             🛡️ 天网系统 9.6 (绝对寿命·纯净直连版) 🛡️\033[0m"
echo -e "\033[1;36m======================================================================================================\033[0m"
printf "%-6s | %-16s | %-16s | %-10s | %-14s | %s\n" "通道" "锁定 IP (目标)" "当前真实 IP" "对外气闸" "绝对存活时长" "健康状态"
echo "------------------------------------------------------------------------------------------------------"
APIS=("http://api.ipify.org" "http://icanhazip.com")
for NODE in 1 2 3; do
    [ "$NODE" == "1" ] && { IN_PORT=2081; OUT_PORT=1081; WORK="/etc/s-box"; REG="S1"; }
    [ "$NODE" == "2" ] && { IN_PORT=2082; OUT_PORT=1082; WORK="/etc/s-box/sub2"; REG="S2"; }
    [ "$NODE" == "3" ] && { IN_PORT=2083; OUT_PORT=1083; WORK="/etc/s-box/sub3"; REG="S3"; }
    TARGET=$(cat "$WORK/s${NODE}.lock" 2>/dev/null | tr -d '[:space:]'); [ -z "$TARGET" ] && TARGET="未锁定"
    CURRENT=$(curl -s -m 5 --socks5 127.0.0.1:$IN_PORT ${APIS[$RANDOM % ${#APIS[@]}]} 2>/dev/null | tr -d '[:space:]')
    GATE_REAL=$(netstat -tlnp 2>/dev/null | grep -q ":$OUT_PORT " && echo "开启" || echo "熔断")
    
    UPTIME_STR="--:--:--"
    if [ -f "$WORK/s${NODE}.uptime" ] && [ "$TARGET" != "未锁定" ]; then
        START_TIME=$(cat "$WORK/s${NODE}.uptime" 2>/dev/null | tr -d '[:space:]')
        NOW=$(date +%s); DIFF=$((NOW - START_TIME)); [ $DIFF -lt 0 ] && DIFF=0
        DAYS=$((DIFF / 86400)); HOURS=$(( (DIFF % 86400) / 3600 )); MINS=$(( (DIFF % 3600) / 60 )); SECS=$((DIFF % 60))
        if [ "$DAYS" -gt 0 ]; then UPTIME_STR=$(printf "%d天 %02d:%02d:%02d" $DAYS $HOURS $MINS $SECS); else UPTIME_STR=$(printf "%02d:%02d:%02d" $HOURS $MINS $SECS); fi
    fi
    
    if [ -f "$WORK/s${NODE}.manual" ]; then COLOR="\033[1;35m"; GATE="🛑挂起"; STATUS="🛑 人工干预中"
    elif [ -f "$WORK/s${NODE}.hibernating" ]; then COLOR="\033[1;36m"; GATE="🔴熔断"; STATUS="🌙 深度休眠中"
    elif pgrep -f "/usr/bin/sl${NODE}" > /dev/null; then COLOR="\033[1;31m"; GATE="🔴熔断"; STATUS="🚨 引擎狂暴寻回中..."
    elif [ -z "$CURRENT" ]; then COLOR="\033[1;33m"; GATE="🔴熔断"; CURRENT="获取失败"; STATUS="🟡 阻塞等复苏"
    elif [[ "$GATE_REAL" == "开启" && "$CURRENT" == "$TARGET" ]]; then COLOR="\033[1;32m"; GATE="🟢开启"; STATUS="✅ 极品IP稳固锁定"
    else COLOR="\033[1;31m"; GATE="🔴熔断"; STATUS="🚨 状态异常！"
    fi
    printf "${COLOR}%-6s | %-16s | %-16s | %-10s | %-14s | %s\033[0m\n" "$REG" "$TARGET" "${CURRENT:-空}" "$GATE" "$UPTIME_STR" "$STATUS"
done
echo -e "\033[1;36m======================================================================================================\033[0m"
if [ "$1" == "--live" ]; then grep "^\[$(date '+%m-%d')" /etc/s-box/stability.log | tail -n 12 2>/dev/null || echo -e "\033[1;90m暂无记录\033[0m"
else grep "^\[$(date '+%m-%d')" /etc/s-box/stability.log | grep -v "⚙️ SL 狂飙" | tail -n 50 2>/dev/null || echo -e "\033[1;90m暂无记录\033[0m"; fi
echo -e "\033[1;36m======================================================================================================\033[0m"
MYIP_EOF
chmod +x /usr/bin/myip; ln -sf /usr/bin/myip /usr/bin/c
echo '#!/bin/bash' > /usr/bin/ss && echo 'export LANG=C.UTF-8' >> /usr/bin/ss && echo 'watch -c -n 5 /usr/bin/myip --live' >> /usr/bin/ss && chmod +x /usr/bin/ss

(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * /sbin/reboot") | crontab -
echo -e "\n\033[1;32m🎉 【天网系统 V9.6 终极真理版】纯净官方直连部署完毕！请直接敲入 ss 查看大盘！\033[0m"
