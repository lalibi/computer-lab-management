function Set-Hosts {
    param (
        [string] $Computer = $env:computerName,
        [Parameter(Mandatory=$true)]
        [string] $Username,
        [Parameter(Mandatory=$true)]
        [SecureString] $Password,
        [switch] $ResetFirst = $false
    )

    [PSCredential] $credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    Invoke-Command -ComputerName $Computer -Credential $credentials -ScriptBlock {
        param($ResetFirst)

        $path = "$env:windir\System32\drivers\etc\hosts"
        $entries = @(
            '1v1.lol', 
            '2048game.com',
            'akinator.mobi',
            'crazygames.com' 
            'flipline.com', 
            'friv.cm', 
            'friv.com', 
            'friv20.org',
            'friv2017.us',
            'friv5online.com', 
            'frivoriginal.com',
            'friv-2017.com',
            'gameflare.com',
            'gameforge.com',
            'games.gr',
            'geoguessr.com',
            'gogy.com',
            'gryfek.pl',
            'igrezadecu.com',
            'krunker.io',
            'mathsisfun.com',
            'nitrome.gr',
            'paixnidiaxl.gr',
            'play2048.co',
            'poki.gr', 
            'tanktrouble.com',
            'twoplayergames.org',
            'gazzetta.gr', 
            'stoiximan.gr', 
            'twitch.com',
            'youtube.com'
        )

        if ($ResetFirst) {
            $content = @'
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
'@
        } else {
            $content = Get-Content -Path $path -Raw
        }

        $entries | ForEach-Object {
            $result = $content | Select-String -Pattern $_ 
            if ($ResetFirst -or -not $result) {
                $content += "`n127.0.0.1`t$_"
                # Add also the 'www.', 'en.', & 'gr.' version
                if ($_.Split('.').Count -lt 3) {
                    $content += "`n127.0.0.1`twww.$_"
                    $content += "`n127.0.0.1`ten.$_"
                    $content += "`n127.0.0.1`tgr.$_"
                }
            }          
        }

        Set-Content -Path $path ($content -replace "(?s)`r`n\s*$")
        Get-Content -Path $path
    } -ArgumentList $ResetFirst
}

function Reset-Hosts {
    param (
        [string] $Computer = $env:computerName,
        [Parameter(Mandatory=$true)]
        [string] $Username,
        [Parameter(Mandatory=$true)]
        [SecureString] $Password
    )

    [PSCredential] $credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    Invoke-Command -ComputerName $Computer -Credential $credentials -ScriptBlock { 
        $content = @'
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
'@

        Set-Content -Path $path $content
    }
}

Clear-Host

1..12 | ForEach-Object { 
    $pc = "PC-" + "$_".PadLeft(2, '0')
    Write-Host ('-' * 100) -ForegroundColor Green
    Write-Host $pc -ForegroundColor Green
    Write-Host ('-' * 100) -ForegroundColor Green

    Set-Hosts -Computer $pc -ResetFirst `
        -Username "$Computer\Admin" `
        -Password (ConvertTo-SecureString 'p@p@g0u' -AsPlainText -Force)
}