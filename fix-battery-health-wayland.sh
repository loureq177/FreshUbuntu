#!/bin/bash

# Automatyczne wykrycie nazwy użytkownika
USER_NAME=$(whoami)

# Ścieżka do katalogu i pliku polityki
PKLA_DIR="/etc/polkit-1/localauthority/50-local.d"
PKLA_FILE="$PKLA_DIR/org.battery.health.policy.pkla"

# Tworzenie katalogu, jeśli nie istnieje
sudo mkdir -p "$PKLA_DIR"

# Tworzenie pliku z odpowiednią polityką
sudo tee "$PKLA_FILE" > /dev/null <<EOF
[Allow Battery Health Charging]
Identity=unix-user:$USER_NAME
Action=org.battery.healthcharging.set
ResultActive=yes
EOF

echo "✅ Gotowe. Plik polityki został zapisany do:"
echo "   $PKLA_FILE"
echo "🔄 Zrestartuj komputer lub wyloguj się i zaloguj ponownie, aby zmiany zadziałały."
