function GeneratePerfReport ($logFile)
{
    

get-job
$totalJobs = 0
$logfileName = $logFile
if ($logFile -eq $null) {$logfileName = dans010316.csv}
$firstLogLine = "Start Time, Finish Time, Duration, Status, Signal Strength"
Add-Content $logfileName $firstLogLine
while ($totalJobs -lt 10000)

{
    $thisJob = start-job -scriptblock { 
        
        $startTime = [System.DateTime]::UtcNow;
        $response  = iwr "http://zombo.com" -TimeoutSec 20;
        $responseString = $response.StatusDescription
        if ($response -eq $null) {write-host "TimedOut"; $responseString = "TimeOut"}
        #$response | format-list 
        #Write-Host $response
        $endTime = [System.DateTime]::UtcNow;
        $totalRequestTime = $endTime - $startTime;
        $totalRequestTime =$totalRequestTime.TotalMilliseconds.ToString();
        if ($null -eq $response) { $totalRequestTime = 999999 }
        $signalStrength = (netsh wlan show interfaces) -Match '^\s+Signal' -Replace '^\s+Signal\s+:\s+','';
        $logline = $startTime.ToString("o") + ", " +$endTime.ToString("o") + ", " + $totalRequestTime + ", " + $responseString + ", " + $signalStrength;
        Write-Debug $logline; 
        Add-Content PRovider.net.comcast.csv $logline;}

    $totalJobs ++
    Write-Host "Job# " + $thisJob.Id + "Started."
    sleep 1
    get-job
    remove-job -State Completed
    Remove-Job -State Failed
}
sleep(30)
remove-job -State Completed
$jobsIncomplete = get-job 
Write-Host $jobsIncomplete.Length + " unfinished jobs."
}

#Export-ModuleMember -Function GeneratePerfReport

GeneratePerfReport("C:\testingnewhouse10.csv") 