# Set Wget Progress to Silent, Becuase it slows down Downloading by 50x
echo "Setting Wget Progress to Silent, Becuase it slows down Downloading by 50x`n"
$ProgressPreference = 'SilentlyContinue'
# Hash helpers for locally downloaded Oracle installers
function Read-NormalizedHash {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -Path $Path)) { throw "Hash file not found: $Path" }
    return (Get-Content -Raw -Path $Path).Trim().ToLower()
}

function Confirm-FileHash {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedSha256
    )
    if (-not (Test-Path -Path $Path)) { throw "File not found for hash check: $Path" }
    $actual = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $ExpectedSha256) {
        throw "SHA-256 mismatch for $Path. Expected $ExpectedSha256, got $actual."
    }
    Write-Host "SHA-256 verified for $Path"
}


# Check JDK-21 Availability or Download JDK-21
$UninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$Jdk21 = $UninstallPaths | ForEach-Object {
    Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | ForEach-Object {
        $Props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        if ($Props.DisplayName -like 'Java(TM) SE Development Kit 21*') {
            $Props
        }
    }
} | Select-Object -First 1

if (!($Jdk21)) {
    echo "`t`tDownloading Java JDK-21 ...."
    wget "https://download.oracle.com/java/21/archive/jdk-21_windows-x64_bin.exe" -O jdk-21.exe
    Confirm-FileHash -Path 'jdk-21.exe' -ExpectedSha256 (Read-NormalizedHash -Path 'JDK21_SHA256')
    echo "`n`t`tJDK-21 Downloaded, lets start the Installation process"
    start -wait jdk-21.exe
    rm jdk-21.exe
} else {
    echo "Required JDK-21 is Installed"
    $Jdk21
}

# Check JRE-8 Availability or Download JRE-8
$Jre8 = $UninstallPaths | ForEach-Object {
    Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | ForEach-Object {
        $Props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        if ($Props.DisplayName -like 'Java 8 Update *') {
            $Props
        }
    }
} | Select-Object -First 1

if (!($Jre8)) {
    echo "`n`t`tDownloading Java JRE ...."
    wget "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=247947_0ae14417abb444ebb02b9815e2103550" -O jre-8.exe
    Confirm-FileHash -Path 'jre-8.exe' -ExpectedSha256 (Read-NormalizedHash -Path 'JRE8_SHA256')
    echo "`n`t`tJRE-8 Downloaded, lets start the Installation process"
    start -wait jre-8.exe
    rm jre-8.exe
} else {
    echo "`n`nRequired JRE-8 is Installed`n"
    $Jre8
}

# Download Burpsuite Professional
Write-Host "Downloading Burp Suite Professional Latest..."
$Version = if ($PSScriptRoot) { (Get-Content -Raw -Path (Join-Path $PSScriptRoot 'VERSION')).Trim() } else { (Get-Content -Raw -Path 'VERSION').Trim() }
$ExpectedSha256 = if ($PSScriptRoot) {
    (Get-Content -Raw -Path (Join-Path $PSScriptRoot 'BURP_SHA256')).Trim()
} else {
    (Get-Content -Raw -Path 'BURP_SHA256').Trim()
}

$JarFile = "burpsuite_pro_v$Version.jar"
try {
    Invoke-WebRequest -Uri "https://github.com/xiv3r/Burpsuite-Professional/releases/download/burpsuite-pro/burpsuite_pro_v$Version.jar" `
      -OutFile $JarFile -UseBasicParsing -ErrorAction Stop
} catch {
    throw "Failed to download Burp Suite Professional JAR: $_"
}
$ActualHash = (Get-FileHash -Path $JarFile -Algorithm SHA256).Hash.ToUpper()
if ($ActualHash -ne $ExpectedSha256.ToUpper()) {
    throw "SHA-256 mismatch for $JarFile. Expected $ExpectedSha256, got $ActualHash."
}

# Download loader if it not exists
if (!(Test-Path loader.jar)){
    echo "`nDownloading Loader ...."
    Invoke-WebRequest -Uri "https://github.com/xiv3r/Burpsuite-Professional/raw/refs/heads/main/loader.jar" -OutFile loader.jar -UseBasicParsing -ErrorAction Stop
    echo "`nLoader is Downloaded"
}else{
    echo "`nLoader is already Downloaded"
}

# Verify bundled loader.jar
$ExpectedLoaderSha256 = if ($PSScriptRoot) {
    (Get-Content -Raw -Path (Join-Path $PSScriptRoot 'LOADER_SHA256')).Trim()
} else {
    (Get-Content -Raw -Path 'LOADER_SHA256').Trim()
}
$ActualLoaderHash = (Get-FileHash -Path loader.jar -Algorithm SHA256).Hash.ToUpper()
if ($ActualLoaderHash -ne $ExpectedLoaderSha256.ToUpper()) {
    throw "SHA-256 mismatch for loader.jar. Expected $ExpectedLoaderSha256, got $ActualLoaderHash."
}


# Creating Burp.bat file with command for execution
if (Test-Path burp.bat) {rm burp.bat}
$Path = "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:`"$pwd\loader.jar`" -noverify -jar `"$pwd\burpsuite_pro_v$Version.jar`""
$Path | add-content -path Burp.bat
echo "`nBurp.bat file is created"


# Creating Burp-Suite-Pro.vbs File for background execution
if (Test-Path Burp-Suite-Pro.vbs) {
   Remove-Item Burp-Suite-Pro.vbs}
$BurpBatPath = Join-Path $pwd 'Burp.bat'
echo "Set WshShell = CreateObject(`"WScript.Shell`")" > Burp-Suite-Pro.vbs
add-content Burp-Suite-Pro.vbs "WshShell.Run chr(34) & `"$BurpBatPath`" & Chr(34), 0"
add-content Burp-Suite-Pro.vbs "Set WshShell = Nothing"
echo "`nBurp-Suite-Pro.vbs file is created."

# Lets Activate Burp Suite Professional with keygenerator and Keyloader
echo "Reloading Environment Variables ...."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
echo "`n`nStarting Keygenerator ...."
Start-Process -FilePath java.exe -ArgumentList '-jar', 'loader.jar'
echo "`n`nStarting Burp Suite Professional"
java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:"loader.jar" -noverify -jar "burpsuite_pro_v$Version.jar"
