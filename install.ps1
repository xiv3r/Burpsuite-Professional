Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Set download progress to silent, because it can slow downloads significantly.
echo "Setting download progress to silent.`n"
$ProgressPreference = 'SilentlyContinue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = (Get-Location).Path
}
Set-Location $ScriptDir

function Download-File {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile
    )

    $TempFile = "$OutFile.part"
    if (Test-Path $TempFile) {
        Remove-Item $TempFile -Force
    }

    Invoke-WebRequest -Uri $Uri -OutFile $TempFile
    if (!(Test-Path $TempFile) -or ((Get-Item $TempFile).Length -eq 0)) {
        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
        throw "Downloaded file is empty: $OutFile"
    }

    Move-Item $TempFile $OutFile -Force
}

# Check JDK-21 Availability or Download JDK-21
$jdk21 = Get-CimInstance -ClassName Win32_Product -Filter "Vendor='Oracle Corporation'" | Where-Object Caption -CLike "Java(TM) SE Development Kit 21*"
if (!($jdk21)){
    echo "`t`tDownloading Java JDK-21 ...."
    Download-File "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe" "jdk-21.exe"
    echo "`n`t`tJDK-21 Downloaded, lets start the Installation process"
    Start-Process -FilePath ".\jdk-21.exe" -Wait
    Remove-Item jdk-21.exe -Force
}else{
    echo "Required JDK-21 is Installed"
    $jdk21
}

# Check JRE-8 Availability or Download JRE-8
$jre8 = Get-CimInstance -ClassName Win32_Product -Filter "Vendor='Oracle Corporation'" | Where-Object Caption -CLike "Java 8 Update *"
if (!($jre8)){
    echo "`n`t`tDownloading Java JRE ...."
    Download-File "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550" "jre-8.exe"
    echo "`n`t`tJRE-8 Downloaded, lets start the Installation process"
    Start-Process -FilePath ".\jre-8.exe" -Wait
    Remove-Item jre-8.exe -Force
}else{
    echo "`n`nRequired JRE-8 is Installed`n"
    $jre8
}

# Download Burpsuite Professional
Write-Host "Downloading Burp Suite Professional Latest..."
$BurpFileName = "burpsuite_desktop_latest.jar"
Download-File "https://portswigger.net/burp/releases/download?product=pro&type=Jar" $BurpFileName

# Creating Burp.bat file with command for execution
if (Test-Path burp.bat) { Remove-Item burp.bat -Force }
$BurpJar = Join-Path $ScriptDir $BurpFileName
$LoaderJar = Join-Path $ScriptDir "loader.jar"
$path = "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:`"$LoaderJar`" -noverify -jar `"$BurpJar`""
$path | Set-Content -Path Burp.bat
echo "`nBurp.bat file is created"


# Creating Burp-Suite-Pro.vbs File for background execution
if (Test-Path Burp-Suite-Pro.vbs) {
   Remove-Item Burp-Suite-Pro.vbs -Force}
echo "Set WshShell = CreateObject(`"WScript.Shell`")" > Burp-Suite-Pro.vbs
Add-Content Burp-Suite-Pro.vbs "WshShell.Run chr(34) & `"$ScriptDir\Burp.bat`" & Chr(34), 0"
Add-Content Burp-Suite-Pro.vbs "Set WshShell = Nothing"
echo "`nBurp-Suite-Pro.vbs file is created."

# Download loader if it not exists
if (!(Test-Path loader.jar)){
    echo "`nDownloading Loader ...."
    Download-File "https://github.com/xiv3r/Burpsuite-Professional/raw/refs/heads/main/loader.jar" "loader.jar"
    echo "`nLoader is Downloaded"
}else{
    echo "`nLoader is already Downloaded"
}

# Lets Activate Burp Suite Professional with keygenerator and Keyloader
echo "Reloading Environment Variables ...."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
echo "`n`nStarting Keygenerator ...."
Start-Process java.exe -ArgumentList "-jar `"$LoaderJar`""
echo "`n`nStarting Burp Suite Professional"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED "-javaagent:$LoaderJar" -noverify -jar "$BurpJar"
