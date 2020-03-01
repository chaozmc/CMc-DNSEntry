function Remove-DNSEntry {
    
    <#
        .SYNOPSIS
            Removes a specific DNS record in a specified zone on a specified dns server

        .EXAMPLE
            Remove-DNSEntry -RecordType A -DNSRecord "oldhost.example.com" -TargetZone "example.com" -TargetDNSServer "ns1.example.com" -BackupDir "C:\Temp\"
    #>

    [CmdletBinding(ConfirmImpact="Low")]
    param(
        # RecordType, either A-Record or CNAME-Record
        [Parameter(Mandatory)]
        [ValidateSet('A','CNAME')]
        [string]$RecordType,

        #The name of the new entry in the DNS Zone
        [Parameter(Mandatory)]
        [string]$DNSRecord,
        
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
   if ($DNSRecord.EndsWith($TargetZone)) { $DNSRecord = $DNSRecord.Replace(".$($TargetZone)", "") }

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

    #Get the Records from DNSServer
    Write-Verbose -Message "Retrive object record $($DNSRecord) from Type $($RecordType)"
    $objectToDelete = Get-DnsServerResourceRecord -ComputerName $TargetDNSServer -ZoneName $TargetZoneObject.ZoneName -RRType $RecordType -Name $DNSRecord

    Write-Verbose -Message "Remove the DNS record: $($DNSRecord)"
    Remove-DnsServerResourceRecord -ZoneName $TargetZoneObject.ZoneName -ComputerName $TargetDNSServer -InputObject $objectToDelete -Force
    #Save the old Record for restore-reasons
    $backupObject = @{
        action="RemoveEntry"
        deletedEntry=$objectToDelete
        DNSZone=$TargetZoneObject.ZoneName
        DNSServer=$TargetDNSServer
    }
    $backupObject | Export-Clixml -Path "$($BackupDir)$($objectToDelete.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"
    Write-Verbose -Message "Saved Backpfile to $($BackupDir)$($objectToDelete.HostName).$($TargetZoneObject.ZoneName)-Backup-$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").xml"

}