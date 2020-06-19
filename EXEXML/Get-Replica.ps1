Param([string]$ServerName=$null)

if (!$ServerName) {

	write-host -ForegroundColor Red "ERRO: Indique um nome de servidor"
	Write-Host ""
	Write-Host ""
	Write-Host "Uso:"
	Write-Host ""
	Write-Host "Replica.ps1 -ServerName <Nome_do_Servidor>"
	Write-Host ""
	Write-Host ""
	
	continue;
	
}

# Cria sessão no computador remoto
$pw = convertto-securestring -AsPlainText -Force -String "KadSft()9t"
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "primusdc\admin.hyperv",$pw
$Session = New-PSSession -computername $ServerName -Authentication Negotiate -Credential $cred
Import-PSSession $Session -Module Hyper-V -AllowClobber

# Obtem VMs que estão sendo replicadas
$VMReplication = Get-VMReplication

# Verifica se cada VM está 
$Normal = @($VMReplication |where {$_.Health -eq "Normal"}).Count
$Critical = @($VMReplication |where {$_.Health -eq "Critical"}).count
$Warning = @($VMReplication |where {$_.Health -eq "Warning"}).Count



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
						"<LimitMaxWarning>0.5</LimitMaxWarning>"
						"<LimitMode>1</LimitMode>"
					"</result>"
					#Critical
					"<result>" 
						"<channel>Critical</channel>" 
						"<value>$Critical</value>"
						"<LimitMaxError>0.5</LimitMaxError>"
						"<LimitMode>1</LimitMode>"
					"</result>"
				"</prtg>"