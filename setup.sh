#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 開始設定 Termux 網管環境..."

# 1. 修正 Git 設定
echo "[+] 設定 Git 忽略檔案權限變更 (避免 chmod 導致 pull 失敗)..."
git config core.fileMode false

# 2. 修正 .gitignore (如果檔案已存在則備份)
echo "[+] 優化 .gitignore 內容..."
[ -f .gitignore ] && mv .gitignore .gitignore.bak
cat <<EOF > .gitignore
*.log
*.tmp
*.bak
*.swp
node_modules/
__pycache__/
.DS_Store
EOF

# 3. 檢查並安裝必要套件
echo "[+] 檢查必要套件 (arp-scan, dnsutils, iproute2)..."
pkg update -y
packages=("arp-scan" "dnsutils" "iproute2" "grep" "gawk" "nmap")

for pkg in "${packages[@]}"; do
    if ! command -v $pkg &> /dev/null; then
        echo "  - 安裝 $pkg..."
        pkg install -y $pkg
    else
        echo "  - $pkg 已安裝"
    fi
done

echo "---------------------------------------"
echo "✅ 設定完成！"
echo "💡 現在你可以順暢地 git pull，並執行你的掃描腳本了。"
