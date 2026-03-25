#!/data/data/com.termux/files/usr/bin/bash
# 要先 pkg install curl nmap dnsutils inetutils
# ===== 基本設定 =====
DEFAULT_SUBNET="192.168.1.0/24"

if [ -n "$1" ]; then
    SUBNET="$1"
else
    read -p "Enter subnet [${DEFAULT_SUBNET}]: " USER_SUBNET
    SUBNET=${USER_SUBNET:-$DEFAULT_SUBNET}
fi
echo "===== NETSCAN START ====="

# 1. 外網 IP
echo "[+] External IP:"
curl -s ifconfig.me
echo -e "\n"

# 2. Gateway（用 route workaround）
echo "[+] Gateway:"
GW=$(ip route 2>/dev/null | grep default | awk '{print $3}')
if [ -z "$GW" ]; then
  echo "Cannot detect (Android blocked netlink, surprise surprise)"
else
  echo "$GW"
fi
echo ""

# 3. DNS 測試
echo "[+] DNS Test:"
dig +short google.com | head -n 1
echo ""

# 4. Ping 測試
echo "[+] Ping 8.8.8.8:"
ping -c 2 8.8.8.8
echo ""

# 5. Traceroute
echo "[+] Traceroute (8.8.8.8):"
traceroute -m 5 8.8.8.8
echo ""

# 6. Subnet 掃描（TCP connect scan）
echo "[+] Scanning subnet: $SUBNET"
nmap -sn -n $SUBNET
echo ""

# 7. 常用 port 掃描（快速）
echo "[+] Quick port scan (22,80,443):"
nmap -sT -p 22,80,443 $SUBNET
echo ""

echo "===== NETSCAN END ====="