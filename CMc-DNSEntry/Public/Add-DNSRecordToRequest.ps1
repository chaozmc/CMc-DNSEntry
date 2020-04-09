function Add-DNSRecordOperationToRequest {

    <#
        .SYNOPSIS
            Creates a new RecordOperation

        .EXAMPLE
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "ADD" -RecordType "A" -RecordName "test.home.local" -RecordValue "127.0.0.1" -DnsZone "home.local"
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "ADD" -RecordType "CNAME" -RecordName "test.home.local" -RecordValue "test2.home.local" -DnsZone "home.local"
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "DEL" -RecordType "A" -RecordName "test.home.local" -RecordValue "127.0.0.1" -DnsZone "home.local"
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "DEL" -RecordType "CNAME" -RecordName "test.home.local" -RecordValue "test2.home.local" -DnsZone "home.local"
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "CHG" -RecordType "A" -RecordName "test.home.local" -RecordValue "127.0.0.2" -DnsZone "home.local"
            Add-DNSRecordOperationToRequest -RequestObject $Requets -RecordOperation "CHG" -RecordType "CNAME" -RecordName "test.home.local" -RecordValue "test3.home.local" -DnsZone "home.local"
    #>

    [CmdletBinding(ConfirmImpact="Low")]
    [OutputType('CoreRequest.DNSRecord')]
    param(
        # Name of the Reference of the Record
        [Parameter(Mandatory)]
        [CoreReques.DNSRequest]$RequestObject,

        #Requestor Name, preferable the sAMAccountName of a User
        [Parameter(Mandatory)]
        [ValidateSet('ADD','CHG','DEL')]
        [string]$RecordOperation,
        
        #DnsRecord Type, A, CNAME, ...
        [Parameter(Mandatory)]
        [ValidateSet('A','CNAME')]
        [string]$RecordType,

        #The name of the Record
        [Parameter(Mandatory)]
        [string]$RecordName,

        #The value of the Reord
        [Parameter(Mandatory)]
        [string]$RecordValue,

        #in which DNS-Zone should the Record created...
        [Parameter(Mandatory)]
        [string]$DnsZone
        

    )

    begin {
        if (-not (Test-Path -Path $PathToClassDLL) ) {
            Write-Error -Message "Unable to find DLL-File Path($($PathToClassDLL)). Error was: $_" -ErrorAction Stop
        }
        try {
            Add-Type -Path $PathToClassDLL
        }
        catch {
            Write-Error -Message "Unable to load DLL-File Path($($PathToClassDLL)). Error was: $_" -ErrorAction Stop
        }
        Write-Verbose -Message "Successfully loaded DLL-File $($PathToClassDLL)"

        
        
        
    }

    process {
        $Rec = New-Object -TypeName 
        $RequestObject.AddRecordToCollection()

}