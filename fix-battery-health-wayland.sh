#!/bin/bash

USER_NAME=$(whoami)

PKLA_DIR="/etc/polkit-1/localauthority/50-local.d"
PKLA_FILE="$PKLA_DIR/org.battery.health.policy.pkla"

sudo mkdir -p "$PKLA_DIR"

sudo tee "$PKLA_FILE" > /dev/null <<EOF
[Allow Battery Health Charging]
Identity=unix-user:$USER_NAME
Action=org.battery.healthcharging.set
ResultActive=yes
EOF

echo "Gotowe. Plik polityki zostal zapisany do:"
echo "   $PKLA_FILE"
echo "Zrestartuj komputer lub wyloguj sie i zaloguj ponownie, aby zmiany zadzialaly."
