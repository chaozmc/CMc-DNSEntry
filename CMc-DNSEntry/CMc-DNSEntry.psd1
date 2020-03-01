@{

    RootModule = 'CMc-DNSEntry.psm1'

    ModuleVersion = '0.2.0.0'

    GUID = 'e592a66c-8e0d-415a-8b67-69809111528f'

    Author = 'ChaozMc'

    CompanyName = 'is-jo.org'

    Copyright = '(c) 2020 ChaozMc'

    Description = 'PowerShell module for simplifying tasks with a Microsoft DNS server'

    PowerShellVersion = '3.0'

    RequiredModules = @(
        @{
            ModuleName = "DnsServer";
            ModuleVersion = "2.0.0.0";
            Guid = "46f598e5-9907-42b2-afbb-68e5f7e34604"
        }
    )

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