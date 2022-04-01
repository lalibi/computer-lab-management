function Initialize-Workstation {

  $sections = @(
    @{
      "title" = "System";
      "steps" = @(
        @{
          "title" = "Computer name";
          "prompt" = "Current Computer name is '$(hostname)'. Do you want to change it?"
          "block" = {
            $name = Read-Host "Enter the new name"
            Rename-Computer -NewName $name
          }
        },
        @{
          "title" = "Workgroup";
          "prompt" = "Current Workgroup is '$((Get-WmiObject -Class Win32_ComputerSystem).Workgroup)'. Do you want to change it?"
          "block" = {
            $name = Read-Host "Enter the new workgroup name"
            Add-Computer -WorkGroupName $name
          }
        },
        @{
          "title" = "Administrator account";
          "prompt" = "Do you want to create an Administrator account?"
          "block" = {
            $password = Read-Host "Enter password" -AsSecureString
            New-LocalUser "Admin" -FullName "Administrator" -Password $password -Description "Local Administrator"
            Add-LocalGroupMember -Group "Administrators" -Member "Admin"
            Set-LocalUser "Admin" -PasswordNeverExpires 1
          }
        },
        @{
          "title" = "Restart";
          "prompt" = "Now its a good time to restart. Do you want to?"
          "block" = {
            shutdown /r /t 3
            return
          }
        },
        @{
          "title" = "User account";
          "prompt" = "Do you want to restrict the User account?"
          "block" = {
            Add-LocalGroupMember -Group "Users" -Member "Student"
            Remove-LocalGroupMember -Group "Administrators" -Member "Student"
          }
        }
      )
    },
    @{
      "title" = "Software";
      "steps" = @(
        @{
          "title" = "Chocolatey";
          "condition" = { return (-not $env:ChocolateyInstall) }
          "prompt" = "Do you want to install Chocolatey?"
          "block" = {
            # Set-ExecutionPolicy Bypass -Scope Process -Force
            # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
          }
        },
        @{
          "title" = "Programs";
          "initialization" = { $global:programs = @('GoogleChrome', 'Firefox', 'Autoruns', 'Procexp') }
          "prompt" = "Do you want to install '$global:programs'?"
          "block" = {
            choco install $programs -y
          }
        }
      )
    },
    @{
      "title" = "Misc";
      "steps" = @(
        @{
          "title" = "Desktop links";
          "prompt" = "Do you want to move predefined desktop links?"
          "block" = {
            Get-ChildItem 'C:\Users\Student\Desktop\' -Directory | Move-Item 'C:\Users\Public\Desktop'
            Get-ChildItem 'C:\Users\Student\Desktop\' | `
              Where-Object { $_.Extension -eq '.lnk'  } | `
              ForEach-Object { Move-Item $_.FullName 'C:\Users\Public\Desktop' }
            Get-ChildItem 'C:\Users\Public\Desktop\' | `
              ForEach-Object {
                $item = $_.FullName
                $isDirectory = $_.PSIsContainer
                Get-Acl $item | ForEach-Object {
                  $acl = $_
                  $acl.Access | Where-Object { $_.IdentityReference.value -match 'Student$' } | ForEach-Object { $acl.RemoveAccessRule($_) }

                  if ($isDirectory) {
                    $newRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule `
                      -ArgumentList 'Student', 'ReadAndExecute', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
                      "DIR"
                  } else {
                    $newRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule `
                      -ArgumentList 'Student', 'ReadAndExecute', 'Allow'
                    "FILE"
                  }

                  $acl.SetAccessRule($newrule)
                  Set-Acl -Path $item -AclObject $acl
                }
              }
          }
        },
        @{
          "title" = "PS Remoting";
          "prompt" = "Do you want to enable PS Remoting?"
          "block" = {
            Enable-PSRemoting
          }
        }
      )
    }
  );

  $sections | ForEach-Object {
    $section = $_

    Write-Header-1 $section.title

    $step_counter = 0

    $section.steps | ForEach-Object {
      $step = $_

      if ($step.initialization) {
        Invoke-Command -ScriptBlock $step.initialization
      }

      if (($null -eq $step.condition) -or ((Invoke-Command -ScriptBlock $step.condition) -eq $true)) {
        $step_counter += 1

        Write-Header-2 "$($step_counter). $($step.title)"

        $answer = Show-PromptChoice $step.title $step.prompt

        if ($answer) {
          Invoke-Command -ScriptBlock $step.block
        }
      }
    }
  }

  # Lock Wallpaper
  # Disable settings
  # Set hosts
  # Disable sound
  # Clear taskbar
  # Set network to private
  # Time
  # Enable PUP shield?
  # Classroom spy
}

<#
 # Helper Functions
 # -------------------------------------------------- #>

 function Write-Header-1 {
  param(
    [string] $Title
  )

  Write-Host
  Write-Host
  Write-Host ("-" * 50) -ForegroundColor Green
  Write-Host "|* " -ForegroundColor Green -NoNewLine
  Write-Host $Title -NoNewLine
  Write-Host (" " * (50 - $Title.length - 6)) "*|" -ForegroundColor Green
  Write-Host ("-" * 50) -ForegroundColor Green
}

function Write-Header-2 {
  param(
    [string] $Title
  )

  Write-Host
  Write-Host
  Write-Host "|*" -ForegroundColor Green -NoNewLine
  Write-Host " $Title"
  Write-Host "|*" ("-" * 44)  "*|" -ForegroundColor Green
  Write-Host
}

# Windows PowerShell Tip: Adding a Simple Menu to a Windows PowerShell Script - https://goo.gl/O5nZ89
function Show-PromptChoice {
  param(
    [string] $Caption,
    [string] $Message = $null,
    [object[]] $Choices = @("&No", "&Yes"), # @("&Yes", "&No") or @(@("&Yes", "Delete File"), @("&No", "Don't Delete File"))
    [int] $DefaultChoice = 0
  )

  if (($Choices -is [array]) -and ($Choices.length -gt 0)) {
     $_Choices = @()

     $Choices | ForEach-Object {
      if ($_ -is [array]) {
        $_Choices += New-Object System.Management.Automation.Host.ChoiceDescription $_[0], $_[1]
      } else {
        $_Choices += New-Object System.Management.Automation.Host.ChoiceDescription $_
      }
    }
  } else {
    throw New-Object System.IndexOutOfRangeException "No choices given for the prompt."
  }

  return $Host.UI.PromptForChoice($Caption, "$Message`n`n", $_Choices, $DefaultChoice)
}