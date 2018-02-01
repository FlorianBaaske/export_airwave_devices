#Load the settings file and parse them
#from http://tlingenf.spaces.live.com/blog/cns!B1B09F516B5BAEBF!213.entry
#
Get-Content ".\settings.cfg" | foreach-object -begin {$settings=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $settings.Add($k[0], $k[1]) } }

$username = $settings.user
$password = $settings.password
$airwavehost = $settings.airwave_host
$network="1"
$type_string="Aruba 2930F-24G-4SFP"

#set TLS Parameter
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#ignore Selfsigned Certs
function Ignore-SelfSignedCerts
{
    try
    {
        Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@
        Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
      }
    catch
    {
        Write-Host $_ -ForegroundColor "Yellow"
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
Ignore-SelfSignedCerts

$loginUri = "https://" + $airwavehost + "/LOGIN"
$body = "credential_0=" + $username + "&credential_1=" + $password + "&destination=/index.html"

$loginObj = Invoke-RestMethod -Uri $loginUri -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -SessionVariable session

$apSearchUri = "https://" + $airwavehost + "/ap_search.xml?query=" + $network

$apsObj = Invoke-RestMethod -Uri $apSearchUri -WebSession $session

[xml]$apsXML = $apsObj

$csvlist=@()

$apsXML.amp_ap_search.record |
%{
    if($_.type_string.ascii_value -eq $type_string)
        {
            $newrow = New-Object PSObject -Property @{
                "IP Address" = $_.icmp_address.ascii_value
                "SNMP Community String" = "public"
                "Name" = $_.name.ascii_value
                "Type" = ""
                "Auth Password" = ""
                "SNMPv3 Auth Protocol" = ""
                "Privacy Password" = ""
                "SNMPv3 Privacy Protocol" = ""
                "SNMPv3 Username" = ""
                "Enable Password" = ""
                "SNMP Port" = ""
                "Telnet Username" = "admin"
                "Telnet Password" = "admin"
            }
            $csvlist += $newrow
        }
}

$csvlist | ft -AutoSize

$path = ".\" + $network + "switches.csv"

$csvlist | Select-Object "IP Address", "SNMP Community String", "Name", "Type", "Auth Password", "SNMPv3 Auth Protocol", "Privacy Password", "SNMPv3 Privacy Protocol", "SNMPv3 Username", "Telnet Username", "Telnet Password", "Enable Password", "SNMP Port" | export-csv -path $path -notypeinformation