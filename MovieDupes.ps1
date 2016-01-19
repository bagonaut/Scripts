function findDupesInRoots( [string] $root1, [string] $root2, [string] $root3)
{
    $Global:FileList = @{"foo" = "bar"}
    if ($root1 -ne $null) {addDupesToDictionaryFromRoot($root1)};
    if ($root1 -ne $null) {addDupesToDictionaryFromRoot($root2)};
    #if ($root1 -ne $null) {addDupesToDictionaryFromRoot($root3)};
    printDupes

}

function addDupesToDictionaryFromRoot ([string] $root)
{
    $movieFiles = ls -recurse *.mkv,*.avi,*.mp4
    $movieFiles | ForEach-Object { 
                        if ( $Global:FileList.ContainsKey($_.Name) ) {
                                    if ($Global:FileList[$_.Name].Contains($_.FullName) -eq $false) {
                                        Write-Output "Dupe Detected: " + $_.FullName;
                                        $Global:FileList[$_.Name] += "$"   
                                        $Global:FileList[$_.Name] += ($_.FullName)
                                    }
                        }
                        else { $Global:FileList.Add($_.Name, $_.FullName)} 
    }

}

function printDupes()
{
    $Global:FileList.GetEnumerator() | % {
                            if ($_.Value.Contains("$") ) {
                                $key = $_.Key
                                Write-Output "Full Dupe List for $key ";
                                $result = $_.Value.Split("$".ToCharArray());
                                if ($result -ne $null) {
                                    $result | Write-Output
                                }  
                            }   
                         } 
}

findDupesInRoots("D:\Video", "C:\Users\Randy", $null)