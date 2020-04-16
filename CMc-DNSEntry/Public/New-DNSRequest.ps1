function New-DNSRequest {

    <#
        .SYNOPSIS
            Creates a new DNSRequest

        .EXAMPLE
            New-DNSRequest -Reference "REQ4711" -Requestor "sAMAccountName" -PathToClassDLL "C:\Temp\CoreRequest.dll" -WorkingDir "C:\Temp\Test"
    #>

    [CmdletBinding(ConfirmImpact="Low")]
    [OutputType('CoreReques.DNSRequest')]
    param(
        # Name of the Reference of the Record
        [Parameter(Mandatory)]
        [string]$Reference,

        #Requestor Name, preferable the sAMAccountName of a User
        [Parameter(Mandatory)]
        [string]$Requestor,
        
        #Path to the CoreRequest.dll File
        [string]$PathToClassDLL,

        #Path to the WorkingDirectory. There the Request will be saved
        [Parameter(Mandatory)]
        [string]$WorkingDir

    )

    begin {
        if ( $PathToClassDLL -eq $null ) {
            if ( Test-Path -Path (Join-Path $PSScriptRoot -ChildPath "CoreRequest.dll")) {
                $PSScriptRoot = Join-Path $PSScriptRoot -ChildPath "CoreRequest.dll"
            }

            if ( Test-Path -Path (Join-Path $PSScriptRoot -ChildPath "..\CoreRequest.dll")) {
                $PSScriptRoot = Join-Path $PSScriptRoot -ChildPath "..\CoreRequest.dll"
            }

            if ( Test-Path -Path (Join-Path $PSScriptRoot -ChildPath "..\includes\CoreRequest.dll")) {
                $PSScriptRoot = Join-Path $PSScriptRoot -ChildPath "..\includes\CoreRequest.dll"
            }

        }
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

        if (-not (Test-Path -Path $WorkingDir) ) {
            try {
                New-Item -Path $WorkingDir -ItemType Directory -ErrorAction Stop | Out-Null #-Force
            }
            catch {
                Write-Error -Message "Unable to create working directory $($WorkingDir). Error was: $_" -ErrorAction Stop
            }
            Write-Verbose -Message "Successfully created working directory $($WorkingDir)"
        }
        
        
    }

    process {
        $newRequest = New-Object -TypeName CoreRequest.DNSRequest

        $newRequest.RequestReference = $Reference
        $newRequest.requestorAccountName = $Requestor

        $newRequest.SaveTo($WorkingDir)

        return $newRequest
    }

}