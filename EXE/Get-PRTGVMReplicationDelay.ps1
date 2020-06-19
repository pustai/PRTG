<#
.SYNOPSIS

    Get-PRTGVMReplicaDelay.ps1
        Get information about delay in Hyper-v Replica

.DESCRIPTION

    Get-PRTGVMReplicaDelay.ps1: Verify each VM on an Hyper-v environment to check if there is a delay with one ou more servers and format the result to PRTG

    Warning and error limits must be configured on the sensor value channel.

.PARAMETER ComputerName
    Specifies one Hyper-V hosts from which virtual machines are to be analised

.PARAMETER Username
    Specifies username to start CimSession on the ComputerName

.PARAMETER Password
    Specifies password to start CIMSession on the ComputerName

.PARAMETER minuteDelayTime
    Specifies the delay time considered to show as Warning or Error

.EXAMPLE
.\Get-PRTGVMReplicaDelay.ps1
    Parameter field: -ComputerName '%host' -Password '%windowspassword' -username '%windowsdomain\%windowsuser' -minuteDelayTime 90
    It is posible to use PRTG placeholders to use the informations already defined in PRTG device.
    Expected output
    2: |VM01: 97 min||VM02: 156 min|
    or
    0: OK

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
    $password,
    
    [Parameter()]
    [int]
    $minuteDelayTime

) # end: param (

function Get-VMReplicationPoints() {

    Try {
        # start CimSession on the ComputerName
        $Password = Convertto-SecureString -AsPlainText -Force -String $Password
        $Cred = new-object -TypeName System.Management.Automation.PSCredential -Argumentlist $username, $password
        $Session = New-CimSession -ComputerName $ComputerName -Credential $Cred -ErrorAction stop
        
    } # end: Try {
    Catch {

        "Cannot connect to: $ComputerName"
        exit 2
        
    } # end: Catch {

    $GetVM = Get-VMReplication -CimSession $Session
    foreach ($VM in $GetVM) {
        Try {

            # Get informations about checkpoints on each VM
            $checkPoints = Get-VMSnapshot -VMName $VM.Name -CimSession $Session -ErrorAction Stop
            $firstTime = (New-TimeSpan -start ($checkPoints | Select-Object -First 1).CreationTime -End (Get-Date)).TotalMinutes
            $lastTime = (New-TimeSpan -start ($checkPoints | Select-Object -Last 1).CreationTime -End (Get-Date)).TotalMinutes
            
            # Compare if last checkpoint is older then defined on minuteDelayTime
            if ($lastTime -ge $minuteDelayTime) {

                $propertyResult = @{
                    Name          = $VM.Name
                    RecentePontos = ($checkPoints | Select-Object -Last 1).CreationTime
                    lastTime      = [math]::Round($lastTime, 0)
                    AntigoPontos  = ($checkPoints | Select-Object -First 1).CreationTime
                    firstTime     = [math]::Round($firstTime, 0)
                    Quantidade    = $checkPoints.Count
                }
                $Result = New-Object -TypeName PSObject -Property $propertyResult
                Write-Output $Result

            } # end: if ($lastTime -ge $horasRecente) {

        } # end: try
        catch { 
            $_.ExceptionMessage
        }

    } # end: foreach ($VM in $GetVM) {

} # end: function Get-VMReplicationPoints() {

$VM = Get-VMReplicationPoints

# Format result for prtg sensor understand
if ($VM) {
    # if there´s VM with last checkpoint older then minuteDelayTime show in PRTG
    $aux = ($VM | Measure-Object | Select-Object -ExpandProperty Count) -As [String]
    $aux += ":"
    $VM | ForEach-Object {
        $aux += " |$($_.Name): $($_.lastTime) min| "
    }
    $aux
    
} # end: if ($VM) {
else {
    # if there´s no VM with last checkpoint older then minuteDelayTime show OK
    "0: OK"
} # end: else {
