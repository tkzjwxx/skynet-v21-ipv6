# 🌐 Skynet Matrix V22 / 天网出站矩阵系统 V22

[English](#english) | [简体中文](#chinese)

---

<h2 id="english">🇺🇸 English</h2>

Skynet V22 is a highly advanced, automated proxy matrix tailored for pure IPv6 VPS (like Woiden, Hax). It integrates Cloudflare WARP, Sing-box, and multiple Psiphon nodes into a self-healing ecosystem. 

**🔥 What's New in V22:**
* **Unified Control Center (`tw`)**: All scattered commands are now unified into a single, interactive dashboard.
* **True Physical Hibernation**: Unused channels can be fully disabled (services stopped, systemd disabled, network airlocked) to achieve strictly zero memory/CPU footprint on low-end VPS.
* **Zero-Leakage Airlock**: Dual-track SLA monitoring strictly cuts off local ports if an IP drift is detected, preventing your real IP from leaking to target platforms.

### ⚙️ Traffic Flow & Architecture
* **Inbound (Argo Tunnel -> Sing-box)**: Cloudflare forwards traffic to local VMess ports (`10001`, `10002`, `10003`).
* **Inbound (Direct IPv6)**: Sing-box also listens on `8443`, `8444`, `8445` for raw Hysteria2 direct connections.
* **Outbound Matrix (Sing-box -> Psiphon -> WARP)**: Traffic is routed to 3 independent Psiphon nodes (S1, S2, S3) running locally, which then exit to the internet via the WARP IPv4 network.

### 🚀 Step 1: Install Skynet V22
Run the following chained command as `root` on your pure IPv6 VPS. It will automatically install `curl` if missing, clean up old versions, and start the deployment:

```bash
apt-get update -y && apt-get install -y curl && bash <(curl -sL https://raw.githubusercontent.com/tkzjwxx/skynet-v22-ipv6/main/install.sh)
```
*(⚠️ Note: The script will pause and open the WARP menu. Please install WARP, verify you get an IPv4 address, and type `0` to exit the menu so the installation can complete.)*

### 🌩️ Step 2: Configure Cloudflare Argo Tunnel (CRITICAL)
For the VMess nodes to work, you MUST map the local Sing-box ports to your subdomains using Cloudflare Zero Trust:
1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) -> Networks -> Tunnels.
2. Click Create a tunnel (Select Cloudflared) and name it (e.g., `Skynet`).
3. Copy the installation command provided by CF (`cloudflared service install eyJ...`) and run it in your VPS terminal.
4. Click Next and configure the Public Hostnames (Add 3 routes):
   * Route 1: `us.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10001`
   * Route 2: `uk.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10002`
   * Route 3: `jp.yourdomain.com` -> Service Type: `HTTP` -> URL: `localhost:10003`
5. Save the tunnel.

### ⌨️ Step 3: Global Command - The Unified Dashboard
Skynet V22 has eliminated all cluttered shortcut commands. Simply type the following command anywhere in your terminal to access the central matrix:

* `tw` : **Open the TianWang (Skynet) Master Dashboard**

From this interactive UI, you can:
* Monitor live SLA, IP targets, and airlock status for all 3 zones.
* Enter specific zones (S1/S2/S3) to draw new IPs or force-lock specific ones.
* Toggle **Physical Hibernation** for individual channels or the entire matrix to save RAM.
* Generate your VMess/HY2 node configurations.
* Access the S4 Phantom Bypass for clean IP hunting.
* Execute the self-destruct sequence to purge the system.

---

<h2 id="chinese">🇨🇳 简体中文</h2>

天网系统 V22 是一套专为纯 IPv6 VPS (如 HAX, Woiden) 打造的商业级自动化代理矩阵生态。它通过底层 WARP 获取 IPv4 出口，配合 Sing-box 分流与多路独立的 Psiphon 战区，并强制绑定 Cloudflare Argo Tunnel，实现 IP 绝对防封与节点毫秒级自愈。

**🔥 V22 史诗级核心进化：**
* **大一统总控中台 (`tw`)**：告别繁杂的命令行碎片，所有功能收束于单一可视化交互面板。
* **Systemd 物理级启停阀门**：支持对单通道进行“深度休眠”。一键物理断网、释放全量内存、注销开机自启，实现极致白嫖环境下的“零资源浪费”。
* **防泄露绝对气闸**：双轨 SLA 监控引擎，一旦侦测到 IP 漂移或假死，瞬间物理斩断本地 SOCKS5 气闸，彻底杜绝养号环境下的真实 IP 穿透泄露！

### ⚙️ 核心流量走向
* **入站 (Argo -> Sing-box)**：Cloudflare 边缘节点将流量通过隧道穿透至本机的 `10001`, `10002`, `10003` 端口 (VMess)。同时保留 `8443-8445` 端口供 Hysteria2 原生 IPv6 直连备用。
* **出站 (Sing-box -> Psiphon -> WARP)**：入站流量被分发至本机的 3 个独立 Psiphon 战区引擎 (S1/S2/S3)，最终通过 WARP 的 IPv4 隧道走向外网。

### 🚀 第一步：执行创世部署
请使用 `root` 权限登录纯 IPv6 机器执行以下链式指令（自带环境依赖补全与旧版垃圾清理）：

```bash
apt-get update -y && apt-get install -y curl && bash <(curl -sL https://raw.githubusercontent.com/tkzjwxx/skynet-v22-ipv6/main/install.sh)
```
*(⚠️ 核心提示：执行中途会挂起并唤出【WARP 菜单】。请手动安装 WARP (纯v6机建议装双栈或单栈IPv4)，当屏幕提示成功获取 WARP IPv4 后，输入 `0` 退出菜单，主程序将自动接力完成全量部署！)*

### 🌩️ 第二步：配置 CF Argo 隧道映射 (必做核心步骤)
如果不做这一步，你提取到的 VMess 节点将无法连接！部署完成后，请按照以下步骤打通隧道：
1. 登录 [Cloudflare Zero Trust 后台](https://one.dash.cloudflare.com/)，依次点击左侧菜单的 Networks -> Tunnels。
2. 点击 Create a tunnel（选择 Cloudflared），随便起个名字（如 Skynet）。
3. 选择你的系统环境（Debian/Ubuntu 64-bit），复制页面下方给出的长命令（以 `cloudflared service install eyJ...` 开头），直接粘贴到你的 VPS 终端里运行。
4. 运行成功后点击页面右下角的 Next，来到 Public Hostnames 映射页面。你需要添加 3 条记录：
   * 子域名 1 (接管 S1 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10001`
   * 子域名 2 (接管 S2 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10002`
   * 子域名 3 (接管 S3 战区) -> Service Type 选 `HTTP` -> URL 填 `localhost:10003`
5. 全部添加完成后，保存隧道。此时机器已成功与 Cloudflare 边缘骨干网硬连接！

### ⌨️ 第三步：天网全局指令中台
V22 已经将所有杂乱的快捷键（c, v, s1, l1 等）物理抹除。现在，你只需要记住唯一的一个指令：

* `tw` ： **呼出天网 (TianWang) 矩阵总控台**

在可视化交互面板中，你可以：
* 📊 **监控大盘**：全局双轨 SLA 状态、IP 锁定目标与底层气闸开闭情况一目了然。
* 🎯 **战区管理**：进入 S1/S2/S3 独立战区，进行极品 IP 盲抽或强制狂暴死磕。
* 💤 **物理启停管控**：一键让指定通道或全局进入深度休眠，彻底释放 VPS 内存。
* 🔗 **节点生成**：一键提取你的专属 VMess / HY2 节点配置连接。
* 👻 **幽灵旁路**：启动 S4 幽灵斥候旁路引擎，进行深海 IP 洗号与黑名单绞杀。
* ⚠️ **物理超度**：执行天网自毁回滚程序，清理一切痕迹还你最初纯净。
