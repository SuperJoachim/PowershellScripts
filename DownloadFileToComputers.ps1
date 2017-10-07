<#
.SYNOPSIS
    Runbook to update or put a file on a Windows server .
.DESCRIPTION
    This runbook will download a public file and put it into a directory of your chosing. If a zipfile is chose it will unpack it to the folder in the destination.
.PARAMETER SourceFile
    Url to the file it needs to download.
.PARAMETER TargetDirectory
    Where it should download the file to. If a zipfile is chosen as the SourceFile it will unpack the content to this folder.
.PARAMETER Credential
    Credentials for the hybrid computers. Should be a credential in your azure automation.
.PARAMETER Computers
    The list of computers you need to install the client on. Split using ","
#>

param (
    [Parameter()][string]$SourceFile,
    [Parameter()][string]$TargetDirectory,
    [Parameter()][string]$Computers,
    [Parameter()][string]$Credential
)

if($Computers.Contains(",")) {
    [string[]]$ComputersToManage = $Computers.Split(",")
}
else {
    [string[]]$ComputersToManage = $Computers
}

$vmCred = Get-AutomationPSCredential -Name $Credential
$vmOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck


ForEach ($Computer in $ComputersToManage)
{
    Write-Output $Computer 

        if(Test-WSMan -ComputerName $Computer) {
            $sslFlag = $false
        }
        else {
            $sslFlag = $true
        }
    
    Invoke-Command -ComputerName $Computer -Credential $vmCred -UseSSL:$sslFlag -SessionOption $vmOptions -ArgumentList $SourceFile, $TargetDirectory -ScriptBlock {
        
        param ($SourceFile, $TargetDirectory)   
        $Zip = $false
    
        if($SourceFile -like "*.zip") {
            Write-Output "Zip file uploaded - unzipping into directory."
            $Zip = $true
        }
        
        
        if($Zip -eq $true) {
            $TempFilename = Join-Path $env:TEMP $SourceFile.Split("/")[-1]
            Write-Output "Downloading file to $TempFilename"
            (New-Object System.Net.WebClient).DownloadFile($SourceFile, $TempFilename)
            Write-Output "Unzipping into $TargetDirectory"

            $shell = New-Object -ComObject shell.application
            $zip = $shell.NameSpace($TempFilename)
            foreach ($item in $zip.items()) {
                $shell.Namespace($TargetDirectory).CopyHere($item, 0x14)
            }
            Write-Output "Done"
        }
        else {
            $TempFilename = Join-Path $env:TEMP $SourceFile.Split("/")[-1]
            $TargetFilename = Join-Path $TargetDirectory $SourceFile.Split("/")[-1]
            Write-Output "Downloading file to $TempFilename"
            (New-Object System.Net.WebClient).DownloadFile($SourceFile, $TempFilename)
            Write-Output "Moving file to $TargetFilename"
            Move-Item -Path $TempFilename -Destination $TargetFilename -Force
        }
        
    }
}
