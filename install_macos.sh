#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/xiv3r/Burpsuite-Professional.git"
REPO_DIR="Burpsuite-Professional"
url="https://portswigger.net/burp/releases/download?product=pro&type=Jar"
burp_jar="burpsuite_desktop_latest.jar"

if [ -f "loader.jar" ]; then
  repo_dir="$(pwd)"
elif [ -d "$REPO_DIR/.git" ]; then
  repo_dir="$REPO_DIR"
else
  git clone "$REPO_URL" "$REPO_DIR"
  repo_dir="$REPO_DIR"
fi

cd "$repo_dir"


# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
tmp_jar="${burp_jar}.part"
rm -f "$tmp_jar"
curl -fL "$url" -o "$tmp_jar"
if [ ! -s "$tmp_jar" ]; then
  echo "Error: Downloaded file is empty." >&2
  rm -f "$tmp_jar"
  exit 1
fi
mv "$tmp_jar" "$burp_jar"

# Execute Key Generator and Burp Suite Simultaneously
echo "Starting Key loader.jar and Burp Suite Professional..."
(java -jar "loader.jar") &
sleep 2  # Brief delay to ensure loader.jar starts first
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:"$(pwd)/loader.jar" \
     -noverify \
     -jar "$(pwd)/$burp_jar" &


echo "Creating burpsuitepro shortcut..."
cat << 'EOF' > burp
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Executing Burp Suite Professional..."
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:"${SCRIPT_DIR}/loader.jar" \
     -noverify \
     -jar "${SCRIPT_DIR}/burpsuite_desktop_latest.jar" &
EOF
chmod +x burp

#app bundle
echo "Creating burpsuitepro app bundle..."
jpackage --name "Burp Suite Professional" \
  --input "$(pwd)" \
  --main-jar "$burp_jar" \
  --type app-image \
  --icon "$(pwd)/burp_suite.icns" \
  --dest ~/Applications/ \
  --java-options "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/java.lang=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED" \
  --java-options "-javaagent:$(pwd)/loader.jar" \
  --java-options "-noverify"
