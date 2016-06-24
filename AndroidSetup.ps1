Import-Module BitsTransfer

$AndroidSDKUri = "https://dl.google.com/android/android-sdk_r24.4.1-windows.zip"
$AndroidZip = "C:\prereq\AndroidSDK.zip"
Start-BitsTransfer -Source $AndroidSDKUri -Destination $AndroidZip -Authentication Basic
$Env:ANDROID_HOME = "C:\Program Files (x86)\Android\android-sdk\"
$Android_Root = "C:\Program Files (x86)\Android\"
if (-Not [System.IO.Directory]::Exists($Env:ANDROID_HOME)) {Write-output "Making Android Home directory "; md $Env:ANDROID_HOME}
[System.IO.Compression.ZipFile]::ExtractToDirectory($AndroidZip, $Android_Root)
#Rename to match Visual Studio
ren "C:\Program Files (x86)\Android\android-sdk-windows" $Env:ANDROID_HOME
#download Eula Acceptor
Start-BitsTransfer -Source "https://github.com/bagonaut/Scripts/raw/master/pressy.exe" -Destination "C:\prereq\pressy.exe"
#Environment vars in machine for Future use
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $Env:Android_Home, [System.EnvironmentVariableTarget]::Machine)
$PathVar = [System.String]::concat("$Env:Path;", "$Env:Android_Home\Tools;", "$Env:ANDROID_HOME\platform-tools;") 
$Env:Path = $PathVar 
[Environment]::SetEnvironmentVariable("Path", $Env:Path, [System.EnvironmentVariableTarget]::Machine)
#xcopy /E /Y C:\prereq\AndroidSDK\android-sdk-windows\platforms 'C:\Program Files (x86)\Android\android-sdk\platforms'
C:\prereq\pressy.exe # Accept Eulas
android.bat update sdk -u
