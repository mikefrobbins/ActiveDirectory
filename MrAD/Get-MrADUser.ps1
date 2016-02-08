#Requires -Version 3.0
function Get-MrADUser {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [String[]]$UserName
    )
    
    PROCESS {
        
        foreach ($user in $UserName){
            
            $Search = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(samaccountname=$user))"

            foreach ($user in $($Search.FindAll())){
                
                $stringSID = (New-Object -TypeName System.Security.Principal.SecurityIdentifier($($user.Properties.objectsid),0)).Value
                $objectGUID = [System.Guid]$($user.Properties.objectguid)

                [pscustomobject]@{
                    DistinguishedName = $($user.Properties.distinguishedname)
                    Enabled = (-not($($user.GetDirectoryEntry().InvokeGet('AccountDisabled'))))
                    GivenName = $($user.Properties.givenname)
                    Name = $($user.Properties.name)
                    ObjectClass = $($user.Properties.objectclass)[-1]
                    ObjectGUID = $objectGUID
                    SamAccountName = $($user.Properties.samaccountname)
                    SID = $stringSID
                    Surname = $($user.Properties.sn)
                    UserPrincipalName = $($user.Properties.userprincipalname)
                }

            }

        }

    }

}