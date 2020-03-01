function Set-DNSEntry {

    <#
        .SYNOPSIS
            Set the value of an existing dns record to a new value

        .EXAMPLE
            Set-DNSEntry -RecordType A -DNSRecord "host.example.com" -NewValue "127.0.0.1" -TargetZone "example.com" -TargetDNSServer "ns1.example.com" -BackupDir "C:\Temp\"
    #>

 [CmdletBinding(ConfirmImpact="Low")]
    param(
        # RecordType, either A-Record or CNAME-Record
        [Parameter(Mandatory)]
        [ValidateSet('A','CNAME')]
        [string]$RecordType,

        #DNSRecord refers to the Recordname in the DNS Zone
        [Parameter(Mandatory)]
        [string]$DNSRecord,
        
        #Set the record to this value
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
    #Check if $TargetZone is a Primary, otherwise we don't change anything
    if ($TargetZoneObject.ZoneType -ne "Primary") {Write-Error "Not a Primary Zone." -ErrorAction Stop}
    #Check for validity
    if ($DNSRecord.EndsWith($TargetZone)) { $DNSRecord = $DNSRecord.Replace(".$($TargetZone)", "") }
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

    #If RecordType is A then check if NewValue is a valid IP address
    if ($RecordType -eq "A") 
    {
        try {[System.Net.IPAddress]::parse($NewValue)}
        catch { Write-Error $Error[0] -ErrorAction Stop }
    }
    
    #Get the Records from DNSServer
    Write-Verbose -Message "Retrive old record $($DNSRecord) from Type $($RecordType)"
    $old = Get-DnsServerResourceRecord -ComputerName $TargetDNSServer -ZoneName $TargetZoneObject.ZoneName -RRType $RecordType -Name $DNSRecord
    $new = $old.Clone()
    Write-Verbose -Message "Cloned old record into new variable object"
    
   
    if (!($old -eq $null)) {
        switch ($RecordType) {
            "A" {
                $new.RecordData.IPv4Address = [System.Net.IPAddress]::parse($NewValue)
                if (!($old.RecordData.IPv4Address -eq $new.RecordData.IPv4Address)) {
                    Set-DnsServerResourceRecord -NewInputObject $new -OldInputObject $old -ZoneName $TargetZoneObject.ZoneName -ComputerName $TargetDNSServer
                    Write-Verbose -Message "Changed DNS A-Record $($old.HostName) from value $($old.RecordData.IPv4Address) to $($new.RecordData.IPv4Address)"
                    #Save the old Record for restore-reasons
                    $backupObject = @{
                        action = "ChangeEntry"
                        oldEntry=$old
                        newEntry=$new
                        DNSZone=$TargetZoneObject.ZoneName
                        DNSServer=$TargetDNSServer
                    }
                    $backupObject | Export-Clixml -Path "$($BackupDir)$($old.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
                    Write-Verbose -Message "Saved Backpfile to $($BackupDir)$($old.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
                } else {
                    Write-Host "Old and New is the Same" -ForegroundColor Red
                }
            }

            "CNAME" {
                $new.RecordData.HostNameAlias = "$($NewValue)."
                if (!($old.RecordData.HostNameAlias -eq $new.RecordData.HostNameAlias)) {
                    Set-DnsServerResourceRecord -NewInputObject $new -OldInputObject $old -ZoneName $TargetZoneObject.ZoneName -ComputerName $TargetDNSServer
                    Write-Verbose -Message "Changed DNS CName-Record $($old.HostName) from value $($old.RecordData.HostNameAlias) to $($new.RecordData.HostNameAlias)"
                    #Save the old Record for restore-reasons
                    $backupObject = @{
                        action="ChangeEntry"
                        oldEntry=$old
                        newEntry=$new
                        DNSZone=$TargetZoneObject.ZoneName
                        DNSServer=$TargetDNSServer
                    }
                    $backupObject | Export-Clixml -Path "$($BackupDir)$($old.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
                    Write-Verbose -Message "Saved Backpfile to $($BackupDir)$($old.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
                } else {
                    Write-Host "Old and New is the Same" -ForegroundColor Red
                }
            }
        }
    }
}