#!/data/data/com.termux/files/usr/bin/bash
# pkg install nmap tcpdump dnsutils curl
DEFAULT_IFACE="wlan0"

echo "===== NETSCAN (ROOT MODE) ====="

# ===== 檢查 root =====
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Not running as root. Trying with su..."
  exec su -c "$0 $@"
fi

# ===== 抓 interface =====
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [ -z "$IFACE" ]; then
  IFACE=$DEFAULT_IFACE
fi

echo "[+] Interface: $IFACE"

# ===== 抓 IP & subnet =====
IP_INFO=$(ip -4 addr show $IFACE | grep inet | awk '{print $2}' | head -n1)

IP=$(echo $IP_INFO | cut -d/ -f1)
CIDR=$(echo $IP_INFO | cut -d/ -f2)

if [ -n "$IP" ]; then
  BASE=$(echo $IP | cut -d. -f1-3)
  AUTO_SUBNET="${BASE}.0/24"
else
  AUTO_SUBNET="192.168.1.0/24"
fi

# ===== Gateway =====
GW=$(ip route | grep default | awk '{print $3}')

echo "[+] Local IP: $IP"
echo "[+] Gateway: $GW"
echo ""

# ===== 問 subnet =====
read -p "Enter subnet [${AUTO_SUBNET}]: " USER_SUBNET
SUBNET=${USER_SUBNET:-$AUTO_SUBNET}

echo ""
echo "Select mode:"
echo "1) quick  (arp + ping)"
echo "2) deep   (SYN scan)"
echo "3) web    (80/443 SYN)"
echo "4) live   (clean list)"
echo "5) sniff  (tcpdump)"
read -p "Enter choice [1]: " MODE_INPUT

case $MODE_INPUT in
  2) MODE="deep" ;;
  3) MODE="web" ;;
  4) MODE="live" ;;
  5) MODE="sniff" ;;
  *) MODE="quick" ;;
esac

echo ""
echo "===== RUNNING ($MODE) ====="
echo "Subnet: $SUBNET"
echo ""

# ===== 基本測試 =====
echo "[+] External IP:"
curl -s ifconfig.me
echo -e "\n"

echo "[+] DNS:"
dig +short google.com | head -n1
echo ""

# ===== 模式 =====

if [ "$MODE" = "quick" ]; then
  echo "[+] ARP scan (via ip neigh)"
  ip neigh

  echo ""
  echo "[+] Ping sweep"
  for i in {1..254}; do
    ping -c1 -W1 ${SUBNET%.*}.$i >/dev/null 2>&1 && echo "Alive: ${SUBNET%.*}.$i" &
  done
  wait

elif [ "$MODE" = "deep" ]; then
  echo "[+] SYN scan (fast)"
  nmap -sS --top-ports 100 $SUBNET

elif [ "$MODE" = "web" ]; then
  echo "[+] Web SYN scan"
  nmap -sS -p 80,443 $SUBNET

elif [ "$MODE" = "live" ]; then
  echo "[+] Live hosts (ARP + reverse DNS)"

  ip neigh | awk '{print $1}' | while read ip; do
    name=$(nslookup $ip 2>/dev/null | awk -F'= ' '/name =/{print $2}' | sed 's/\.$//')
    if [ -z "$name" ]; then
      echo "$ip"
    else
      echo "$ip ($name)"
    fi
  done

elif [ "$MODE" = "sniff" ]; then
  echo "[+] tcpdump (Ctrl+C to stop)"
  tcpdump -i $IFACE

fi

echo ""
echo "===== DONE ====="