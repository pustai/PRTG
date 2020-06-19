[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $ComputerName = "localhost",    

    [Parameter()]
    [float]
    $horasRecente = 1.5,

    [Parameter()]
    [string]
    $pw

)

function Get-VMReplicationPoints() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $ComputerName,    
    
        [Parameter()]
        [float]
        $horasRecente,

        [Parameter()]
        [string]
        $pw 

    )
    Try{
        $pwd = convertto-securestring -AsPlainText -Force -String $pw
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "pdr\admin.hyperv",$pwd
        # $Session = New-PSSession -ComputerName $ComputerName -Authentication Negotiate -Credential $cred -ErrorAction stop
        $Session = New-CimSession -ComputerName $ComputerName -Credential $cred -ErrorAction stop
        
    }Catch{
        "2: Não foi possível conectar"
        exit 2
        
    }
    # $GetVM = Invoke-Command -Session $Session -ScriptBlock{ Get-VMReplication}
    $GetVM = Get-VMReplication -CimSession $Session
    foreach ($VM in $GetVM) {
        Try {
            
            $checkPoints = Get-VMSnapshot -VMName $VM.Name -CimSession $Session
            # $checkPoints = Invoke-Command -Session $Session -ArgumentList $VM -ScriptBlock {
            #    Param($VM)
            #    Get-VMSnapshot -VMName $VM.Name
            # }

            $AntigoHoras = (New-TimeSpan -start ($checkPoints | Select-Object -First 1).CreationTime -End (Get-Date)).TotalHours
            $RecenteHoras = (New-TimeSpan -start ($checkPoints | Select-Object -Last 1).CreationTime -End (Get-Date)).TotalHours
            if ($RecenteHoras -ge $horasRecente) {
                $propertyResult = @{
                    Name          = $VM.Name
                    RecentePontos = ($checkPoints | Select-Object -Last 1).CreationTime
                    RecenteHoras  = [math]::Round($RecenteHoras, 0)
                    AntigoPontos  = ($checkPoints | Select-Object -First 1).CreationTime
                    AntigoHoras   = [math]::Round($AntigoHoras, 0)
                    Quantidade    = $checkPoints.Count
                }
                $Result = New-Object -TypeName PSObject -Property $propertyResult
                Write-Output $Result

            }
        }
        catch { }
    }# end: foreach ($VM in $GetVM) {
}

$VM = Get-VMReplicationPoints -horasRecente $horasRecente -ComputerName $ComputerName -pw $pw
if ($VM) {
    $aux = ($VM | Measure-Object | Select-Object -ExpandProperty Count) -As [String]
    $aux += ":"
    $VM | ForEach-Object {
        $aux += " |$($_.Name) - Idade: $($_.RecenteHoras)h| "
    }
    $aux
    
}
else {
    "0: OK"
    
}