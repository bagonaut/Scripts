    $xamgolog = [System.IO.Path]::Combine($env:TEMP, "XamGo.log");
    Out-File "Beginning Xamarin Install" -Append -FilePath $xamgolog

    # Create directory for installation artifacts.
    if (-Not [System.IO.Directory]::Exists("C:\prereq")) {Write-output "Making prereq directory C:\prereq" | Out-File -Append -FilePath $xamgolog; md C:\prereq}

    # Pulling visual studio configuration file from git repository
    if (-Not [System.IO.File]::Exists("C:\prereq\AdminFile.xml")) {
        Write-output "Downloading AdminFile (Visual Studio 2015 Installation Template)" | Out-File -Append -FilePath $xamgolog;
        $wc = New-Object System.Net.WebClient
        $adminContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/Adminfile.xml")
        $adminContents | out-file C:\prereq\AdminFile_final.xml -Encoding ascii #vs requires an ascii xml file...
    }
    
    # Pulling Android setup script from repository.
    if (-Not [System.IO.File]::Exists("C:\prereq\AndroidSetup.ps1")) {
        Write-output "Downloading Android Setup script" | Out-File -Append -FilePath $xamgolog;
        $wc = New-Object System.Net.WebClient
        $adminContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/AndroidSetup.ps1")
        $adminContents | out-file C:\prereq\AndroidSetup.ps1 
    }

    # Aquire and extract the VSTS build agent. You have to configure and hook this up.
    if (-Not [System.IO.File]::Exists("C:\prereq\Agent.zip")) {
        Write-output "Downloading VSTS Build Agent";
        $wc = New-Object System.Net.WebClient #github does not like BITS
        $wc.DownloadFile("https://github.com/Microsoft/vsts-agent/releases/download/v2.102.1/vsts-agent-win7-x64-2.102.1.zip", "C:\prereq\Agent.zip") 
        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
        [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\prereq\Agent.zip", "C:\prereq\Agent")
    }

    # Downloading iso (Visual Studio 2015 Community Image) and Tasky Xamarin Sample
    if (-Not [System.IO.File]::Exists("C:\prereq\VS.iso")) {
        Write-output "Downloading iso (Visual Studio 2015 Community Image) and Tasky Xamarin Sample" | Out-File -Append -FilePath $xamgolog;
        $wc = New-Object System.Net.WebClient
        try {
            $get = "/download/f/d/c/fdce5d40-87d3-4bd6-9139-2a7638b96174/vs2015.2.com_enu.iso" # subject to change
            $srv = "download.microsoft.com"
            $foo = "http://" + $srv + $get
            $uri = [System.Uri]::new($foo)
            import-module BitsTransfer
            Start-BitsTransfer -Source $uri.ToString() -Destination C:\prereq\vs_2015.iso
            Mount-DiskImage -ImagePath C:\prereq\vs_2015.iso
            #get tasky demo
            $taskyProj = "https://raw.githubusercontent.com/bagonaut/Scripts/master/TaskyAndroid.csproj"
            $taskyZipUri = "https://developer.xamarin.com/content/Tasky/Tasky.zip"
            $TaskyZip = "C:\prereq\Tasky.zip"
            Start-BitsTransfer -source $taskyZipUri -Destination $TaskyZip -Authentication Basic
            [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
            [System.IO.Compression.ZipFile]::ExtractToDirectory($TaskyZip, [System.IO.Path]::GetDirectoryName($TaskyZip) + "\Tasky")

            #Because Tasky from Xamarin website is configured to build using API 15, which is no longer supported by android update sdk
            # I have updated the csproj to loop in a more recent platform.
            Copy-Item -Path "C:\prereq\Tasky\TaskyAndroid\TaskyAndroid.csproj" -Destination "C:\prereq\Tasky\TaskyAndroid\TaskyAndroid.csproj.old" #backup the old
            Remove-Item -Path "C:\prereq\Tasky\TaskyAndroid\TaskyAndroid.csproj" -Force
            Start-BitsTransfer -source $taskyProj -Destination "C:\prereq\Tasky\TaskyAndroid\TaskyAndroid.csproj" -Authentication Basic

        }
        catch{
            Write-Output $_
        }
    Write-Output "Download Complete." | Out-File -Append -FilePath $xamgolog
    }


        Write-Verbose 'Installing VS 2015 ...'



        # Populated by test function
        $adminFile = "C:\prereq\AdminFile_final.xml"
        $installDir = "C:\bagoxam\"

        # Set antimalware policy
        $wc = New-Object System.Net.WebClient
        

        # Use Set-MpPreference to confiugre antimalware for the duration of the install. Reduces install time from >6 hours to 40 minutes
        Set-MpPreference -ExclusionPath "C:\bagoxam;'C:\Program Files (x86)\Microsoft Visual Studio 14.0\';C:\prereq\AndroidSDK;"
        Set-MpPreference -ExclusionProcess "vs_community.exe;devenv.exe;secondaryInstaller.exe;java.exe"
        Set-MpPreference -DisableRealtimeMonitoring $true

        # find the first CD drive on this machine. It SHOULD be the one mounted above, but your machine configuration may differ.
        # feel free to hard code for your configuration
        $FirstCD = get-PSDrive | where-object {$_.Free -eq 0}
        if ($FirstCD.GetType().ToString() -eq "System.Object[]") {$FirstCD = $FirstCD[0]}
        # Set this variable to hard code the VS install location.
        $installerPath = $FirstCD.Root + "vs_community.exe"
        $args = [System.String]::concat("/Quiet /AdminFile ", $adminFile, " /Log ",  "$env:TEMP\VisualStudio2015_install.log", " /CustomInstallPath ", $installDir )
        Write-Output "Beginning install with the following params:" | Out-File -Append -FilePath $xamgolog
        Write-Output $installerPath  | Out-File -Append -FilePath $xamgolog
        Write-Output $args  | Out-File -Append -FilePath $xamgolog

        #Start background job to check on SecondaryInstaller.exe. If your install lasts for more than 4 hours...
        $secondaryMonitor = Start-Job -Name secondaryInstaller -ScriptBlock{
            $monitorStart = [System.DateTime]::UtcNow
            $monitorLength = [System.TimeSpan]::FromHours(2); # installs lasting for more than 2 hours will be terminated
            $endWatch = $false;
            $backgroundLog = [System.IO.Path]::Combine($env:TEMP, "SecondaryInstallerMonitor.log");
            Write-Output "Secondary Installer Monitoring job started." | Out-File -Append -FilePath $backgroundLog;
            do  {
                # If the monitor job lasts for more than 2 + 2 hours, quit no matter what.
                if (([System.DateTime]::UtcNow - $monitorStart) -gt ($monitorLength + [System.TimeSpan]::FromMinutes(120)) ) { 
                    $endWatch = $true;
                    Write-Output "Aborting Secondary Installer Monitoring job." | Out-File -Append -FilePath $backgroundLog;
                }
                Write-Output "Looking For Secondary Installer" | Out-File -Append -FilePath $backgroundLog;
                $secondaryInstallers = Get-Process -Name SecondaryInstaller
                if ($secondaryInstallers -ne $null) { # SecondaryInstaller.exe like to launch another Secondary Installer.exe process 
                    Write-Output "Secondary Installer Found. WatchTime = " + ([System.DateTime]::UtcNow - $monitorStart) | Out-File -Append -FilePath $backgroundLog;
 
                    # If multiple instances of SecondaryInstaller are found...
                    if ($secondaryInstallers.GetType().ToString() -eq "System.Object[]") { 
                         
                        Write-Output "Multiple Secondary Installer instances found. "| Out-File -Append -FilePath $backgroundLog;
                        $secondaryInstallers | % { #iterate through all isntances and kil them if...
                            $installerLifespan = ([System.DateTime]::UtcNow - $_.StartTime)
                            if ($installerLifespan -gt $monitorLength) { # the install has been running for an inordinate amount of time.
                                Write-Output "Killing " + $_.Name + $_.Id | Out-File -Append -FilePath $backgroundLog;
                                $_.Kill(); 
                                $endWatch = $true;
                            }
                            Write-Output "Installer $_ for: $installerLifespan" | Out-File -Append -FilePath $backgroundLog; #who needs formatting?
                        } 
                        
                    }
                    else { #assuming a single return
                        $installerLifespan = ([System.DateTime]::UtcNow - $secondaryInstallers.StartTime)
                        if ($installerLifespan -gt $monitorLength) {
                            Write-Output "Killing Secondary Installer." | Out-File -Append -FilePath $backgroundLog;
                            $secondaryInstallers.Kill();
                            $endWatch = $true;
                        }
                        Write-Output "Single Job alive for: $installerLifespan" | Out-File -Append -FilePath $backgroundLog;

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
            Write-Output "Beginning Android Setup"  | Out-File -Append -FilePath $xamgolog #If android got interrupted by secondary install kill, this will patch android up.
            C:\prereq\AndroidSetup.ps1
        }
        catch{
            Write-Output $_
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
        $endTime = [System.DateTime]::NowUtc
        Write-Verbose -Message 'Testing if VS 2015 is installed or not ..'  | Out-File -Append -FilePath $xamgolog
        Set-MpPreference -DisableRealtimeMonitoring $false
        $installTime = $endTime - $startTime
        Write-Output "Install takes: " $installTime.ToString()   | Out-File -Append -FilePath $xamgolog
        Write-Output "Press enter to restart machine and complete installation. After reboot, open C:\prereq\Tasky\Tasky.sln to see xamarin in action."  | Out-File -Append -FilePath $xamgolog
        
        #find and kill pressy if it is still running. 
        $pressy = get-process pressy
        $pressy.Kill();
        pause 
        Restart-Computer
