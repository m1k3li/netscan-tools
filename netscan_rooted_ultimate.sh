#!/data/data/com.termux/files/usr/bin/bash
# 先 pkg install arp-scan dnsutils
echo "===== NETSCAN ULTIMATE ====="

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
# ===== 取得 interface =====
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# ===== 取得 IP / subnet =====
IP_INFO=$(ip -4 addr show $IFACE | grep inet | awk '{print $2}' | head -n1)
IP=$(echo $IP_INFO | cut -d/ -f1)
BASE=$(echo $IP | cut -d. -f1-3)
SUBNET="${BASE}.0/24"

# ===== Gateway =====
GW=$(ip route | grep default | awk '{print $3}')

echo "[+] Interface: $IFACE"
echo "[+] Subnet: $SUBNET"
echo "[+] Gateway: $GW"
echo ""

# ===== 問輸出格式 =====
echo "Output format:"
echo "1) table"
echo "2) json"
read -p "Select [1]: " FORMAT

[ "$FORMAT" = "2" ] && OUTPUT="json" || OUTPUT="table"

echo ""
echo "[+] Scanning network..."
echo ""

RESULTS=""

# ===== ARP 掃描 =====
arp-scan --interface=$IFACE --localnet | grep -v "packets" | while read line; do

  IP_ADDR=$(echo $line | awk '{print $1}')
  MAC=$(echo $line | awk '{print $2}')
  VENDOR=$(echo $line | cut -d" " -f3-)

  # ===== hostname =====
  HOST=$(nslookup $IP_ADDR 2>/dev/null | awk -F'= ' '/name =/{print $2}' | sed 's/\.$//')

  # ===== 類型判斷 =====
  TYPE="Unknown"
  echo "$VENDOR" | grep -qi "cisco\|huawei\|juniper\|mikrotik" && TYPE="Network Device"
  echo "$VENDOR" | grep -qi "apple\|samsung\|xiaomi\|oppo" && TYPE="Phone"
  echo "$VENDOR" | grep -qi "intel\|dell\|hp\|lenovo" && TYPE="Computer"
  echo "$VENDOR" | grep -qi "epson\|canon\|brother" && TYPE="Printer"
  echo "$VENDOR" | grep -qi "tp-link\|netgear\|asus" && TYPE="Router/AP"

  # ===== 標記 gateway =====
  FLAG=""
  [ "$IP_ADDR" = "$GW" ] && FLAG="<< GATEWAY >>"

  if [ "$OUTPUT" = "json" ]; then
    echo "{"
    echo "  \"ip\": \"$IP_ADDR\","
    echo "  \"mac\": \"$MAC\","
    echo "  \"vendor\": \"$VENDOR\","
    echo "  \"hostname\": \"$HOST\","
    echo "  \"type\": \"$TYPE\","
    echo "  \"flag\": \"$FLAG\""
    echo "},"
  else
    printf "%-15s %-17s %-20s %-20s [%s] %s\n" \
      "$IP_ADDR" "$MAC" "$VENDOR" "$HOST" "$TYPE" "$FLAG"
  fi

done

echo ""
echo "===== DONE ====="