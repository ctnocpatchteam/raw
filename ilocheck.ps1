Function Get-HPServerStatistics {
<#
.Synopsis
    This will grab current readings from an HP Proliant Server iLO settings.  Tested on HP Proliant DL580 G7, DL360 G8, DL380 G8, DL380 G7 with iLO versions 3.0 and 4.0
    For updated help and examples refer to -Online version.
  
 
.DESCRIPTION
    This will grab current readings from an HP Proliant Server iLO settings.  Tested on HP Proliant DL580 G7, DL360 G8, DL380 G8, DL380 G7 with iLO versions 3.0 and 4.0
    For updated help and examples refer to -Online version.
 
 
.NOTES   
    Name: Get-HPServerStatistics
    Author: theSysadminChannel
    Version: 1.0
    DateCreated: 2019-Feb-15
    DateUpdated: 2019-Feb-15
 
.LINK
    https://thesysadminchannel.com/get-hp-server-status-using-powershell-ilo-query -
 
 
.EXAMPLE
    For updated help and examples refer to -Online version.
 
#>
 
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
 
        [Alias("IPAddress")]
 
        [string[]] $ComputerName,
 
        [switch]   $Summary,
 
        [System.Management.Automation.PSCredential]
        $Credential
    )
 
 
    BEGIN {
    #Used to ignore any SSL cert errors when connecting to HP iLO.
    #This should revert to the default Policy upon closing your Powershell window.
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
 
    }
 
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            try {
                if ($Credential) {
                        #Inserting Username and password from Get-Credential
                        #$Credential = (Get-Credential)
                        $Username = $Credential.GetNetworkCredential().username
                        $Password = $Credential.GetNetworkCredential().password
                    } else {
                        #Hardcoding Username and Password in clear text. For cowboys only.
                        $Username = 'administrator'
                        $Password = 'Password'
                }
 
                $URL      = "https://$Computer/json"
                $Login = Invoke-WebRequest -Uri "$URL/login_session" -Method "POST" -Headers @{
                    "Cookie"="sessionLang=en; 
                    UserPref=fahrenheit%3Dtrue; 
                    sessionUrl=https%253A%2F%2F$Computer%2Findex.html"; 
                } -Body "{`"method`":`"login`",`"user_login`":`"$Username`",`"password`":`"$Password`"}" -SessionVariable 'Session'
 
                $Overview = Invoke-WebRequest -Uri "$URL/overview" -Headers @{
                    "Cookie"="sessionLang=en; 
                    UserPref=fahrenheit%3Dtrue; 
                    sessionUrl=https%253A%2F%2F$Computer%2Findex.html"; 
                } -WebSession $Session
                $Overview = $Overview.Content | ConvertFrom-Json
 
                $PowerReading = Invoke-WebRequest -Uri "$URL/power_readings" -Headers @{
                    "Cookie"="sessionLang=en; 
                    UserPref=fahrenheit%3Dtrue; 
                    sessionUrl=https%253A%2F%2F$Computer%2Findex.html"; 
                } -WebSession $Session
                $PowerReading = $PowerReading.Content | ConvertFrom-Json
 
                $Temperature = Invoke-WebRequest -Uri "$URL/health_temperature" -Headers @{
                    "Cookie"="sessionLang=en; 
                    UserPref=fahrenheit%3Dtrue; 
                    sessionUrl=https%253A%2F%2F$Computer%2Findex.html";
                } -WebSession $Session
 
                $TempReading = $Temperature.Content | ConvertFrom-Json  | select -ExpandProperty temperature
                $TempReading = $TempReading[0]
 
                if ($Overview.power -eq 'OFF') {
                        $TempReadingC = 0
                        $TempReadingF = 0
                    } else {
                        $TempReadingC = $TempReading.currentreading
                        $TempReadingF = ($TempReadingC * 9/5) + 32
                }
                 
 
                if ($Summary) {
                        $Properties = @{ComputerName  = $Computer
                                        ProductName   = $Overview.product_name
                                        IP_Address    = $Overview.ip_address
                                        iLO_Firmware  = $Overview.ilo_fw_version
                                        License       = $Overview.license
                                        iLO_Name      = $Overview.ilo_name
                                        System_Health = $Overview.system_health  
                                      }
                        $Object = New-Object -TypeName PSCustomObject -Property $Properties | Select ComputerName, ProductName, IP_Address, iLO_Firmware, License, iLO_Name, System_Health
 
                    } else {
                        $Properties = @{ComputerName = $Computer
                                        ProductName  = $Overview.product_name
                                        CurrentPower = "$($PowerReading.present_power_reading) Watts"
                                        CurrentTemp  = "$($TempReadingF)F / $($TempReadingC)C"
                                      }
                    $Object = New-Object -TypeName PSCustomObject -Property $Properties | Select ComputerName, ProductName, CurrentPower, CurrentTemp
                }
            } catch {
                 
                $ErrorMessage = $Computer + " Error: " + $_.Exception.Message
 
            } finally {
                Write-Output $ErrorMessage
 
                Write-Output $Object
 
                $Properties = $null
                $Object     = $null
                $Overview   = $null
                $ErrorMessage = $null
                 
            }
        }
    }
 
    END {}
 
}
