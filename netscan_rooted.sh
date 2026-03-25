#!/data/data/com.termux/files/usr/bin/bash

# ==== TERMUX / ROOT FRIENDLY INIT ====
TERMUX_PREFIX="/data/data/com.termux/files/usr"
export PATH="$TERMUX_PREFIX/bin:$PATH"

# 嘗試 root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Not running as root. Trying with su..."
    if command -v su >/dev/null 2>&1; then
        exec su -c "$0 $*"  # 重新用 su 執行整個 script
    else
        echo "[!] su not found. Continuing without root..."
    fi
fi

echo "===== NETSCAN ULTIMATE (ROOT MODE) ====="

# ==== 偵測網路介面 ====
INTERFACE=$(ip route | grep '^default' | awk '{print $5}')
INTERFACE=${INTERFACE:-wlan0}
echo "[+] Interface: $INTERFACE"

# ==== 偵測本地 IP ====
LOCAL_IP=$(ip addr show $INTERFACE | grep -oP 'inet \K[\d.]+')
echo "[+] Local IP: $LOCAL_IP"

# ==== 嘗試抓 Gateway ====
GATEWAY=$(ip route | grep default | awk '{print $3}')
echo "[+] Gateway: $GATEWAY"

# ==== 外部 IP ====
EXTERNAL_IP="N/A"
if command -v curl >/dev/null 2>&1; then
    EXTERNAL_IP=$(curl -s ifconfig.me)
fi
echo "[+] External IP: $EXTERNAL_IP"

# ==== DNS ====
DNS="N/A"
if command -v dig >/dev/null 2>&1; then
    DNS=$(dig +short @1.1.1.1 google.com | head -n1)
fi
echo "[+] DNS: $DNS"

# ==== 使用者輸入 subnet ====
read -p "Enter subnet [192.168.101.0/24]: " SUBNET
SUBNET=${SUBNET:-192.168.101.0/24}

# ==== 選擇模式 ====
echo "Select mode:"
echo "1) quick  (arp + ping)"
echo "2) deep   (SYN scan)"
echo "3) web    (80/443 SYN)"
echo "4) live   (clean list)"
echo "5) sniff  (tcpdump)"
read -p "Enter choice [1]: " MODE
MODE=${MODE:-1}

echo "===== RUNNING mode $MODE ====="

# ==== 模式執行函式 ====
run_quick() {
    echo "[+] Quick scan on $SUBNET"
    if command -v arp-scan >/dev/null 2>&1; then
        arp-scan --localnet
    else
        echo "[!] arp-scan not found"
    fi
    ping -c 2 $SUBNET
}

run_deep() {
    echo "[+] Deep scan on $SUBNET"
    if command -v nmap >/dev/null 2>&1; then
        nmap -sS -T4 $SUBNET
    else
        echo "[!] nmap not found"
    fi
}

run_web() {
    echo "[+] Web scan on $SUBNET (ports 80/443)"
    if command -v nmap >/dev/null 2>&1; then
        nmap -p 80,443 -sS -T4 $SUBNET
    else
        echo "[!] nmap not found"
    fi
}

run_live() {
    echo "[+] Live hosts on $SUBNET"
    if command -v ping >/dev/null 2>&1; then
        fping -a -g $SUBNET 2>/dev/null
    else
        echo "[!] ping/fping not found"
    fi
}

run_sniff() {
    echo "[+] Sniffing traffic (tcpdump)"
    if command -v tcpdump >/dev/null 2>&1; then
        tcpdump -i $INTERFACE -c 50
    else
        echo "[!] tcpdump not found"
    fi
}

# ==== 執行選擇模式 ====
case $MODE in
    1) run_quick ;;
    2) run_deep ;;
    3) run_web ;;
    4) run_live ;;
    5) run_sniff ;;
    *) echo "[!] Invalid choice" ;;
esac

echo "===== DONE ====="