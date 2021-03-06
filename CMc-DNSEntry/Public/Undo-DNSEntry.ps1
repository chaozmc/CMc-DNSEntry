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
# SIG # Begin signature block
# MIIkMAYJKoZIhvcNAQcCoIIkITCCJB0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSGe7+lXTRe3GuD62EU4PFWTn
# WTWggh+EMIIFmjCCA4KgAwIBAgITewAAABoCdAHBKk3x3wAAAAAAGjANBgkqhkiG
# 9w0BAQsFADBLMQswCQYDVQQGEwJBVDERMA8GA1UEChMISG9tZS5ORVQxDDAKBgNV
# BAsTA1BLSTEbMBkGA1UEAxMSSG9tZS1ORVQtSXNzdWluZ0NBMB4XDTIwMDIyOTIy
# MTUxNloXDTIxMDIyODIyMTUxNlowOTEWMBQGA1UEAxMNTWFya3VzIEZlaWxlcjEf
# MB0GCSqGSIb3DQEJARYQbWFya3VzQGZlaWxlci5tZTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAOxABIEfaHBiA9a1G38A/Tan0pkK3PSlQWn+Fr8in5MI
# Zwkmd9zSVedbGRYwoUbQfdWAJsxKBO22t6PZ9H3DnVa9Eojh3zNOdwAIXdHaPmuk
# dCgcy20Hiv2wmy1R1MIcUSWlqZWtYDgBOeecRR6yFpW/LJJU9uC38IgZtdTXQo2p
# oStrNmhhM5kaoWju8xCQJ0OafH4xQItFr0F+NWqoAVigUPa9JCjgF4/U/cA0BbAI
# q/iCbKs5ufDobl2qaslVTtTcWJWPaLqSrvI+yD0meRiS/UCPbeS6MESpTpqDb08h
# qYjewZns/Ee3FLuTD1xkSMFTsuvB8kvCGyaPiDpfV7kCAwEAAaOCAYcwggGDMDwG
# CSsGAQQBgjcVBwQvMC0GJSsGAQQBgjcVCITd3wa37hH5gTaCgeQ4gfXXM4F3hOTP
# CoOQ6hECAWQCAQUwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeA
# MBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFCnaeKyua3E9
# 8hKmw3dGfne0+r99MB8GA1UdIwQYMBaAFFeweyP0Hnd1/oeRP15l252FZQOkMDwG
# A1UdHwQ1MDMwMaAvoC2GK2h0dHA6Ly9wa2kuaXMtam8ub3JnL0hvbWUtTkVULUlz
# c3VpbmdDQS5jcmwwRwYIKwYBBQUHAQEEOzA5MDcGCCsGAQUFBzAChitodHRwOi8v
# cGtpLmlzLWpvLm9yZy9Ib21lLU5FVC1Jc3N1aW5nQ0EuY3J0MDoGA1UdEQQzMDGg
# HQYKKwYBBAGCNxQCA6APDA1tYXhAZmVpbGVyLm1lgRBtYXJrdXNAZmVpbGVyLm1l
# MA0GCSqGSIb3DQEBCwUAA4ICAQAdgqEz1QpAs1e88Gq1omdqckEl7k1GaGcf72E+
# LyCrjnxaLJShc1K20hGBO8/UfLZ7GXH1wPwmf+jGtED/OLBprg8MPLAVdrOb1g2f
# qNCSRavxAlQS3sBEDE8hmQiXzULeHdkJEUoOi468ztj5aJu6f0lL+EygwT6Zkp9d
# ZpSq39UW2+lh5VPTxPqx4i1mMOn5TyIX0Oa6lRww13rqtuLXIWzAmfpyfujyGudN
# eio6VRfnTSJh83W8w0eH8kJUlXBMJYWo69CdSVcwEqd9TjRyDohBcIFPBkspDOIs
# zgZtBtRbxqSxRJlxKghG7w1pdTFt50S6T/hZ7+ZXVR1q1nzhJ6tvvEfKil0J1/Gq
# Ut2o79UN95hRufSFdwiVB2GPSaJfYLXR/13GOZBAMAdqPxbomF2IrM2jgfWjScua
# 7IMHU5sV4P9pU3dKKQvn6mH/lhnJRp9ZkTtHeFXmVdr4aXEm2IaVKcXYTn8260vK
# mbtJHmF/9qY3hr6vGVYKx8/tEP+6g7l2rIIQ7BdNarY+j9YPZhk7Nvu0SBKyFU62
# l3o50iFt53tHWZduzo5dkFmytGCvJmYsKVd6dv5Re+gR/NK02usGQ3Tnf7+Qn/t7
# UUWh9CiL2NdRRr0NsY9dT3Av7AJS5FqnB4vN5TQkRyrSzJxt6vkdOD7AMadQDfUy
# Z5bOZjCCBekwggPRoAMCAQICEH9pM8dmpj+XTv+RhvVQmNIwDQYJKoZIhvcNAQEL
# BQAwSDELMAkGA1UEBhMCQVQxETAPBgNVBAoTCEhvbWUuTkVUMQwwCgYDVQQLEwNQ
# S0kxGDAWBgNVBAMTD0hvbWUtTkVULVJvb3RDQTAeFw0yMDAyMjkwNDA0MTVaFw0z
# MTAyMjgwNDE0MTFaMEgxCzAJBgNVBAYTAkFUMREwDwYDVQQKEwhIb21lLk5FVDEM
# MAoGA1UECxMDUEtJMRgwFgYDVQQDEw9Ib21lLU5FVC1Sb290Q0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQCzwQo2IMxDvfqVWWIMbmU1tnnsCtg565ml
# n3VwAhDe3I+r/uN3e1X10qut9kvnaw7/WRy8F4Purzdvk8QnSRjasfKpHg6a1kpy
# dp5rFSS5VkylC+33cNIhvNssQhVlLU7eGT3C50WfFuX89XgAwlSpSWGc2RX+CMfl
# EhJLjBsO2v5iEl7EcgAe8F8D3uUJTD5p5ZP5HgAFjq6Z7aqWRwXYEKFlPYOM9Woq
# aOX8XqJNju9BJhHqFPywiHXQ7Y4Bp0GZ7l/WIhglyTMi16179JN1AzWmIN3ktVfM
# HzOsu9Q5vRAa7iomr59M8bzpCoUbpQmSxR4VPDArtsoUi8ELQGYNHPgPeAMwFVj0
# rUkbj7ILjowylWerA15ylRW9ZHCm0+InX0dPaB2RKHNh0oXFb/eyE9VxtzcrKOSc
# QsLOYRvft78jjMFrldhfLoyrP8lB1oUlev77rACDyF2MYLISFchTXuiDM5ndGTj0
# d15xqC+SYQxLY2rKZNOWqVYw50tvJDNExOdUjDX+mVQqyKT7cnFQ871qhSujQWKV
# oF7KTLmfvDpe3/yCh3ARaUMQQ6mQo6p++f7ojQqCfwU2SeWxZUvvqhGwIOkx5VWZ
# o9WzFxou9Pc4/EGGLQi8DHZfsMRt0WM0YYAeDaUElbPrlNr2fSrb2BvxqaYfrmaU
# lout6YmUkQIDAQABo4HOMIHLMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB0GA1UdDgQWBBQC3G9N1yMyLPYstA6ThvS4NXWfizAQBgkrBgEEAYI3FQEEAwIB
# ADB6BgNVHSAEczBxMG8GBFUdIAAwZzA6BggrBgEFBQcCAjAuHiwATABlAGcAYQBs
# ACAAUABvAGwAaQBjAHkAIABTAHQAYQB0AGUAbQBlAG4AdDApBggrBgEFBQcCARYd
# aHR0cDovL3BraS5pcy1qby5vcmcvY3BzLmh0bWwwDQYJKoZIhvcNAQELBQADggIB
# AG+EQJ32ogk3yz5spLdm9BfLyD3ITkTZlP1L6kVecnrayxT8xLLoOvSFgrSe88mG
# 1ueEco7JKQeAueDLPTkOF6O1spqLcgky5y6vQqak71K60LPFv1ZiCnEvUqx6QpN9
# /oCjV62hpn/bNmqXUBs/6DK5eQHtfycJsdormt85tC0gJod2tYZ/f002xcu6geqx
# fJwJcH7MXVB+W7ma6jqa7hz/i9CGBWLR79cNXM8nW9je7JPgh5UYQooaQaVo04VQ
# TNoIfhw5HBgrVbTJt1McHH6rOn5a7Az/YPAKjzwqDU+CCO2fNkd5sXMifsastovV
# vu5HlV+ZEfbUbZrZygDyKhpgv3EOaa6Xh+bviQ5ViNRXNoS8bOKTDBGiWZ4x2MG3
# J6/Z3Puzf5Pa/FiPBX7K2pPutScRQ8tnvUHvHe5wz7bsRSVfnB7Gj5cL2OqNaeM1
# qZVZEPL48HdY0Hkvm4C0jcp3ZCfMSoS4u4fYSvkTsdaM8JGwyawD1AS/UvZU9wGw
# MmfcgpsjLObMS3ECSzD1F8YcuZjIeyxLVXb1afAvbKbgwpH7+yfDy+yScyHxoV0z
# wggUZXYEmTYYAwqtSvke5tIN8yOiS1nXKMojt6Ipirs0mvNowWCAmXCqB7j/H8af
# TWYQRWBudVeNmT1QLO0li+R0B3I8xZyfRE5wukxgjnowMIIGajCCBVKgAwIBAgIQ
# AwGaAjr/WLFr1tXq5hfwZjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEwHhcNMTQxMDIyMDAw
# MDAwWhcNMjQxMDIyMDAwMDAwWjBHMQswCQYDVQQGEwJVUzERMA8GA1UEChMIRGln
# aUNlcnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRpbWVzdGFtcCBSZXNwb25kZXIwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjZF38fLPggjXg4PbGKuZJdTvM
# buBTqZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ2YPOb2bu3cuF6V+l+dSHdIhEOxnJ
# 5fWRn8YUOawk6qhLLJGJzF4o9GS2ULf1ErNzlgpno75hn67z/RJ4dQ6mWxT9RSOO
# hkRVfRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkCYYhhchhoubh87ubnNC8xd4EwH7s2
# AY3vJ+P3mvBMMWSN4+v6GYeofs/sjAw2W3rBerh4x8kGLkYQyI3oBGDbvHN0+k7Y
# /qpA8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM0AjMa+xiQpGsAsDvpPCJEY93AgMB
# AAGjggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUB
# Af8EDDAKBggrBgEFBQcDCDCCAb8GA1UdIASCAbYwggGyMIIBoQYJYIZIAYb9bAcB
# MIIBkjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzCC
# AWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABp
# AHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABl
# AHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBp
# AEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5
# AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBj
# AGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQBy
# AGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5
# ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwHwYDVR0jBBgwFoAU
# FQASKxOYspkH7R7for5XDStnAs0wHQYDVR0OBBYEFGFaTSS2STKdSip5GoNL9B6J
# wcp9MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMDigNqA0hjJodHRwOi8vY3JsNC5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDB3BggrBgEFBQcBAQRr
# MGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEF
# BQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEQ0EtMS5jcnQwDQYJKoZIhvcNAQEFBQADggEBAJ0lfhszTbImgVybhs4jIA+A
# h+WI//+x1GosMe06FxlxF82pG7xaFjkAneNshORaQPveBgGMN/qbsZ0kfv4gpFet
# W7easGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuXx/Y/5+IRQaa9YtnwJz04HShvOlIJ
# 8OxwYtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2FKvzj0OncZ0h3RTKFV2SQdr5D4HR
# mXQNJsQOfxu19aDxxncGKBXp2JPlVRbwuwqrHNtcSCdmyKOLChzlldquxC5ZoGHd
# 2vNtomHpigtt7BIYvfdVVEADkitrwlHCCkivsNRu4PQUCjob4489yq9qjXvc2EQw
# gga2MIIEnqADAgECAhMUAAAAAlIy3wKzg9vZAAAAAAACMA0GCSqGSIb3DQEBCwUA
# MEgxCzAJBgNVBAYTAkFUMREwDwYDVQQKEwhIb21lLk5FVDEMMAoGA1UECxMDUEtJ
# MRgwFgYDVQQDEw9Ib21lLU5FVC1Sb290Q0EwHhcNMjAwMjI5MDQxMzE2WhcNMjUw
# MjI4MDQyMzE2WjBLMQswCQYDVQQGEwJBVDERMA8GA1UEChMISG9tZS5ORVQxDDAK
# BgNVBAsTA1BLSTEbMBkGA1UEAxMSSG9tZS1ORVQtSXNzdWluZ0NBMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtTOnkK1Q+dAxBLfWf3lAEqQZM8GvLJQr
# vkUQKpjn+H44kTXFBZ1o3Tb7ChyaI9IYAkMRRFT1c37i25IDUKptiOkYUHqfRhv4
# vn7osFFDPrOQDPhx+3OegChSTIox6g6q2xXNhdrgEhNmmjO25XZx+Ci3El92JXFZ
# iy/GGzLNQu8lY7SLo/TI/uHy894ALXxQlKlz6W36xiSzQvZcJ5DyjoDbT7iAZQ0a
# 5mBJaddp0hRL4spnAE9rDkuxVorC233z3/+evfFQBqA9fpD/O0za3OZCe35xIveL
# 5ZeKmdjEV9afAZ3aoufYd0lQNbH7va8cyvTrT0qNoigPmtdcN/TUZyLMmlV7cxbH
# izxHBKvHjzzqZrB3lZd0ZYWz106TrUZzWxvm6/zTWD5ZoErRy0Dz6XFJPjOGw1PH
# tWP4x7RamnWvNj6kjGhJhUjYTtdjaVzzkAZJKtsw21V7D9/lR5hZt8XIdrGINAo8
# VwzMLWetmpMio2YuyV0c8muMQiyY11131JqDKCnsljxGUaJeZY2jV01kyvFbwdX4
# KxXvKetW03Z0BARAvkWoEVg9oF2HRcDW2I7qy/I3ivlmglajtcL99lMJUtY7yCdX
# 7PV0GaGbGR+V0j4nQr+2MgQkaO+BATAQ0lS0VbGq0ZFntOvi8FbYo4eC4lFGRc19
# nH5MOYupw8UCAwEAAaOCAZQwggGQMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQW
# BBRXsHsj9B53df6HkT9eZdudhWUDpDCBgQYDVR0gBHoweDB2BgsrBgEEAYOuaQEB
# ATBnMDoGCCsGAQUFBwICMC4eLABMAGUAZwBhAGwAIABQAG8AbABpAGMAeQAgAFMA
# dABhAHQAZQBtAGUAbgB0MCkGCCsGAQUFBwIBFh1odHRwOi8vcGtpLmlzLWpvLm9y
# Zy9jcHMuaHRtbDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBQC3G9N1yMyLPYstA6ThvS4
# NXWfizA5BgNVHR8EMjAwMC6gLKAqhihodHRwOi8vcGtpLmlzLWpvLm9yZy9Ib21l
# LU5FVC1Sb290Q0EuY3JsMEQGCCsGAQUFBwEBBDgwNjA0BggrBgEFBQcwAoYoaHR0
# cDovL3BraS5pcy1qby5vcmcvSG9tZS1ORVQtUm9vdENBLmNydDANBgkqhkiG9w0B
# AQsFAAOCAgEAS4t2bVFy7rSTt8WiR/+Xt2mNb5MVX0RnnPbAwRxP6VWG3q0cJK28
# Qlv/IcF21pG8VUAPAWIWUftLbAPqyn1Z83AruUzFetqWKNUupQqWUMRo1KkCPkCg
# us18bFzLf0+xgXhyk7amppPEZ0L+YbAGsi0bmZmGg+OpgIdMlFX+/WqdxlZjD3TN
# aJMb4V+JyVPVOhQUZ6/NWd+RPeJpBwNmb1iQ0VgD7Yek7VDVrP+AvIdZEKpJ6tA2
# 8g4iSQGW33dlZpIn+2CU/lzn0Tf+f0IkvJBh8X4tZTUHWcFVz0AA2u1FJ5ID8HgV
# QIeTgMGhefhVcOnHM31atGD99uicc/cR3Eai6kM5zEJs+MIG5CYu0yi6x+j3Beed
# vqL+fVrXEKaw4IBB+4fwIVhAuEjBxgfeHPdhDEvRovy47VvZQTnqJa4ucqOISFVe
# XqUIQMOadefsKUf+kuUTbjAQFfJV0VvgkiI7HGbgTrWkqn34HuaH6S05rmv6NXLD
# j0VnuNNYgHtuHu9pcQqzpKLXw9AyRO0w+A1R680OwXnxCAXggUL0RdGGjU3NzwQd
# I+2DfiIk0V5jk2eECGvO5r9X1ZYZ4hvUqCcU6fVDpvKXP6fbYsgOMHYD14XwGk16
# dB9kuYcelyg03ZiR5CBYcMsWWEphGB+yj9GISea+O99EJqWdNlAhFCswggbNMIIF
# taADAgECAhAG/fkDlgOt6gAK6z8nu7obMA0GCSqGSIb3DQEBBQUAMGUxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAe
# Fw0wNjExMTAwMDAwMDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# ITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAOiCLZn5ysJClaWAc0Bw0p5WVFypxNJBBo/JM/xN
# RZFcgZ/tLJz4FlnfnrUkFcKYubR3SdyJxArar8tea+2tsHEx6886QAxGTZPsi3o2
# CAOrDDT+GEmC/sfHMUiAfB6iD5IOUMnGh+s2P9gww/+m9/uizW9zI/6sVgWQ8DIh
# FonGcIj5BZd9o8dD3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ0MZdEkKB4YNugnM/
# JksUkK5ZZgrEjb7SzgaurYRvSISbT0C58Uzyr5j79s5AXVz2qPEvr+yJIvJrGGWx
# wXOt1/HYzx4KdFxCuGh+t9V3CidWfA9ipD8yFGCV/QcEogkCAwEAAaOCA3owggN2
# MA4GA1UdDwEB/wQEAwIBhjA7BgNVHSUENDAyBggrBgEFBQcDAQYIKwYBBQUHAwIG
# CCsGAQUFBwMDBggrBgEFBQcDBAYIKwYBBQUHAwgwggHSBgNVHSAEggHJMIIBxTCC
# AbQGCmCGSAGG/WwAAQQwggGkMDoGCCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFW
# HoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBm
# AGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0
# AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAv
# AEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0
# AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAg
# AGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBw
# AG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBu
# AGMAZQAuMAsGCWCGSAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/AgEAMHkGCCsGAQUF
# BwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMG
# CCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3Js
# My5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2
# hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMB0GA1UdDgQWBBQVABIrE5iymQftHt+ivlcNK2cCzTAfBgNVHSMEGDAW
# gBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEARlA+ybco
# JKc4HbZbKa9Sz1LpMUerVlx71Q0LQbPv7HUfdDjyslxhopyVw1Dkgrkj0bo6hnKt
# OHisdV0XFzRyR4WUVtHruzaEd8wkpfMEGVWp5+Pnq2LN+4stkMLA0rWUvV5PsQXS
# Dj0aqRRbpoYxYqioM+SbOafE9c4deHaUJXPkKqvPnHZL7V/CSxbkS3BMAIke/MV5
# vEwSV/5f4R68Al2o/vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmMT/tZ4CMP0qquAHzu
# nEIOz5HXJ7cW7g/DvXwKoO4sCFWFIrjrGBpN/CohrUkxg0eVd3HcsRtLSxwQnHcU
# wZ1PL1qVCCkQJjGCBBYwggQSAgEBMGIwSzELMAkGA1UEBhMCQVQxETAPBgNVBAoT
# CEhvbWUuTkVUMQwwCgYDVQQLEwNQS0kxGzAZBgNVBAMTEkhvbWUtTkVULUlzc3Vp
# bmdDQQITewAAABoCdAHBKk3x3wAAAAAAGjAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUaRA+oKT6
# +sKH+48/8VQvOgVJPB4wDQYJKoZIhvcNAQEBBQAEggEAbpSMkUVUGosTtvR2QmG1
# QO9fLsVG3EQv5LrDv/sZRStKVWAROov/oIDI9vQNQMRfso2tGcY84Em93W059Tct
# 6iAzpFYM6w8bvkZKvxan8CvL/eR4I9SygDEs8VQ9rAp1eBnU750mZerw7VyCFqas
# 4tb3wQYgSIxDmle+DJoZYm4oSMumXNZHxkUKnqVaJUEkgokVJ43F2KKet48Zfj8k
# uCCO7vp83Q+f1epAqscdHdESRSNBz+3EAsoexgXnI6OqCaPFk31e0z8FIxFw591K
# aBHGznLji2hoRD255/vbnif80NUU2tvqwmV5P+k987AkPc3i3i9S/IvCYLnYbqK0
# paGCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGaAjr/WLFr
# 1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMjAwMzAxMTk1MzI5WjAjBgkqhkiG9w0BCQQxFgQUc6II
# UmeDk9EL3Epx3NhJriBGb7EwDQYJKoZIhvcNAQEBBQAEggEAH1K8yiCbYt8QEKNz
# cqmo//0XGpIzPlqoGtCRN8PuD8oAsfSMasYdIvbq4onNQpLNPSaN7DUjVFeomVlr
# cq+T/UHdTS8p1E5g7m/sCvY4ybswEDZ9B0O9SUWZ7IfxRcjWxFjK5u4NLzzZ79Cq
# 7O080k6yeFOBpH9U7/2/XgKZDXSwyAdbUSrEcScthLDNnD0ur/ubeMpQrAi7eTGm
# IPHkiPVxrhh1rYD60JEEWzol/3JUdii/XXS3pK7kKRP9hNWtzI+3QK/WsmRvuRXo
# fOcExs9/Fr4Kn62S06FOXeoYdStNRj65OXE9b+43Ef4d4s8twk8GDufrvM/Y2toO
# BVVySQ==
# SIG # End signature block
