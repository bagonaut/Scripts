

    if (-Not [System.IO.Directory]::Exists("C:\prereq")) {Write-output "Making prereq directory C:\prereq"; md C:\prereq}
    if (-Not [System.IO.File]::Exists("C:\prereq\AdminFile.xml")) {
        Write-output "Downloading AdminFile (Visual Studio 2015 Installation Template)";
        $wc = New-Object System.Net.WebClient
        $adminContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/Adminfile.xml")
        $adminContents | out-file C:\prereq\AdminFile_final.xml -Encoding ascii #vs requires an ascii xml file...
    }
    
    if (-Not [System.IO.File]::Exists("C:\prereq\AndroidSetup.ps1")) {
        Write-output "Downloading Android Setup script";
        $wc = New-Object System.Net.WebClient
        $adminContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/AndroidSetup.ps1")
        $adminContents | out-file C:\prereq\AndroidSetup.ps1 
    }
    if (-Not [System.IO.File]::Exists("C:\prereq\VS.iso")) {
        Write-output "Downloading iso (Visual Studio 2015 Community Image)";
        $wc = New-Object System.Net.WebClient
        try {
            $get = "/download/f/d/c/fdce5d40-87d3-4bd6-9139-2a7638b96174/vs2015.2.com_enu.iso"
            $srv = "download.microsoft.com"
            $foo = "http://" + $srv + $get
            $uri = [System.Uri]::new($foo)
            import-module BitsTransfer
            Start-BitsTransfer -Source $uri.ToString() -Destination C:\prereq\vs_2015.iso
            Mount-DiskImage -ImagePath C:\prereq\vs_2015.iso
            #get tasky demo
            $taskyZipUri = "https://developer.xamarin.com/content/Tasky/Tasky.zip"
            $TaskyZip = "C:\prereq\Tasky.zip"
            Start-BitsTransfer -source $taskyZipUri -Destination $TaskyZip -Authentication Basic
            [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
            [System.IO.Compression.ZipFile]::ExtractToDirectory($TaskyZip, [System.IO.Path]::GetDirectoryName($TaskyZip) + "\Tasky")

        }
        catch{
            Write-Output $_
        }
    Write-Output "Download Complete."
    }


        Write-Verbose 'Installing VS 2015 ...'


        # Populated by test function
        $adminFile = "C:\prereq\AdminFile_final.xml"
        $installDir = "C:\bagoxam\"

        # Set antimalware policy
        $wc = New-Object System.Net.WebClient
        
        #$malwareConfignContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/malwareConfig.json")
        #$malwareConfigContents | out-file C:\prereq\malwareConfig.json -Encoding ascii -Force   
        #since this is azure1.5 , I have no idea how to config the malwareservice. I'm going to murder it.
        #no dice, use Set-MpPreference to confiugre antimalware
        Set-MpPreference -ExclusionPath "C:\bagoxam;'C:\Program Files (x86)\Microsoft Visual Studio 14.0\';C:\prereq\AndroidSDK;"
        Set-MpPreference -ExclusionProcess "vs_community.exe;devenv.exe;secondaryInstaller.exe;java.exe"

        Set-MpPreference -DisableRealtimeMonitoring $true
        $FirstCD = get-PSDrive | where-object {$_.Free -eq 0}
        if ($FirstCD.GetType() -eq "System.Object[]") {$FirstCD = $FirstCD[0]}
        $installerPath = $FirstCD.Root + "vs_community.exe"
        $args = [System.String]::concat("/Quiet /AdminFile ", $adminFile, " /Log ",  "$env:TEMP\VisualStudio2015_install.log", " /CustomInstallPath ", $installDir )
        Write-Output "Beginning install with the following params:"
        Write-Output $installerPath
        Write-Output $args
        $startTime = [System.DateTime]::Now
        try{
        Start-Process -FilePath $installerPath -ArgumentList $args -Wait
        C:\prereq\AndroidSetup.ps1
        }
        catch{
            Write-Output $_
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
        $endTime = [System.DateTime]::Now
        Write-Verbose -Message 'Testing if VS 2015 is installed or not ..'
        Set-MpPreference -DisableRealtimeMonitoring $false
        $installTime = $startTime - $endTime
        Write-Output "Install takes: " $installTime.ToString()
