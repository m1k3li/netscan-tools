#!/data/data/com.termux/files/usr/bin/bash

# ==== 環境變數初始化 ====
TERMUX_PREFIX="/data/data/com.termux/files/usr"
export PATH="$TERMUX_PREFIX/bin:/system/bin:/system/xbin:$PATH"

echo "===== NETSCAN ULTIMATE ====="

# ==== ROOT 檢查與切換 ====
if [[ $EUID -ne 0 ]]; then
    echo "[!] Not running as root. Trying with su..."
    # 使用 -mm 保持 mount namespace，並手動傳遞 PATH
    exec su -mm -c "PATH=$PATH $0 $*"
    exit $?
fi

echo "===== NETSCAN ULTIMATE (ROOT MODE) ====="

# ===== 取得作用中的 Interface =====
# 優先找 default route，找不到就找第一個非 loopback 的介面
IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$IFACE" ]; then
    IFACE=$(ip link show | grep "state UP" | awk '{print $2}' | tr -d ':' | grep -v "lo" | head -n1)
fi

# 如果還是抓不到就報錯
if [ -z "$IFACE" ]; then
    echo "[-] Error: Could not find an active network interface."
    exit 1
fi

# ===== 取得 IP / Subnet =====
IP_INFO=$(ip -4 addr show "$IFACE" | grep inet | awk '{print $2}' | head -n1)
if [ -z "$IP_INFO" ]; then
    echo "[-] Error: Could not get IP address for $IFACE"
    exit 1
fi

IP=$(echo "$IP_INFO" | cut -d/ -f1)
# 自動計算 Subnet (支援不同遮罩，不限於 /24)
SUBNET=$(ip route | grep "$IFACE" | grep "proto kernel" | awk '{print $1}' | head -n1)
GW=$(ip route | grep default | grep "$IFACE" | awk '{print $3}' | head -n1)

echo "[+] Interface: $IFACE"
echo "[+] IP Address: $IP"
echo "[+] Subnet:    $SUBNET"
echo "[+] Gateway:   $GW"
echo "---------------------------------------"

# ===== 選擇輸出格式 =====
echo "Output format:"
echo "1) table (default)"
echo "2) json"
read -p "Select [1-2]: " FORMAT_CHOICE

[ "$FORMAT_CHOICE" = "2" ] && OUTPUT="json" || OUTPUT="table"

echo ""
echo "[+] Scanning network with arp-scan..."
echo ""

# ===== 掃描與輸出 =====
if [ "$OUTPUT" = "json" ]; then echo "["; fi

# 執行 arp-scan
# 注意：Android 上有時需要明確指定 --localnet 或直接給 Subnet
arp-scan --interface="$IFACE" "$SUBNET" | grep -E '([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}' | while read line; do

    IP_ADDR=$(echo "$line" | awk '{print $1}')
    MAC=$(echo "$line" | awk '{print $2}')
    VENDOR=$(echo "$line" | cut -f3-)

    # 嘗試反查 Hostname
    HOST=$(nslookup "$IP_ADDR" 8.8.8.8 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
    [ -z "$HOST" ] && HOST="unknown"

    # 類型判斷 (簡單邏輯)
    TYPE="Device"
    L_VENDOR=$(echo "$VENDOR" | tr '[:upper:]' '[:lower:]')
    [[ "$L_VENDOR" =~ (cisco|huawei|juniper|mikrotik) ]] && TYPE="Network"
    [[ "$L_VENDOR" =~ (apple|samsung|xiaomi|oppo|vivo|huawei) ]] && TYPE="Phone"
    [[ "$L_VENDOR" =~ (intel|dell|hp|lenovo|asus|gigabyte) ]] && TYPE="PC"
    [[ "$L_VENDOR" =~ (epson|canon|brother|hp) ]] && TYPE="Printer"
    [[ "$L_VENDOR" =~ (tp-link|netgear|asus|d-link) ]] && TYPE="Router"

    FLAG=""
    [ "$IP_ADDR" = "$GW" ] && FLAG="<GATEWAY>"

    if [ "$OUTPUT" = "json" ]; then
        cat <<EOF
  {
    "ip": "$IP_ADDR",
    "mac": "$MAC",
    "vendor": "$VENDOR",
    "hostname": "$HOST",
    "type": "$TYPE",
    "is_gateway": "$( [[ "$FLAG" == "" ]] && echo "false" || echo "true" )"
  },
EOF
    else
        printf "%-15s %-17s %-15s %-15s %s\n" "$IP_ADDR" "$MAC" "$TYPE" "$HOST" "$FLAG"
    fi
done

if [ "$OUTPUT" = "json" ]; then echo "{}]"; fi

echo ""
echo "===== SCAN COMPLETE ====="