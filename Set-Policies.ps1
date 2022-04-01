function Set-Policies {
    param (
        [string] $Computer = $env:computerName,
        [Parameter(Mandatory=$true)]
        [string] $Username,
        [Parameter(Mandatory=$true)]
        [SecureString] $Password
    )

    [PSCredential] $credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    Invoke-Command -ComputerName $Computer -Credential $credentials -ScriptBlock {
     
        <# This might work when users are not logged in
        # https://www.pdq.com/blog/modify-the-registry-of-another-user/
        # Load ntuser.dat
        reg load HKU\Student C:\Users\Student\NTUSER.DAT

        Push-Location "Registry::HKEY_USERS\Student\Software\Microsoft\Windows\CurrentVersion\Policies"

            if (-not (Test-Path "ActiveDesktop")) {
                New-Item -Name "ActiveDesktop"
            }

            $result = New-ItemProperty -Path "ActiveDesktop" -Name "NoChangingWallPaper" -Value 1 -PropertyType DWORD -Force
            $result.Handle.Close()

        Pop-Location

        [gc]::Collect()
        #Unload ntuser.dat
        reg unload HKU\Student #>

        $sid = (Get-LocalUser 'Student').SID.Value
        $sid

        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        
        if (Test-Path -Path "HKU:\$sid") {
            Push-Location "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Policies"
            #Push-Location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies"

                if (-not (Test-Path "ActiveDesktop")) {
                    New-Item -Name "ActiveDesktop"
                }

                New-ItemProperty -Path "ActiveDesktop" -Name "NoChangingWallPaper" -Value 1 -PropertyType DWORD -Force
                
                if (-not (Test-Path "System")) {
                    New-Item -Name "System"
                }
                
                New-ItemProperty -Path "System" -Name "NoDispAppearancePage" -Value 1 -PropertyType DWORD -Force
                New-ItemProperty -Path "System" -Name "NoColorChoice" -Value 1 -PropertyType DWORD -Force
                New-ItemProperty -Path "System" -Name "NoDispBackgroundPage" -Value 1 -PropertyType DWORD -Force
                New-ItemProperty -Path "System" -Name "NoDispScrSavPage" -Value 1 -PropertyType DWORD -Force
                
                if (-not (Test-Path "Explorer")) {
                    New-Item -Name "Explorer"
                }
                
                New-ItemProperty -Path "Explorer" -Name "NoControlPanel" -Value 0 -PropertyType DWORD -Force
                New-ItemProperty -Path "Explorer" -Name "NoSaveSettings" -Value 1 -PropertyType DWORD -Force
                New-ItemProperty -Path "Explorer" -Name "NoThemesTab" -Value 1 -PropertyType DWORD -Force

                gpupdate

            Pop-Location
        }
    }
}

Clear-Host

1..12 | ForEach-Object { 
    $pc = "PC-" + "$_".PadLeft(2, '0')
    Write-Host ('-' * 100) -ForegroundColor Green
    Write-Host $pc -ForegroundColor Green
    Write-Host ('-' * 100) -ForegroundColor Green

    Set-Policies -Computer $pc `
        -Username "$Computer\Admin" `
        -Password (ConvertTo-SecureString 'p@p@g0u' -AsPlainText -Force)
}