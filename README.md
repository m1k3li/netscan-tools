cat > README.md << 'EOF'
# Netscan Tools

A collection of network scanning tools designed for Termux / Linux environments.

## Scripts

### netscan.sh
- Non-root version
- Works on restricted Android (Termux)
- Uses nmap TCP connect scan

### netscan-root.sh
- Requires root
- Uses ip / ARP / SYN scan

### netscan-ultimate.sh
- Full network inventory
- ARP scan + vendor + hostname
- JSON / table output

## Usage

```bash
chmod +x *.sh
./netscan.sh
```
## Requirements

- nmap
- arp-scan (root version)
- dnsutils
- curl

## Notes
Some features require root
Designed for quick network troubleshooting

EOF
#a test for git update.
