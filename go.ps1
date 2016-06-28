        $secondaryMonitor = Start-Job -Name secondaryInstaller -ScriptBlock{
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
                    Write-Output "Secondary Installer Found. WatchTime = " + ([System.DateTime]::UtcNow - $monitorStart) | Out-File -Append -FilePath $backgroundLog;
 
                    if ($secondaryInstallers.GetType() -eq "System.Object[]") { 
                         
                        Write-Output "Multiple Secondary Installer instances found. "| Out-File -Append -FilePath $backgroundLog;
                        % {
                            if (([System.DateTime]::UtcNow - $_.StartTime) -gt $monitorLength) {
                                Write-Output "Killing " + $_.Name + $_.Id | Out-File -Append -FilePath $backgroundLog;
                                $_.Kill(); 
                                $endWatch = $true;
                            }
                        } 
                        
                    }
                    else { #assuming a single return
                        if (([System.DateTime]::UtcNow - $secondaryInstallers.StartTime) -gt $monitorLength) {
                            Write-Output "Killing Secondary Installer." | Out-File -Append -FilePath $backgroundLog;
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
