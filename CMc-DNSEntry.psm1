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

function Undo-DNSEntry {
    
    <#
        .SYNOPSIS
            Reverts a dns change done by this script. After this is done, the backupfile is renamed to [REVERTED]_oldFileName.xml

        .EXAMPLE
            Undo-DNSEntry -BackupFile "C:\Temp\host.example.com-yyyy-mm-dd_hh-mm-ss.xml"
            Undo-DNSEntry -BackupFileSet (Get-ChildItem -Path C:\Temp -Filter "*.xml")
            Get-ChildItem -Path C:\Temp -Filter "*.xml" | Undo-DNSEntry
    #>

        [CmdletBinding(ConfirmImpact="Low")]
        param(
            #Specifies the file where the backup of one transaction is located
            [Parameter(Mandatory=$False, Position=0, ParameterSetName="BackupFile", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [Alias('FullName')]
            [PSCustomObject]$BackupFile,

            #Specifies a whole directory where backups exist so a range of actions can be undone
            [Parameter(Mandatory=$False, Position=0, ParameterSetName="BackupFileSet")]
            [object]$BackupFileSet
        )

        process {

            if ($BackupFile) {

                if ($BackupFile -is [System.IO.FileInfo] -and $BackupFile.FullName.EndsWith(".xml") -and -not $BackupFile.Name.StartsWith("[REVERTED]")) {
    
                    Write-Verbose "Load backup-object from piped object path string $($BackupFile.FullName)"
                    $savedObject = Import-Clixml -Path $BackupFile.FullName
        
                    Write-Verbose -Message "Decide what needs to be reverted"
                    if ($savedObject.action -eq "AddEntry") {
                        $newEntry = $savedObject.newEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Object to delete: $($newEntry.HostName), DNSZone: $($TargetZone), DNS-Server: $($TargetDNSServer)"
                        Remove-DnsServerResourceRecord -InputObject $newEntry -ZoneName $TargetZone -ComputerName $TargetDNSServer -Force
                        Write-Verbose -Message "Removed object"
                        Get-Item -Path $BackupFile.FullName | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed Backupfile"
                    } elseif ($savedObject.action -eq "ChangeEntry") {
                        $oldEntry = $savedObject.oldEntry
                        $newEntry = $savedObject.newEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Loaded objects from Backup"
                        Set-DnsServerResourceRecord -NewInputObject $oldEntry -OldInputObject $newEntry -ZoneName $TargetZone -ComputerName $TargetDNSServer
                        Write-Verbose -Message "Reverted in DNS Server"
                        Get-Item -Path $BackupFile.FullName | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed BackupFile"
                    } elseif ($savedObject.action -eq "RemoveEntry") {
                        $RecordToRestory = $savedObject.deletedEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Loaded objects from Backup"
                        Add-DnsServerResourceRecord -InputObject $RecordToRestory -ZoneName $TargetZone -ComputerName $TargetDNSServer
                        Write-Verbose -Message "Reverted in DNS Server"
                        Get-Item -Path $BackupFile.FullName | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed BackupFile"
                    }
    
                } elseif ($BackupFile -is [string] -and $BackupFile.EndsWith(".xml") -and -not (Get-Item $BackupFile).Name.StartsWith("[REVERTED]")) {
    
                    Write-Verbose "Load backup-object from single path string $($BackupFile)"
                    $savedObject = Import-Clixml -Path $BackupFile
        
                    Write-Verbose -Message "Decide what needs to be reverted"
                    if ($savedObject.action -eq "AddEntry") {
                        $newEntry = $savedObject.newEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Object to delete: $($newEntry.HostName), DNSZone: $($TargetZone), DNS-Server: $($TargetDNSServer)"
                        Remove-DnsServerResourceRecord -InputObject $newEntry -ZoneName $TargetZone -ComputerName $TargetDNSServer -Force
                        Write-Verbose -Message "Removed object"
                        Get-Item -Path $BackupFile | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed Backupfile"
                    } elseif ($savedObject.action -eq "ChangeEntry") {
                        $oldEntry = $savedObject.oldEntry
                        $newEntry = $savedObject.newEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Loaded objects from Backup"
                        Set-DnsServerResourceRecord -NewInputObject $oldEntry -OldInputObject $newEntry -ZoneName $TargetZone -ComputerName $TargetDNSServer
                        Write-Verbose -Message "Reverted in DNS Server"
                        Get-Item -Path $BackupFile | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed BackupFile"
                    } elseif ($savedObject.action -eq "RemoveEntry") {
                        $RecordToRestory = $savedObject.deletedEntry
                        $TargetZone = $savedObject.DNSZone
                        $TargetDNSServer = $savedObject.DNSServer
                        Write-Verbose -Message "Loaded objects from Backup"
                        Add-DnsServerResourceRecord -InputObject $RecordToRestory -ZoneName $TargetZone -ComputerName $TargetDNSServer
                        Write-Verbose -Message "Reverted in DNS Server"
                        Get-Item -Path $BackupFile | Rename-Item -NewName { "[REVERTED]_$($_.Name)" }
                        Write-Verbose -Message "Renamed BackupFile"
                    }
    
                }

            } elseif ($BackupFileSet) {
    
                foreach ($File in $BackupFileSet) {
    
                    if ($File -is [System.IO.FileInfo]) {

                        Undo-DNSEntry -BackupFile $File.FullName
                            
                    }
                    
                }
           }

    }
       
}

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

Export-ModuleMember -Function Set-DNSEntry
Export-ModuleMember -Function Add-DNSEntry
Export-ModuleMember -Function Remove-DNSEntry
Export-ModuleMember -Function Undo-DNSEntry