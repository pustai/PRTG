<#
.SYNOPSIS

    Get-PRTGVMReplicaStatus.ps1
        Get information about status in Hyper-v Replica

.DESCRIPTION

	Get-PRTGVMReplicaDelay.ps1: Verify each VM on an Hyper-v environment to check if there is a Critical or Warning status with one ou more VMs and format the result to PRTG
	
	Script Version:
		[x] 1.0 - 20.Jun.2020

.PARAMETER ComputerName
    Specifies one Hyper-V hosts from which virtual machines are to be analised

.PARAMETER Username
    Specifies username to start CimSession on the ComputerName

.PARAMETER Password
    Specifies password to start CIMSession on the ComputerName

.EXAMPLE
.\Get-PRTGVMReplicaStatus.ps1
    Parameter field: -ComputerName '%host' -Password '%windowspassword' -username '%windowsdomain\%windowsuser'
    It is posible to use PRTG placeholders to use the informations already defined in PRTG device.

.NOTES
    Author: Gustavo Pustai
    Email:  gustavo@primusti.net
#>
[CmdletBinding()]
param (
	[Parameter()]
	[String]
	$ComputerName,    
    
	[Parameter()]
	[string]
	$username,
    
	[Parameter()]
	[string]
	$password

) # end: param (

Try {
	# start CimSession on the ComputerName
	$pw = Convertto-SecureString -AsPlainText -Force -String $Password
	$Cred = new-object -TypeName System.Management.Automation.PSCredential -Argumentlist $username, $pw
	$Session = New-CimSession -ComputerName $ComputerName -Credential $Cred -ErrorAction stop
	
} # end: Try {
Catch {

	"Cannot connect to: $ComputerName"
	$_.Exception.Message
    	exit 2
	
} # end: Catch {

$VMReplication = Get-VMReplication -CimSession $Session

# Get information about VMs Status
$Normal = $VMReplication | Where-Object { $_.Health -eq "Normal" } | Measure-Object | Select-Object -ExpandProperty Count
$Critical = $VMReplication | Where-Object { $_.Health -eq "Critical" } | Measure-Object  | Select-Object -ExpandProperty Count
$Warning = $VMReplication | Where-Object { $_.Health -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count

# Get the name of VMs in Critical and Warning status
if ($Critical -gt 0) {
	$VMReplication | Where-Object { $_.Health -eq "Critical" } | ForEach-Object {
		[string[]]$criticalMessage += "$($_.VMName) |"
	}
}
if ($Warning -gt 0) {
	$VMReplication | Where-Object { $_.Health -eq "Warning" } | ForEach-Object {
		[string[]]$warningMessage += "$($_.VMName) |"
	}
}

Write-Host 	"<prtg>"
				#Normal
				"<result>" 
					"<channel>Normal</channel>" 
					"<value>$Normal</value>"
					"<LimitMode>1</LimitMode>"
					"<LimitMinError>1</LimitMinError>"
				"</result>"
				#Warning
				"<result>" 
					"<channel>Warning</channel>" 
					"<value>$Warning</value>"
					"<LimitWarningMsg>$warningMessage</LimitWarningMsg>"
					"<LimitMaxWarning>0.5</LimitMaxWarning>"
					"<LimitMode>1</LimitMode>"
				"</result>"
				#Critical
				"<result>" 
					"<channel>Critical</channel>" 
					"<value>$Critical</value>"
					"<LimitErrorMsg>$criticalMessage</LimitErrorMsg>"
					"<LimitMaxError>0.5</LimitMaxError>"
					"<LimitMode>1</LimitMode>"
				"</result>"
			"</prtg>"
