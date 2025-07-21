# Set Wget Progress to Silent, Becuase it slows down Downloading by 50x
echo "Setting Wget Progress to Silent, Becuase it slows down Downloading by 50x`n"
$ProgressPreference = 'SilentlyContinue'

# Check JDK-21 Availability or Download JDK-21
$jdk21 = Get-WmiObject -Class Win32_Product -filter "Vendor='Oracle Corporation'" |where Caption -clike "Java(TM) SE Development Kit 21*"
if (!($jdk21)){
    echo "`t`tDownnloading Java JDK-21 ...."
    wget "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe" -O jdk-21.exe  
    echo "`n`t`tJDK-21 Downloaded, lets start the Installation process"
    start -wait jdk-21.exe
    rm jdk-21.exe
}else{
    echo "Required JDK-21 is Installed"
    $jdk21
}

# Check JRE-8 Availability or Download JRE-8
$jre8 = Get-WmiObject -Class Win32_Product -filter "Vendor='Oracle Corporation'" |where Caption -clike "Java 8 Update *"
if (!($jre8)){
    echo "`n`t`tDownloading Java JRE ...."
    wget "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550" -O jre-8.exe
    echo "`n`t`tJRE-8 Downloaded, lets start the Installation process"
    start -wait jre-8.exe
    rm jre-8.exe
}else{
    echo "`n`nRequired JRE-8 is Installed`n"
    $jre8
}

# Download Burpsuite Professional
Write-Host "Downloading Burp Suite Professional Latest..."
$version = "2025"
# Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/download?product=pro&version=$version&type=Jar" `
#   -OutFile "burpsuite_pro_v$version.jar"
Invoke-WebRequest -Uri "https://portswigger.net/burp/releases/download?product=pro&type=Jar" `
  -OutFile "burpsuite_pro_v$version.jar"

# Creating Burp.bat file with command for execution
if (Test-Path burp.bat) {rm burp.bat}
$path = "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:`"$pwd\loader.jar`" -noverify -jar `"$pwd\burpsuite_pro_v$version.jar`""
$path | add-content -path Burp.bat
echo "`nBurp.bat file is created"


# Creating Burp-Suite-Pro.vbs File for background execution
if (Test-Path Burp-Suite-Pro.vbs) {
   Remove-Item Burp-Suite-Pro.vbs}
echo "Set WshShell = CreateObject(`"WScript.Shell`")" > Burp-Suite-Pro.vbs
add-content Burp-Suite-Pro.vbs "WshShell.Run chr(34) & `"$pwd\Burp.bat`" & Chr(34), 0"
add-content Burp-Suite-Pro.vbs "Set WshShell = Nothing"
echo "`nBurp-Suite-Pro.vbs file is created."

# Download loader if it not exists
if (!(Test-Path loader.jar)){
    echo "`nDownloading Loader ...."
    Invoke-WebRequest -Uri "https://github.com/xiv3r/Burpsuite-Professional/raw/refs/heads/main/loader.jar" -OutFile loader.jar
    echo "`nLoader is Downloaded"
}else{
    echo "`nLoader is already Downloaded"
}

# Lets Activate Burp Suite Professional with keygenerator and Keyloader
echo "Reloading Environment Variables ...."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
echo "`n`nStarting Keygenerator ...."
start-process java.exe -argumentlist "-jar loader.jar"
echo "`n`nStarting Burp Suite Professional"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"loader.jar" -noverify -jar "burpsuite_pro_v$version.jar"
