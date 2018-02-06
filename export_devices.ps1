#Load Input Variables
param (
    [Parameter(Mandatory=$True)][string]$queryString,
    [string]$filterTypeString=""
)

#Load the settings file and parse them
#from http://tlingenf.spaces.live.com/blog/cns!B1B09F516B5BAEBF!213.entry
#
Get-Content ".\settings.cfg" | foreach-object -begin {$settings=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $settings.Add($k[0], $k[1]) } }

#save airwave settings to variables
$username = $settings.user
$password = $settings.password
$airwavehost = $settings.airwave_host

#read export parameters
$snmpCommunityString = $settings.snmp_community_string
$type = $settings.type
$authPassword = $settings.auth_password
$snmpv3AuthProtocol = $settings.snmpv3_auth_protocol
$privacyPassword = $settings.privacy_password
$snmpv3PrivacyProtocol = $settings.snmpv3_privacy_protocol
$snmpv3UserName = $settings.snmpv3_username
$enablePassword = $settings.enable_password
$snmpPort = $settings.snmp_port
$telnetUsername = $settings.telnet_username
$telnetPassword = $settings.telnet_password

#check if a filter for Device Type is defined
if($filterTypeString){
    $type_string = $filterTypeString
}else{
    $type_string = $settings.filter_type_string
}

#set TLS Parameter
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#ignore Selfsigned Certs
function Ignore-SelfSignedCerts
{
    try
    {
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
      }
    catch
    {
        Write-Host $_ -ForegroundColor "Yellow"
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
Ignore-SelfSignedCerts

#Create the Login URL
$loginUri = "https://" + $airwavehost + "/LOGIN"
#Create the username password combination
$body = "credential_0=" + $username + "&credential_1=" + $password + "&destination=/index.html"

#Login to AirWave and save the session into the session variable
$loginObj = Invoke-RestMethod -Uri $loginUri -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -SessionVariable session

#Create the Search URL
$apSearchUri = "https://" + $airwavehost + "/ap_search.xml?query=" + $queryString

#Request the device list and save the answer to a variable
$apsObj = Invoke-RestMethod -Uri $apSearchUri -WebSession $session

#Convert the answer from AirWave to xml
[xml]$apsXML = $apsObj

#Create a new CSV object
$csvlist=@()

#Itterate through the list and search for the filter to create a new CSV row
$apsXML.amp_ap_search.record |
%{
    if($_.type_string.ascii_value -eq $type_string)
        {
            $newrow = New-Object PSObject -Property @{
                "IP Address" = $_.icmp_address.ascii_value
                "SNMP Community String" = $snmpCommunityString
                "Name" = $_.name.ascii_value
                "Type" = $type
                "Auth Password" = $authPassword
                "SNMPv3 Auth Protocol" = $snmpv3AuthProtocol
                "Privacy Password" = $privacyPassword
                "SNMPv3 Privacy Protocol" = $snmpv3PrivacyProtocol
                "SNMPv3 Username" = $snmpv3UserName
                "Enable Password" = $enablePassword
                "SNMP Port" = $snmpPort
                "Telnet Username" = $telnetUsername
                "Telnet Password" = $telnetPassword
            }
            $csvlist += $newrow
        }
}

#Output the CSV to CLI
$csvlist | ft -AutoSize

#build the Path to the output file
$path = ".\" + $queryString + "_devices.csv"

#write the CSV list to the output file
$csvlist | Select-Object "IP Address", "SNMP Community String", "Name", "Type", "Auth Password", "SNMPv3 Auth Protocol", "Privacy Password", "SNMPv3 Privacy Protocol", "SNMPv3 Username", "Telnet Username", "Telnet Password", "Enable Password", "SNMP Port" | export-csv -path $path -notypeinformation