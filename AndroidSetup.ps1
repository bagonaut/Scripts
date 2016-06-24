
Import-Module BitsTransfer

$AndroidSDKUri = "https://dl.google.com/android/android-sdk_r24.4.1-windows.zip"
$AndroidZip = "C:\prereq\AndroidSDK.zip"
Start-BitsTransfer -Source $AndroidSDKUri -Destination $AndroidZip -Authentication Basic
[System.IO.Compression.ZipFile]::ExtractToDirectory($AndroidZip, [System.IO.Path]::GetDirectoryName($AndroidZip) + "\AndroidSDK")

Start-BitsTransfer -Source "https://github.com/bagonaut/Scripts/raw/master/pressy.exe" -Destination "C:\prereq\pressy.exe"

$Env:Android_Home = "C:\Prereq\AndroidSDK\android-sdk-windows\"
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $Env:Android_Home, [System.EnvironmentVariableTarget]::Machine)
$PathVar = [System.String]::concat("$Env:Path;", "$Env:Android_Home\Tools;", "$Env:ANDROID_HOME\platform-tools;") 
$Env:Path = $PathVar 
[Environment]::SetEnvironmentVariable("Path", $Env:Path, [System.EnvironmentVariableTarget]::Machine)

C:\prereq\pressy.exe # Accept Eulas
C:\prereq\AndroidSDK\android-sdk-windows\tools\android.bat update sdk -u
