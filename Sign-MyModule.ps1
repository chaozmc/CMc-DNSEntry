$mycert = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
$modulefiles = Get-ChildItem -Recurse -Path ".\CMc-DNSEntry" -File
$modulefiles | ForEach-Object { Set-AuthenticodeSignature -Certificate $mycert -TimestampServer http://timestamp.digicert.com -IncludeChain all -FilePath $_.FullName } 

. '.\Publish-MyModule.ps1'