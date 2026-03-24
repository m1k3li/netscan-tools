#!/data/data/com.termux/files/usr/bin/bash

echo "===== NETSCAN (ROOT+VENDOR) ====="

# ===== root 檢查 =====
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Switching to root..."
  exec su -c "$0 $@"
fi

# ===== 抓 interface =====
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
IP_INFO=$(ip -4 addr show $IFACE | grep inet | awk '{print $2}' | head -n1)

IP=$(echo $IP_INFO | cut -d/ -f1)
BASE=$(echo $IP | cut -d. -f1-3)
SUBNET="${BASE}.0/24"

echo "[+] Interface: $IFACE"
echo "[+] Subnet: $SUBNET"
echo ""

echo "[+] Running arp-scan..."
echo ""

arp-scan --interface=$IFACE --localnet | grep -v "packets" | while read line; do
  
  IP_ADDR=$(echo $line | awk '{print $1}')
  MAC=$(echo $line | awk '{print $2}')
  VENDOR=$(echo $line | cut -d" " -f3-)

  # ===== 裝置類型判斷（簡單 heuristic）=====
  TYPE="Unknown"

  echo "$VENDOR" | grep -qi "cisco\|huawei\|juniper\|mikrotik" && TYPE="Network Device"
  echo "$VENDOR" | grep -qi "apple\|samsung\|xiaomi\|oppo" && TYPE="Phone"
  echo "$VENDOR" | grep -qi "intel\|dell\|hp\|lenovo" && TYPE="Computer"
  echo "$VENDOR" | grep -qi "epson\|canon\|brother" && TYPE="Printer"
  echo "$VENDOR" | grep -qi "tp-link\|netgear\|asus" && TYPE="Router/AP"

  printf "%-15s  %-17s  %-25s  [%s]\n" "$IP_ADDR" "$MAC" "$VENDOR" "$TYPE"

done

echo ""
echo "===== DONE ====="