Import-Module BitsTransfer
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
$AndroidSDKUri = "https://dl.google.com/android/android-sdk_r24.4.1-windows.zip"
$AndroidZip = "C:\prereq\AndroidSDK.zip"
Start-BitsTransfer -Source $AndroidSDKUri -Destination $AndroidZip -Authentication Basic
$Env:ANDROID_HOME = "C:\Program Files (x86)\Android\android-sdk\"
$Android_Root = "C:\Program Files (x86)\Android\"
if (-Not [System.IO.Directory]::Exists($Env:ANDROID_HOME)) {Write-output "Making Android Home directory "; md $Env:ANDROID_HOME}
[System.IO.Compression.ZipFile]::ExtractToDirectory($AndroidZip, $Android_Root)
#Rename to match Visual Studio
XCOPY /E /Y "C:\Program Files (x86)\Android\android-sdk-windows"  $Env:ANDROID_HOME
#download Eula Acceptor Get source code here: https://github.com/bagonaut/Scripts/tree/master/pressy
Start-BitsTransfer -Source "https://github.com/bagonaut/Scripts/raw/master/pressy.exe" -Destination "C:\prereq\pressy.exe"
#Environment vars in machine for Future use
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $Env:Android_Home, [System.EnvironmentVariableTarget]::Machine)
$PathVar = [System.String]::concat("$Env:Path;", "$Env:Android_Home", "Tools;", "$Env:ANDROID_HOME", "platform-tools;") 
$Env:Path = $PathVar 
Write-Output "Setting Path Env"
[Environment]::SetEnvironmentVariable("Path", $Env:Path, [System.EnvironmentVariableTarget]::Machine)
write-output $env:PATH
# So much hacking to get this Eula Accepted.
#$p = [System.Diagnostics.Process]::GetCurrentProcess()
#$swa = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
#$sfw = '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);'
#$sf = '[DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);'
#Add-Type -MemberDefinition $swa -name SWA -namespace Win32
#Add-Type -MemberDefinition $sfw -name SFW -namespace Win32
#Add-Type -MemberDefinition $sf -name SF -namespace Win32
# shotgun approach
#[Win32.SWA]::ShowWindowAsync($p.MainWindowHandle, 5)
#sleep(1)
#[Win32.SFW]::SetForegroundWindow($p.MainWindowHandle)
#sleep(1)
#[Win32.SF]::SetFocus($p.MainWindowHandle) 
#Ensuring that powershell window as invoked from go.ps1 has focus for the pressy hack (code moved to pressy)
$env:androidSetupPStid = [System.AppDomain]::GetCurrentThreadId()
[Environment]::SetEnvironmentVariable("androidSetupPStid", $Env:androidSetupPStid, [System.EnvironmentVariableTarget]::Machine)
#Eula Acceptor
new-alias -name y -value "out-null" -Force -Scope Global #squelch extra y
y
C:\prereq\pressy.exe # Accept Eulas
get-process pressy
$updateCmd = [System.IO.Path]::Combine($Env:ANDROID_HOME, "tools\android.bat")
$updateArgs = "update sdk -u"
cd ([System.IO.Path]::Combine($Env:ANDROID_HOME, "tools")) #Your java treachery knows no bounds
Invoke-Expression " & '$updateCmd' $updateArgs"


