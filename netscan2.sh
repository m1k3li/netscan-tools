#!/data/data/com.termux/files/usr/bin/bash
# alias netscan="~/netscan.sh"
DEFAULT_SUBNET="192.168.1.0/24"

echo "===== NETSCAN ====="

# ===== 問 subnet =====
read -p "Enter subnet [${DEFAULT_SUBNET}]: " USER_SUBNET
SUBNET=${USER_SUBNET:-$DEFAULT_SUBNET}

echo ""
echo "Select mode:"
echo "1) quick  (host discovery)"
echo "2) deep   (top ports)"
echo "3) web    (80/443)"
echo "4) live   (clean host list)"
read -p "Enter choice [1]: " MODE_INPUT

case $MODE_INPUT in
  2) MODE="deep" ;;
  3) MODE="web" ;;
  4) MODE="live" ;;
  *) MODE="quick" ;;
esac

echo ""
echo "===== RUNNING ($MODE) ====="
echo "Subnet: $SUBNET"
echo ""

# ===== 基本資訊 =====
echo "[+] External IP:"
curl -s ifconfig.me
echo -e "\n"

echo "[+] DNS Test:"
dig +short google.com | head -n 1
echo ""

echo "[+] Ping 8.8.8.8:"
ping -c 2 8.8.8.8
echo ""

# ===== 模式 =====

if [ "$MODE" = "quick" ]; then
  echo "[+] Host discovery"
  nmap -sn -n $SUBNET

elif [ "$MODE" = "deep" ]; then
  echo "[+] Top ports scan"
  nmap -sT --top-ports 50 $SUBNET

elif [ "$MODE" = "web" ]; then
  echo "[+] Web scan (80,443)"
  nmap -sT -p 80,443 $SUBNET

elif [ "$MODE" = "live" ]; then
  echo "[+] Live hosts (clean list)"

  nmap -sn -n $SUBNET | awk '/Nmap scan report/{print $NF}' | while read ip; do
    name=$(nslookup $ip 2>/dev/null | awk -F'= ' '/name =/{print $2}' | sed 's/\.$//')
    if [ -z "$name" ]; then
      echo "$ip"
    else
      echo "$ip ($name)"
    fi
  done

fi

echo ""
echo "===== DONE ====="