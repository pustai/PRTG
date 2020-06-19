Param([string]$Servername,[string]$Username,[string]$Password)
#
# Requisitos: Instalar módulo PSTerminalServices https://github.com/imseandavis/PSTerminalServices
#
# Copiar arquivos do módulo para: C:\Windows\System32\WindowsPowerShell\v1.0\Modules
# Padrão da instalação é no usuário: C:\Users\administrador\Documents\WindowsPowerShell\modules\PSTerminalServices
#
# Usuário precisa estar no grupo Usuários de Gerenciamento Remoto no servidor local.
#
#    Uso:
#		Session -Servername <IP> -Username <Usuário servidor destino> -Password <Senha do usuário>

# Cria sessão no computador remoto
$pw = convertto-securestring -AsPlainText -Force -String $Password
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username,$pw
$Session = New-PSSession -computername $Servername -Authentication Negotiate -Credential $cred
Invoke-Command -Session $Session {Import-Module PSTerminalServices}
Import-PSSession $Session -Module PSTerminalServices -AllowClobber

# obtém sessões
$sessions = Get-TSSession

$Active = ($sessions |Where-Object {$_.State -match "Active"} |Sort-Object -Unique Username).Count
$Disconnected = ($sessions |Where-Object {$_.State -match "Disconnected"} |Sort-Object -Unique Username).Count
$Total = ($sessions |Where-Object {$_.State -match "Active"}).Count + ($sessions |Where-Object {$_.State -match "Disconnected"}).Count

Write-Host 	"<prtg>"
					"<result>"
						"<channel>Active</channel>"
						"<value>$Active</value>"
					"</result>"
					"<result>"
						"<channel>Disconnected</channel>"
						"<value>$Disconnected</value>"
					"</result>"
					"<result>"
						"<channel>Total</channel>"
						"<value>$Total</value>"
					"</result>"
				"</prtg>"