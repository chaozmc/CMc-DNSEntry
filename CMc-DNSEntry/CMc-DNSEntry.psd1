@{

    RootModule = 'CMc-DNSEntry.psm1'

    ModuleVersion = '0.2.0.0'

    GUID = 'e592a66c-8e0d-415a-8b67-69809111528f'

    Author = 'ChaozMc'

    CompanyName = 'is-jo.org'

    Copyright = '(c) 2020 ChaozMc'

    Description = 'PowerShell module for simplifying tasks with a Microsoft DNS server'

    PowerShellVersion = '3.0'

    ExternalModuleDependencies = @('DnsServer')

    FunctionsToExport = '*'

    CmdletsToExport = '*'

    VariablesToExport = '*'

    AliasesToExport = '*'

    PrivateData = @{

        PSData = @{

            Tags = @('DNS Entry', 'DNS Server', 'DNS Administration')

            LicenseUri = 'https://github.com/chaozmc/CMc-DNSEntry/blob/master/LICENSE'

            ProjectUri = 'https://github.com/chaozmc/CMc-DNSEntry/'

        }

    }
}