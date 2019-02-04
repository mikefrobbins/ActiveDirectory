#Requires -Version 3.0 -Modules ActiveDirectory
function Test-MrADUserPassword {

<#
.SYNOPSIS
    Test-MrADUserPassword is a function for testing an Active Directory user account for a specific password.
 
.DESCRIPTION
    Test-MrADUserPassword is an advanced function for testing one or more Active Directory user accounts for a
    specific password.
 
.PARAMETER UserName
    The username for the Active Directory user account.

.PARAMETER Password
    The password to test for.

.PARAMETER ComputerName
    A server or computer name that has PowerShell remoting enabled.

.PARAMETER InputObject
    Accepts the output of Get-ADUser.

.EXAMPLE
     Test-MrADUserPassword -UserName alan0 -Password Password1 -ComputerName Server01

.EXAMPLE
     'alan0'. 'andrew1', 'frank2' | Test-MrADUserPassword -Password Password1 -ComputerName Server01

.EXAMPLE
     Get-ADUser -Filter * -SearchBase 'OU=AdventureWorks Users,OU=Users,OU=Test,DC=mikefrobbins,DC=com' |
     Test-MrPassword -Password Password1 -ComputerName Server01

.INPUTS
    String, Microsoft.ActiveDirectory.Management.ADUser
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding(DefaultParameterSetName='Parameter Set UserName')]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ParameterSetName='Parameter Set UserName')]
        [Alias('SamAccountName')]
        [string[]]$UserName,

        [Parameter(Mandatory)]
        [string]$Password,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(ValueFromPipeline,
                   ParameterSetName='Parameter Set InputObject')]
        [Microsoft.ActiveDirectory.Management.ADUser]$InputObject

    )
    
    BEGIN {
        $Pass = ConvertTo-SecureString $Password -AsPlainText -Force

        $Params = @{
            ComputerName = $ComputerName
            ScriptBlock = {Get-Random | Out-Null}
            ErrorAction = 'SilentlyContinue'
            ErrorVariable  = 'Results'
        }
    }

    PROCESS {
        if ($PSBoundParameters.UserName) {
            Write-Verbose -Message 'Input received via the "UserName" parameter set.'
            $Users = $UserName
        }
        elseif ($PSBoundParameters.InputObject) {
            Write-Verbose -Message 'Input received via the "InputObject" parameter set.'
            $Users = $InputObject
        }

        foreach ($User in $Users) {    
            
            if (-not($Users.SamAccountName)) {
                Write-Verbose -Message "Querying Active Directory for UserName $($User)"
                $User = Get-ADUser -Identity $User
            }
    
            $Params.Credential = (New-Object System.Management.Automation.PSCredential ($($User.UserPrincipalName), $Pass))

            Invoke-Command @Params

            [pscustomobject]@{
                UserName = $User.SamAccountName
                PasswordCorrect =
                    switch ($Results.FullyQualifiedErrorId -replace ',.*$') {
                        LogonFailure {$false; break}
                        AccessDenied {$true; break}
                        default {$true}
                    } 
            }    
    
        }
    
    }      

}