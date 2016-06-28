

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

        #Start background job to check on SecondaryInstaller.exe. If your install lasts for more than 4 hours...
                $secondaryMonitor = Start-Job -ScriptBlock{
            $monitorStart = DateTime.NowUtc;
            $monitorLength = [System.TimeSpan]::FromHours(4);
            $endWatch = $false;
            $backgroundLog = [System.IO.Path]::Combine($env:TEMP, "secondaryMonitor.log");
            Write-Output "Secondary Installer Monitoring job started." | Out-File -Append -FilePath $backgroundLog;
            do  {
                if ((DateTime.NowUtc - $monitorStart) -gt ($monitorLength + [System.TimeSpan]::FromMinutes(10)) ) {
                    $endWatch = $true;
                    Write-Output "Aborting Secondary Installer Monitoring job." | Out-File -Append -FilePath $backgroundLog;
                }
                Write-Output "Looking For Secondary Installer" | Out-File -Append -FilePath $backgroundLog;
                $secondaryInstallers = Get-Process -Name SecondaryInstaller
                if ( -Not $secondaryInstallers -eq $null) {

                    if ((DateTime.NowUtc - $monitorStart) -gt $monitorLength) {
                        #if we are in the ten minute window and secondary installer is still running, kill all instances of secondary installer
                        #possibly check log at $env:TEMP\VisualStudio2015_install_SecondaryInstaller_UX.log
                        if ($secondaryInstallers.GetType() -eq "System.Object[]") { 
                            { 
                                Write-Output "Multiple Secondary Installer instances found. Killing. "| Out-File -Append -FilePath $backgroundLog;
                                % {$_.Kill(); $endWatch = $true;} 
                            }
                        }
                        else {
                            Write-Output "Killing Secondary Installer."| Out-File -Append -FilePath $backgroundLog;
                            $secondaryInstallers.Kill();
                            $endWatch = $true;
                        }
                    }
                }
                Write-Output "Sleeping 1 Minute." | Out-File -Append -FilePath $backgroundLog;
                sleep(60) #sleep a minute

            } Until ($endWatch -eq $true)

        Write-Output "Secondary Job died of old age." | Out-File -Append -FilePath $backgroundLog;
        }#secondaryMonitor runs until it kills secondary install or 4 hours have elapsed


        $startTime = [System.DateTime]::NowUtc
        try{
            Start-Process -FilePath $installerPath -ArgumentList $args -Wait
            #if we get here, kill the background job.
            if ($secondaryMonitor.Finished -eq $false) {
                $secondaryMonitor.StopJob(); 
            }
            Write-Output "Beginning Android Setup" #If android got interrupted by secondary install kill, this will patch android up.
            C:\prereq\AndroidSetup.ps1
        }
        catch{
            Write-Output $_
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
        $endTime = [System.DateTime]::NowUtc
        Write-Verbose -Message 'Testing if VS 2015 is installed or not ..'
        Set-MpPreference -DisableRealtimeMonitoring $false
        $installTime = $endTime - $startTime
        Write-Output "Install takes: " $installTime.ToString()
