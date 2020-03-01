#
# Modulmanifest für das Modul "CMc-DNSEntry"
#
# Generiert von: ChaozMc
#
# Generiert am: 01.03.2020
#

@{
RootModule = 'CMc-DNSEntry.psm1'
ModuleVersion = '0.2.0.5'
GUID = 'e592a66c-8e0d-415a-8b67-69809111528f'
Author = 'ChaozMc'
CompanyName = 'is-jo.org'
Copyright = '(c) 2020 ChaozMc'
Description = 'PowerShell module for simplifying tasks with a Microsoft DNS server. With Undo-Function.'
PowerShellVersion = '3.0'
RequiredModules = @('DnsServer')
CmdletsToExport = "*"

	PrivateData = @{

		PSData = @{

			Tags = 'DNSRecord','DNSServer','DNSEntry','DNS-Administration','DNS'
			LicenseUri = 'https://github.com/chaozmc/CMc-DNSEntry/blob/master/LICENSE'
			ProjectUri = 'https://github.com/chaozmc/CMc-DNSEntry/'
			ExternalModuleDependencies = @('DnsServer')

		}

	}

}

