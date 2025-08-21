# Run manually (not a valid complete bash script)

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/adguard-cli.service << 'EOF'
[Unit]
Description=AdGuard CLI (user)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/adguard-cli start --no-fork
ExecStop=/usr/local/bin/adguard-cli stop
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now adguard-cli.service
# optional so it stays running without a GUI session:
loginctl enable-linger "$USER"
