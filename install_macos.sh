#!/usr/bin/env bash
set -euo pipefail

export JAVA_HOME=/opt/homebrew/opt/openjdk@21
export PATH=$JAVA_HOME/bin:$PATH
hash -r

repo_url="https://github.com/xiv3r/Burpsuite-Professional.git"
branch="main"
repo_dir="Burpsuite-Professional"

if [[ "$(basename "$PWD")" == "$repo_dir" ]]; then
    target_dir="$PWD"
else
    target_dir="$PWD/$repo_dir"
fi

mkdir -p "$target_dir"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Pulling repository..."
git clone --quiet --depth 1 --filter=blob:none --no-checkout "$repo_url" --branch "$branch" "$tmp_dir/src"
git -C "$tmp_dir/src" checkout -q HEAD -- . ':(exclude)Launcher.jpg' 2>/dev/null

printf 'tmp_dir=%q\n' "$tmp_dir"
printf 'target_dir=%q\n' "$target_dir"
ls -ld "$tmp_dir/src" "$target_dir"

rsync -a --delete --exclude='.git' "$tmp_dir/src/" "$target_dir/"
  
cd "$target_dir"


# Download Burpsuite Professional
echo "Downloading Burp Suite Professional Latest..."
version=2026
url="https://portswigger.net/burp/releases/download?product=pro&type=Jar"
curl -fL "$url" -o "burpsuite_pro_v${version}.jar"

# Execute Key Generator and Burp Suite Simultaneously
echo "Starting Key loader.jar and Burp Suite Professional..."
(java -jar "$target_dir/loader.jar") &
sleep 2  # Brief delay to ensure loader.jar starts first
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:"$target_dir/loader.jar" \
     -noverify \
     -jar "burpsuite_pro_v${version}.jar" &


echo "Creating burpsuitepro shortcut..."
cat << EOF > burp
#!/bin/bash
echo "Executing Burp Suite Professional..."
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
     --add-opens=java.base/java.lang=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
     --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
     -javaagent:$target_dir/loader.jar \
     -noverify \
     -jar $target_dir/burpsuite_pro_v${version}.jar &
EOF

chmod +x burp

#app bundle
app_name="Burp Suite Professional"
app_dest="$HOME/Applications"
app_bundle="${app_dest}/${app_name}.app"

rm -rf "$app_bundle"

if pgrep -f "Burp Suite Professional" >/dev/null 2>&1; then
    echo "Burp Suite Professional appears to be running. Close it first."
    exit 1
fi

rm -rf "$app_bundle"

echo "Creating burpsuitepro app bundle..."
jpackage --name "$app_name" \
  --input "$target_dir" \
  --main-jar "burpsuite_pro_v${version}.jar" \
  --type app-image \
  --icon "$target_dir/burp_suite.icns" \
  --dest "${app_dest}/" \
  --java-options "--add-opens=java.desktop/javax.swing=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/java.lang=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED" \
  --java-options "-javaagent:$target_dir/loader.jar" \
  --java-options "-noverify"
  
echo "Done"
