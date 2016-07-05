# Used to download files. backwards compatible with older version of powershell.
Import-Module BitsTransfer 

# Get Zip Lib.
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') 
$AndroidSDKUri = "https://dl.google.com/android/android-sdk_r24.4.1-windows.zip"
$AndroidZip = "C:\prereq\AndroidSDK.zip"
#begin download
Start-BitsTransfer -Source $AndroidSDKUri -Destination $AndroidZip -Authentication Basic

#set environment variables for this session.
$Env:ANDROID_HOME = "C:\Program Files (x86)\Android\android-sdk\"
$Android_Root = "C:\Program Files (x86)\Android\"

#Create destination and extract
if (-Not [System.IO.Directory]::Exists($Env:ANDROID_HOME)) {Write-output "Making Android Home directory "; md $Env:ANDROID_HOME}
[System.IO.Compression.ZipFile]::ExtractToDirectory($AndroidZip, $Android_Root)

#Rename to match Visual Studio
XCOPY /E /Y "C:\Program Files (x86)\Android\android-sdk-windows"  $Env:ANDROID_HOME

#download Eula Acceptor. Get source code here: https://github.com/bagonaut/Scripts/tree/master/pressy
Start-BitsTransfer -Source "https://github.com/bagonaut/Scripts/raw/master/pressy.exe" -Destination "C:\prereq\pressy.exe"

#Environment vars in machine for use outside of this session by visual studio.
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $Env:Android_Home, [System.EnvironmentVariableTarget]::Machine)
$PathVar = [System.String]::concat("$Env:Path;", "$Env:Android_Home", "Tools;", "$Env:ANDROID_HOME", "platform-tools;") 
$Env:Path = $PathVar 
Write-Output "Setting Path Env" 
[Environment]::SetEnvironmentVariable("Path", $Env:Path, [System.EnvironmentVariableTarget]::Machine)
write-output $env:PATH

# So much hacking to get this Eula Accepted.
#Ensuring that powershell window as invoked from go.ps1 has focus for the pressy hack (code moved to pressy)
$env:androidSetupPStid = [System.AppDomain]::GetCurrentThreadId() # for pressy
[Environment]::SetEnvironmentVariable("androidSetupPStid", $Env:androidSetupPStid, [System.EnvironmentVariableTarget]::Machine)
$env:androidSetupPShwnd = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle # for pressy
[Environment]::SetEnvironmentVariable("androidSetupPShd", $Env:androidSetupPShwnd, [System.EnvironmentVariableTarget]::Machine)
#Eula Acceptor
new-alias -name y -value "out-null" -Force -Scope Global #squelch extra y
y
# Start accepting EULAS
C:\prereq\pressy.exe # Accept Eulas

#get-process pressy

$updateCmd = [System.IO.Path]::Combine($Env:ANDROID_HOME, "tools\android.bat")
$updateArgs = "update sdk -u"

#java requires current directory to be set because... java.
cd ([System.IO.Path]::Combine($Env:ANDROID_HOME, "tools")) #Your java treachery knows no bounds
Invoke-Expression " & '$updateCmd' $updateArgs"


