function Copy-Files {
    param (
        [string] $Computer = $env:computerName,
        [Parameter(Mandatory=$true)]
        [string] $Username,
        [Parameter(Mandatory=$true)]
        [SecureString] $Password,
        [string] $SourcePath,
        [string] $DestinationFolder
    )

    [PSCredential] $credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    <# Invoke-Command -ComputerName $Computer -Credential $credentials -ScriptBlock {
       #netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
       #Set-NetFirewallRule -DisplayGroup "Κοινή χρήση αρχείων και εκτυπωτών" -Enabled True -Profile Any
       Set-NetFirewallRule -Group "@FirewallAPI.dll,-28502" -Enabled True -Profile Any
    } #>

    New-PSDrive -Name S -PSProvider FileSystem -Root "\\$Computer\C$\Users\Student" -Credential $credentials #-Persist
    Copy-Item $SourcePath "S:\$DestinationFolder" -Force -Recurse
}

Clear-Host

1..12 | ForEach-Object { 
    $pc = "PC-" + "$_".PadLeft(2, '0')
    Write-Host ('-' * 100) -ForegroundColor Green
    Write-Host $pc -ForegroundColor Green
    Write-Host ('-' * 100) -ForegroundColor Green

    Copy-Files -Computer $pc `
        -Username "$Computer\Admin" `
        -Password (ConvertTo-SecureString 'p@p@g0u' -AsPlainText -Force) `
        -SourcePath '~\Downloads\AppInventor' `
        -DestinationFolder 'Downloads'
}