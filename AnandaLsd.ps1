#params ([string]$filePrefix)

Write-host "Hello."

function ConcatLsds([string] $files)
{
    Write-Host "In Function."
    $lsdFiles = $files.Split(",".ToCharArray());
    if($lsdFiles -eq $null) {return; }
    $tstamp = [System.DateTime]::Now.ToString("s");
    $tstamp = $tstamp.Replace(":", "_");
    $compiledFile = [System.IO.Path]::Combine($lsdFiles[0].DirectoryName, ("compiled." + $tstamp + ".lsd"))
    $compiledFilex = $compiledFile + "x"
    $cFile = (gci $compiledFile) 2> $null
    $xFile = (gci $compiledFilex) 2> $null
    if ($xFile.Exists) { del $compiledFilex }
    if ($cFile.Exists) { del $compiledFile }
    Add-Content $compiledFilex ("CompFile:   " + $compiledFile)
    
    
    $lsdFiles | ForEach-Object {
        #ensure file is properly formatted
        Select-String $_ -pattern "{`"Comments`":" | Out-Null
        select-string $_ -pattern "}]}}" | Out-Null

        $contents = cat -Encoding UTF8 $_
        $startguid = $contents[0].SubString(14,36) #startguid

        $laststring = $contents[$contents.Count -1]
        $lastguid = $laststring.Substring($laststring.Length - 41, 36) #lastguid

        $contents | ForEach-Object { Add-Content -Encoding UTF8 $compiledFile $_; }
        #Add-Content $compiledFile $contents;
        Add-Content $compiledFilex ("FileName:   " + $_)
        Add-Content $compiledFilex ("StartGuid:  " + $startguid)
        Add-Content $compiledFilex ("LastGuid:   " + $lastguid)
    }        
} #end ConcatLSDs




function ConcatLsd([string] $prefix)
{
    if (([string]::IsNullOrWhiteSpace($prefix)) -or ($prefix.Contains('?'))) {
        Write-Host "Needs one argument: the prefix for lsd files you wish to compile";
        return;
    }
    $lsdQueryString = ".`\" + $prefix + "*.lsd"   
    #$lsdFiles = gci $lsdQueryString
    $lsdFiles = gci $lsdQueryString
    if($lsdFiles -eq $null) { write-host "lsd Files matching pattern " + $lsdQueryString "not found in current directory."; return; }
    $compiledFile = [System.IO.Path]::Combine($lsdFiles[0].DirectoryName, ("compiled." + $prefix + ".lsd"))
    $compiledFilex = $compiledFile + "x"
    $cFile = (gci $compiledFile) 2> $null
    $xFile = (gci $compiledFilex) 2> $null
    if ($xFile.Exists) { del $compiledFilex }
    if ($cFile.Exists) { del $compiledFile }
    Add-Content $compiledFilex ("CompFile:   " + $compiledFile)
    
    
    $lsdFiles | ForEach-Object {
        #ensure file is properly formatted
        Select-String $_ -pattern "{`"Comments`":" | Out-Null
        select-string $_ -pattern "}]}}" | Out-Null

        $contents = cat -Encoding UTF8 $_
        $startguid = $contents[0].SubString(14,36) #startguid

        $laststring = $contents[$contents.Count -1]
        $lastguid = $laststring.Substring($laststring.Length - 41, 36) #lastguid

        $contents | ForEach-Object { Add-Content -Encoding UTF8 $compiledFile $_; }
        #Add-Content $compiledFile $contents;
        Add-Content $compiledFilex ("FileName:   " + $_.FullName)
        Add-Content $compiledFilex ("StartGuid:  " + $startguid)
        Add-Content $compiledFilex ("LastGuid:   " + $lastguid)
    }        
} #end ConcatLSD

function SplitLsdx ([string] $lsdxFile)
{
    if (([string]::IsNullOrWhiteSpace($lsdxFile)) -or ($lsdxFile.Contains('?'))) {
        Write-Host "Needs one argument: the prefix for lsd files you wish to compile";
        return;
    }
    $lsdx = gci $lsdxFile
    if($lsdx.Exists -eq $false) {
        Write-Host "lsdx file " + $lsdxFile + "Does not exist."
        return;
    }
    $lsdxContents = cat $lsdxFile
    $compiledFileName = $lsdxContents[0].Substring(12)
    #$compiledContents = cat $compiledFileName
    $compiledContents = [System.IO.File]::ReadAllText($compiledFileName, [System.Text.Encoding]::UTF8 )
    $lastStart = ""
    $lastEnd = ""
    $lastFileName = ""
    foreach ($line in [System.IO.File]::ReadLines($lsdx)) {
        Write-Host $line
        [string] $lineString = $line
        if($lineString.StartsWith("FileName: ")) {$lastFileName = $lineString.Substring(12)}
        if($lineString.StartsWith("StartGuid: ")) {$lastStart = $lineString.Substring(12)}
        if($lineString.StartsWith("LastGuid: ")) {$lastEnd = $lineString.Substring(12)}
        
        if( ([string]::IsNullOrWhiteSpace($lastFileName) -eq $false) -and 
            ([string]::IsNullOrWhiteSpace($lastStart) -eq $false) -and
            ([string]::IsNullOrWhiteSpace($lastEnd) -eq $false) )
        {
            #all arguments populated            
            $newFileName = [System.IO.Path]::GetFileNameWithoutExtension($lastFileName)
            $newFileDir = [System.IO.Path]::GetDirectoryName($lastFileName)
            $newFileName = $newFileName + "s"
            $newFilePath = [System.IO.Path]::Combine($newFileDir, $newFileName)
            $newFilePath = $newFilePath + ".lsd"
            #new file name created

            #IndexOf doesn't appear to be working on a string this length. New approach is needed.
            #compiledContents is array of lines, needs to be concatenated into a super-string

            $thisFileContents = $compiledContents.Substring(($compiledContents.IndexOf($lastStart) - 14), (($compiledContents.IndexOf($lastEnd) + 41) - $compiledContents.IndexOf($lastStart) + 16 ) )
            #$thisFileContents = $compiledContents.Substring(($compiledContents.IndexOf($lastStart) - 14), (($compiledContents.IndexOf($lastEnd) + 41) - $compiledContents.IndexOf( -14) ) )
            Add-Content -Encoding UTF8 $newFilePath $thisFileContents.Trim()
            $lastStart = ""
            $lastEnd = ""
            $lastFileName = ""

        }

    }
}

#ConcatLsd("es_es_li")
#SplitLsdx("compiled.es_es_li.lsdx")
#ConcatLsd("es_es_li")

#$starttags = Select-String *.lsd -pattern "{'"Comments'":"
#$endtags = select-string *.lsd -pattern "}]}}"


#$contents = cat '.\es_ES_LiveData_22Dec2014_26Dec2014_1783 - Copy.lsd'
#$startguid = $contents[0].SubString(14,36)

#$laststring = $contents[$contents.Count -1]
#$lastguid = $laststring.Substring($laststring.Length - 41, 36)


#PS C:\scratch> "Filename: " + "firstfile.lsd" | out-file mergemanifest.txt -append
#PS C:\scratch> "FirstGuid: " + $guid | out-file .\mergemanifest.txt -append
#PS C:\scratch> "LastGuid: " + $lastguid | out-file .\mergemanifest.txt -append
