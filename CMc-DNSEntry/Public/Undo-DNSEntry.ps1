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