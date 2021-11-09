
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Unzip($zipfile, $outdir)
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
    try
    {
        foreach ($entry in $archive.Entries)
        {
            $entryTargetFilePath = [System.IO.Path]::Combine($outdir, $entry.FullName)
            $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)

            #Ensure the directory of the archive entry exists
            if(!(Test-Path $entryDir )){
                New-Item -ItemType Directory -Path $entryDir | Out-Null 
            }

            #If the entry is not a directory entry, then extract entry
            if(!$entryTargetFilePath.EndsWith("\")){
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
            }
        }
    }
    finally
    {
        $archive.Dispose()
    }
}

$Url = 'https://code.vmware.com/docs/14830' 
$ZipFile = 'C:\temp\' + $(Split-Path -Path $Url -Leaf) 
$Destination = 'c:\Windows\system32\WindowsPowerShell\v1.0\Modules\' 
 
Invoke-WebRequest -Uri $Url -OutFile $ZipFile 

Unzip -zipfile $ZipFile -outdir $Destination
 
cd c:\Windows\system32\WindowsPowerShell\v1.0\Modules

Get-ChildItem * -Recurse | Unblock-File

clear 

Get-Module -Name VMware.PowerCLI -ListAvailable
