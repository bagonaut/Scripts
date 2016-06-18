function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    
    $configuration = @{
        IsSingleInstance = 'Yes'
        Path = $Path
    }

    if (-Not [System.IO.Directory]::Exists("C:\prereq")) {Write-output "Making prereq directory C:\prereq"; md C:\prereq}
    if (-Not [System.IO.File]::Exists("C:\prereq\AdminFile.xml")) {
        Write-output "Downloading AdminFile (Visual Studio 2015 Installation Template)";
        $wc = New-Object System.Net.WebClient
        $adminContents = $wc.DownloadString("https://raw.githubusercontent.com/bagonaut/Scripts/master/Adminfile.xml")
        $adminContents | out-file C:\prereq\AdminFile.xml -Encoding ascii #vs requires an ascii xml file...
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
        }
        catch{
            Write-Output $_
        }
    Write-Output "Download Complete."
    }
        

    Write-Verbose 'Checking if VS 2015 is installed ...'
    if (Get-VS2015Install)
    {
        $configuration.Add('Ensure','Present')
    }
    else
    {
        $configuration.Add('Ensure','Absent')
    }

    $configuration
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )
    
    if ($Ensure -eq 'Present')
    {
        Write-Verbose 'Installing VS 2015 ...'
#        $loadInf = '@
#[Setup]
#Lang=english
#Dir=C:\Program Files (x86)\Microsoft VS 2015
#Group=Visual Studio 2015
#NoIcons=0
#Tasks=desktopicon,addcontextmenufiles,addcontextmenufolders,addtopath
#        @'

        # Populated by test function
        $adminFile = "C:\prereq\AdminFile.xml"
        $installDir = "C:\bagoxam"

        # Set antimalware policy


        $FirstCD = get-PSDrive | where-object {$_.Free -eq 0}
        if ($FirstCD.GetType() -eq "System.Object[]") {$FirstCD = $FirstCD[0]}
        $installerPath = $FirstCD.Root + "vs_community.exe"
        $args = [Syste.String]::concat("/Quiet /NoReboot /AdminFile ", $adminFile, " /Log " + "$env:TEMP\VisualStudio2015_install.log")
        Write-Output "bBeginning install with the following params:"
        Write-Output $installerPath
        Write-Output $args
        Start-Process -FilePath $installerPath -ArgumentList $args -Wait
        Write-Verbose -Message 'Testing if VS 2015 is installed or not ..'
        if (Get-VS2015Install)
        {
            Write-Verbose -Message 'VS 2015 install successful ...'
        }
        else
        {
            Write-Error -Message 'VS 2015 install failed ...'
        }
    }
    else 
    {
        Write-Verbose 'Uninstalling VS 2015 ...'
        $vs2015Install = Get-VS2015Install
        try
        {
            Start-Process -FilePath $($vs2015Install.UninstallString) -ArgumentList '/VERYSILENT' -Wait
            Start-Sleep -Seconds 10
        }
        catch
        {
            Write-Error $_
        }
        
        Write-Verbose -Message 'Testing if VS 2015 is uninstalled or not ..'
        if (Get-VS2015Install)
        {
            Write-Error -Message 'VS 2015 uninstall failed ...'
        }
        else
        {
            Write-Verbose -Message 'VS 2015 uninstall successful ...'
        }        
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )

    Write-Verbose -Message 'Testing if VS 2015 is installed ...'
    if (Get-VS2015Install)
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS 2015 is already installed. No action needed.'
            return $true
        }
        else
        {
            Write-Verbose -Message 'VS 2015 is installed while it should not. It will be removed.'
            return $false
        }
    }
    else
    {
        if ($Ensure -eq 'Present')
        {
            Write-Verbose -Message 'VS 2015 is not installed. It will be installed.'
            return $false
        }
        else
        {
            Write-Verbose -Message 'VS 2015 is not installed. No action needed.'
            return $true
        }
    }
}

Function Get-VS2015Install
{
    switch ($env:PROCESSOR_ARCHITECTURE)
    {
        'AMD64' { $UninstallKey = 'HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*' }
        'x86' { $UninstallKey = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*' }
    }

    $products = Get-ItemProperty -Path $UninstallKey | Select DisplayName, DisplayVersion, InstallLocation, UninstallString
    if ($products.DisplayName -contains 'Microsoft Visual Studio 2015')
    {
        return $products.Where({$_.DisplayName -eq 'Microsoft Visual Studio 2015'})
    }
}

Export-ModuleMember -Function *-TargetResource

