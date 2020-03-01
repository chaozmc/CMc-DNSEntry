#Get content of Public folder (as private doesn't contain any functions atm)
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )

#import the files and therefore the functions
Foreach($import in @($Public))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Import of $($import.fullname): $_ failed"
    }
}

#make them available
Export-ModuleMember -Function $Public.Basename