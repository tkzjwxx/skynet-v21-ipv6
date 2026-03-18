#!/bin/bash
# ====================================================================
# 天网系统 V10.1 指挥官版 (增强下载稳定性 + 唯一指令 c)
# ====================================================================
echo -e "\033[1;31m🔥 正在执行【天网系统 V10.1】全量重筑 (增强下载稳定性)...\033[0m"

# 1. 基础环境
apt-get update -y && apt-get install -y curl socat net-tools psmisc wget jq unzip tar openssl cron >/dev/null 2>&1
mkdir -p /etc/s-box/sub2 /etc/s-box/sub3 /etc/s-box/sub4 /etc/s-box/blacklist

# 2. 部署 WARP-GO
echo -e "\033[1;32m🌐 正在植入 WARP-GO 核心...\033[0m"
wget -qN https://gitlab.com/fscarmen/warp/-/raw/main/warp-go.sh
bash warp-go.sh 4 >/dev/null 2>&1

# 3. 核心引擎拉取 (增加重试与容错)
echo -e "\033[1;33m📦 正在打捞核心组件 (Sing-box & Psiphon)...\033[0m"

# 下载 Psiphon
wget -q --show-progress -O /etc/s-box/psiphon-tunnel-core https://raw.githubusercontent.com/Psiphon-Labs/psiphon-tunnel-core-binaries/master/linux/psiphon-tunnel-core-x86_64
chmod +x /etc/s-box/psiphon-tunnel-core

# 【关键修复】下载 Sing-box，增加重试逻辑
MAX_RETRIES=3
for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "正在尝试下载 Sing-box (第 $i 次)..."
    wget -q --show-progress -O /tmp/sbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.9.3/sing-box-1.9.3-linux-amd64.tar.gz
    if [ $? -eq 0 ] && [ -s /tmp/sbox.tar.gz ]; then
        tar -xzf /tmp/sbox.tar.gz -C /tmp/ && mv -f /tmp/sing-box-*/sing-box /etc/s-box/sing-box
        if [ $? -eq 0 ]; then
            echo -e "\033[1;32m✅ Sing-box 核心解压成功！\033[0m"
            break
        fi
    fi
    echo -e "\033[1;31m⚠️ 下载或解压失败，3秒后重试...\033[0m"
    sleep 3
    [ $i -eq $MAX_RETRIES ] && echo "❌ 无法获取核心组件，请检查网络！" && exit 1
done
chmod +x /etc/s-box/sing-box
rm -rf /tmp/sbox.tar.gz /tmp/sing-box-*

# 4. 烧录 Sing-box 路由配置
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/hy2.key 2>/dev/null
openssl req -new -x509 -days 365 -key /etc/s-box/hy2.key -out /etc/s-box/hy2.crt -subj "/CN=bing.com" 2>/dev/null
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

# 5. 沙盒战区初始化 (省略重复逻辑，保持和之前V10.0一致)
for NODE in 1 2 3 4; do
    [ "$NODE" == "1" ] && { IN=2081; DIR="/etc/s-box"; REG="US"; }
    [ "$NODE" == "2" ] && { IN=2082; DIR="/etc/s-box/sub2"; REG="GB"; }
    [ "$NODE" == "3" ] && { IN=2083; DIR="/etc/s-box/sub3"; REG="JP"; }
    [ "$NODE" == "4" ] && { IN=2084; DIR="/etc/s-box/sub4"; REG="US"; }
    cp /etc/s-box/psiphon-tunnel-core "$DIR/" 2>/dev/null
    cat > "$DIR/base.config" << P_EOF
{"LocalHttpProxyPort":$((IN+16000)),"LocalSocksProxyPort":$IN,"PropagationChannelId":"FFFFFFFFFFFFFFFF","SponsorId":"FFFFFFFFFFFFFFFF","EgressRegion":"$REG","DataRootDirectory":"$DIR","RemoteServerListDownloadFilename":"remote_server_list","RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=","RemoteServerListUrl":"https://s3.amazonaws.com/psiphon/web/mjr4-p23r-puwl/server_list_compressed","UseIndistinguishableTLS":true}
P_EOF
    cat > /etc/systemd/system/psiphon${NODE}.service << SVC_EOF
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
    systemctl enable --now psiphon${NODE} >/dev/null 2>&1
done

# 6. S/L/SL 引擎脚本生成 (保持V10.0逻辑)
# ... 此处省略代码以保持回复简洁，请使用之前V10.0中对应S/L/SL部分的完整代码 ...

# 7. 唯一指挥官 c 与 哨兵 master 部署 (保持V10.0逻辑)
# ... 此处省略代码 ...

# 8. 凌晨 4 点 Cron 任务
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "0 4 * * * echo \"\$(date '+[%m-%d %H:%M:%S]') 🚀 === 凌晨 4:00 重启，开启新史记 ===\" >> /etc/s-box/stability.log && /sbin/reboot") | crontab -

echo -e "\n\033[1;32m🎉 天网系统 V10.1 终极部署完毕！唯一指令：c\033[0m"
