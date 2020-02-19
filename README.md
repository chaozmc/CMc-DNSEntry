# DNSEntry Module

[![HitCount](http://hits.dwyl.com/chaozmc/chaozmc/CMc-DNSEntry.svg)](http://hits.dwyl.com/chaozmc/chaozmc/CMc-DNSEntry) || [![Status](https://img.shields.io/badge/status-Development-yellow?style=plastic)] || [![GitHub issues](https://img.shields.io/github/issues/chaozmc/CMc-DNSEntry?style=plastic)](https://github.com/chaozmc/CMc-DNSEntry/issues) || [![GitHub license](https://img.shields.io/github/license/chaozmc/CMc-DNSEntry?style=plastic)](https://github.com/chaozmc/CMc-DNSEntry/blob/master/LICENSE) || [![Twitter URL](https://img.shields.io/twitter/url?style=social&url=https%3A%2F%2Fgithub.com%2Fchaozmc%2FCMc-DNSEntry)](https://twitter.com/intent/tweet?text=Check%20this%20out:&url=https%3A%2F%2Fgithub.com%2Fchaozmc%2FCMc-DNSEntry)

A small powershell module for making day-to-day changes in a Microsoft DNS server landscape more convinient

## TOC

<!-- vscode-markdown-toc -->
* **1.** [Purpose of this module](#Purposeofthismodule)
* **2.** [Commands provided by this module](#Commandsprovidedbythismodule)
  * 2.1 [Add-DNSEntry](#Add-DNSEntry)
  * 2.1.1 [Add-DNSEntry Syntax](#Add-DNSEntrySyntax)
    * 2.2 [Set-DNSEntry](#Set-DNSEntry)
      * 2.2.1 [Set-DNSEntry Syntax](#Set-DNSEntrySyntax)
    * 2.3 [Remove-DNSEntry](#Set-DNSEntry)
      * 2.3.1 [Remove-DNSEntry Syntax](#Set-DNSEntrySyntax)
    * 2.4 [Undo-DNSEntry](#Undo-DNSEntry)
      * 2.4.1 [Undo-DNSEntry Syntax](#Undo-DNSEntrySyntax)
* **3.** [Requirements](#Requirements)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## 1. <a name='Purposeofthismodule'></a>Purpose of this module

In my team there's the need for planning (and automating) DNS changes as most of maintenance and upgrade tasks take place during night or weekend. Typically the one who prepared the change isn't the one who is on-call during that changes.
For me that was the intention to have a small script (or module) which can be included into scheduled tasks, do the changes which were requested but have also a kind of "undo" function. This allowes changes to DNS to be prepared and automated but also allowes another person to undo changes done by the script without knowing the original configuration.
For example if it's required to add new dns entries for a new application but the application maintainers want to roll back or undo changes, its not necessary to know which entries where exactely added and where. Just call the Undo-function and provide the xml-backup file.
The same applies for changing the value of A or CNAME records, very common task, but if something went's wrong all you have to do is call the undo function.

## 2. <a name='Commandsprovidedbythismodule'></a>Commands provided by this module

### 2.1. <a name='Add-DNSEntry'></a>Add-DNSEntry

Adds a new record in the a specified dns zone

#### 2.1.1. <a name='Add-DNSEntrySyntax'></a>Add-DNSEntry Syntax

``` Powershell
Add-DNSEntry [-RecordType] <String> [-NewEntry] <String> [-NewValue] <String> [-TargetZone] <String> [-TargetDNSServer] <String> [-BackupDir] <String> [<CommonParameters>]
```

### 2.2. <a name='Set-DNSEntry'></a>Set-DNSEntry

Sets the value of the specified dns record to a new value

#### 2.2.1. <a name='Set-DNSEntrySyntax'></a>Set-DNSEntry Syntax

``` Powershell
Set-DNSEntry [-RecordType] <String> [-DNSRecord] <String> [-NewValue] <String> [-TargetZone] <String> [-TargetDNSServer] <String> [-BackupDir] <String> [<CommonParameters>]
```

### 2.3 <a name='Remove-DNSEntry'></a>Remove-DNSEntry

Removes a specific DNS record in a specified zone on a specified dns server

#### 2.3.1. <a name='Remove-DNSEntry'></a>Remove-DNSEntry Syntax

``` Powershell
Remove-DNSEntry [-RecordType] <String> [-DNSRecord] <String> [-TargetZone] <String> [-TargetDNSServer] <String> [-BackupDir] <String> [<CommonParameters>]
```

### 2.4. <a name='Undo-DNSEntry'></a>Undo-DNSEntry

Reverts a previous made change to the DNS server

#### 2.4.1. <a name='Undo-DNSEntrySyntax'></a>Undo-DNSEntry Syntax

``` Powershell
Undo-DNSEntry [-BackupFile] <String> [<CommonParameters>]
Undo-DNSEntry -BackupFileSet (Get-ChildItem -Path C:\Temp -Filter "*.xml") [<CommonParameters>]
Get-ChildItem -Path C:\Temp -Filter "*.xml" | Undo-DNSEntry
```



## 3. <a name='Requirements'></a>Requirements

This module requires the Microsoft DnsServer Powershell Module to be present on the system.

``` Powershell
Get-WindowsCapability -Online -Name Rsat.Dns.Tools* | Add-WindowsCapability -Online
```

Further it's required (for sure) to have the permissions on the target DNS server and to run in an elevated shell, otherwise PS doesn't allow to load and use the RSAT commands.
