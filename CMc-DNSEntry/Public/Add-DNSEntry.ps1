function Add-DNSEntry {

    <#
        .SYNOPSIS
            Adds a new record in the a specified dns zone

        .EXAMPLE
            Add-DNSEntry -RecordType A -DNSRecord "newhost.example.com" -NewValue "127.0.0.1" -TargetZone "example.com" -TargetDNSServer "ns1.example.com" -BackupDir "C:\Temp\"
    #>

    [CmdletBinding(ConfirmImpact="Low")]
    param(
        # RecordType, either A-Record or CNAME-Record
        [Parameter(Mandatory)]
        [ValidateSet('A','CNAME')]
        [string]$RecordType,

        #The name of the new entry in the DNS Zone
        [Parameter(Mandatory)]
        [string]$NewEntry,
        
        #Set the new record to this value
        [Parameter(Mandatory)]
        [string]$NewValue,

        #The DNS-Zone which the change takes place. It have to be a primary zone on the server.
        [Parameter(Mandatory)]
        [string]$TargetZone,

        #The DNS-Server to make the change on. Could be any DNS-Server manageable by the DNS-Server PowerShell Module
        [Parameter(Mandatory)]
        [string]$TargetDNSServer,

        #Specifies the directory where the backup-xml file is placed to
        [Parameter(Mandatory)]
        [string]$BackupDir
    )

    #Check if $TargetZone is defined on DNSServer and stop the execution if not
    $TargetZoneObject = Get-DNSServerZone -ComputerName $TargetDNSServer -Name $TargetZone -ErrorAction Stop
    Write-Verbose -Message "Verified that DNS Zone exists: $($TargetZoneObject.ZoneName)"

    #Check if $TargetZone is a Primary, otherwise we don't change anything
    if ($TargetZoneObject.ZoneType -ne "Primary") {Write-Error "Not a Primary Zone." -ErrorAction Stop}
    Write-Verbose -Message "Verified that Zone $($TargetZoneObject.ZoneName) is a primary Zone"

    #Check for validity
    if ($NewEntry.EndsWith($TargetZone)) { $NewEntry = $NewEntry.Replace(".$($TargetZone)", "") }

    #Check plausability
    if ($RecordType -eq "A" -and (!$NewValue.Contains("."))) { Write-Error "Not a valid new Value" -ErrorAction Stop }
    
    #As the BackupTarget is a Folder, check if it ends with \
    if (-not $BackupDir.EndsWith("\")) { $BackupDir = "$($BackupDir)\" }

    #Check if TargetFolder for Backup exists
    if (-not (Test-Path -LiteralPath $BackupDir)) {
        try {
            New-Item -Path $BackupDir -ItemType Directory -ErrorAction Stop | Out-Null #-Force
        }
        catch {
            Write-Error -Message "Unable to create directory $($BackupDir). Error was: $_" -ErrorAction Stop
        }
        Write-Verbose -Message "Successfully created directory $($BackupDir)"
    }
    else {
        Write-Verbose -Message "Backup directory exists"
    }

    #If RecordType is A check if the NewValue is a valid IP
    if ($RecordType -eq "A") 
    {
        Write-Verbose -Message "Check if IP-Address is in valid format"
        try {[System.Net.IPAddress]::parse($NewValue)}
        catch { Write-Error $Error[0] -ErrorAction Stop }
    }

    switch ($RecordType) {
        "A" {  
            Write-Verbose -Message "Add new DNS A-Record: $($NewEntry) with Value $($newValue)"
            $newDnsObject = Add-DnsServerResourceRecordA -ComputerName $TargetDNSServer -ZoneName $TargetZoneObject.ZoneName -Name $NewEntry -IPv4Address ([System.Net.IPAddress]::parse($NewValue)) -PassThru
            #Save the old Record for restore-reasons
            $backupObject = @{
                action="AddEntry"
                newEntry=$newDnsObject
                DNSZone=$TargetZoneObject.ZoneName
                DNSServer=$TargetDNSServer
            }
            $backupObject | Export-Clixml -Path "$($BackupDir)$($newDnsObject.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
            Write-Verbose -Message "Saved Backpfile to $($BackupDir)$($newDnsObject.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
        }

        "CNAME" {
            Write-Verbose -Message "Add new DNS CNAME-Record: $($NewEntry) with Value $($newValue)"
            $newDnsObject = Add-DnsServerResourceRecordCName -ComputerName $TargetDNSServer -ZoneName $TargetZoneObject.ZoneName -Name $NewEntry -HostNameAlias $NewValue -PassThru
            #Save the old Record for restore-reasons
            $backupObject = @{
                action="AddEntry"
                newEntry=$newDnsObject
                DNSZone=$TargetZoneObject.ZoneName
                DNSServer=$TargetDNSServer
            }
            $backupObject | Export-Clixml -Path "$($BackupDir)$($newDnsObject.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
            Write-Verbose -Message "Saved Backpfile to $($BackupDir)$($newDnsObject.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
        }
    }
}