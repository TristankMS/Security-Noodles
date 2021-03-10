# EnumLocalGroupMembers.ps1
# Enums members of local security groups on target machines
# all care taken, no responsibility accepted by TristanK

param (
    [Parameter(Mandatory=$false)]
    $Target = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [string] $OutputCSVFile = ".\DomainGroups.csv",
    [Parameter(Mandatory=$false)]
    $targetGroups=("Administrators","*Admins*","*Operators*"),
    [Parameter(Mandatory=$false)]  
	[string] $LogFile = ".\DOMAIN-AD-ACL-Progress.log",
    [Parameter(Mandatory=$false)] 
    [bool]$OverWrite=$true
)
# output function
function Print
{	
	param
	(
		$ComputerName,        
        $ContainerItem,
        $UserName,
        $UserOrGroupName,
		$UserSID,
        $GroupName,
        $GroupSID,
        $UserFlags,
        $AccountDisabled,
        $PwdLastSet,
        $PwdExpired,
        $LastLogin,
        $AccountExpires
	)
	# build PS object for pipeline

    $Object = New-Object PSObject                                       
           $Object | add-member Noteproperty ComputerName    $ComputerName
           $Object | add-member Noteproperty UserOrGroupName $UserOrGroupName
           $Object | add-member Noteproperty ContainerItem   $ContainerItem  # moved down a spot for easy VLOOKUPs
           $Object | add-member Noteproperty UserName        $UserName      
           $Object | add-member Noteproperty GroupName       $GroupName
           $Object | add-member Noteproperty UserSID         $UserSID
           $Object | add-member Noteproperty GroupSID        $GroupSID
           $Object | add-member Noteproperty UserFlags       "$UserFlags"
           $Object | add-member Noteproperty AccountDisabled $AccountDisabled
           $Object | add-member Noteproperty PwdLastSet      $PwdLastSet
           $Object | add-member Noteproperty PwdExpired      $PwdExpired
           $Object | add-member Noteproperty LastLogin       $LastLogin
           $Object | add-member Noteproperty AccountExpires  $accountExpires           

    
    if([string]::IsNullOrEmpty($OutputCSVFile)){
        $Object
    }
    else{
        if($OverWrite -eq $true){
            $Object | Export-Csv -NoTypeInformation -Path $OutputCSVFile
        }
        else{
            $Object | Export-Csv -Append -NoTypeInformation -Path $OutputCSVFile
        }
        $Object
    }
}
start-transcript $LogFile
#$server="localhost","127.0.0.1"
#$server=$env:COMPUTERNAME
#$server

$old_ErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

$Target | % {
	$server = $_.Trim()
	$server
	$computer = [ADSI]"WinNT://$server,computer"

    if($null -eq $targetgroup){ $targetgroup = "*" }

foreach ($targetgroup in $targetGroups){
	
	$computer.psbase.children | where { $_.PSBase.schemaClassName -EQ 'group' -and $_.PSBase.Name -like $targetGroup } | foreach {
		#"`tGroup: " + $Group.Name
		$group =[ADSI]$_.psbase.Path
        $groupName = $group.Name.ToString();
        $parent = $group.Parent.ToString() + "/"  # for dedup purposes
		$group.psbase.Invoke("Members") | foreach {
			$principal = $_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)
            
            $hydrate = [ADSI]$principal
            $accountExp = $null
            
            $principalName = $principal -replace $parent,""
            $principalName = $principalName -replace "WinNT://",""
			$type = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
            $disabled = $hydrate.AccountDisabled
            $flags = $hydrate.UserFlags
            try{
                $flags=$flags.ToString()
                }
                catch{
                $flags=""
                }

            $sid = $hydrate.objectSid
            $displaySID = "--"
            try{
                $dSID = new-object System.Security.Principal.SecurityIdentifier $Sid[0],0
                }
            catch{
                $dSID = "--"
                }
            if($dSID -eq "--"){
                $displaySID = "--"
            }
            else{
                $displaySID = $dSID.Value
            }
            $t=$null
            $pwdLastSet = $null
            if($type -like "user"){
                if($null -ne $hydrate.LastLogin.Value){ $lastLoginTime = $hydrate.LastLogin.Value.ToString()}
                $t=[timespan]::FromSeconds($hydrate.PasswordAge.ToString())
                $pwdLastSet = $t.Days.ToString()
                $pwdExpired = $hydrate.PasswordExpired.ToString()
                $accountExp = $null
                if($null -ne $hydrate.AccountExpirationDate){$accountExp = $hydrate.AccountExpirationDate.ToString()}
            }
            #$disabled = $_.GetType().InvokeMember("get_AccountDisabled", 'GetProperty', $null, $_, $null)
        if($type -like "group"){
            Print  -ComputerName $server -ContainerItem $groupName -GroupName $principalName -GroupSID $displaySID -UserOrGroupName $PrincipalName -UserFlags $flags
            }
        elseif($type -like "user"){
            Print -ComputerName $server -ContainerItem $groupName -UserName $principalName -UserOrGroupName $principalName -UserSID $displaySID -UserFlags $flags -AccountDisabled $disabled -LastLogin $lastLoginTime -PwdLastSet $pwdLastSet -PwdExpired $pwdExpired -AccountExpires $accountExp
        }
        else{
                "NonUser"
                Print -ComputerName $server -ContainerItem $groupName -UserName $principalName -UserOrGroupName $principalName
		    }
	     }
        }	
    }
}
$ErrorActionPreference = $old_ErrorActionPreference 

stop-transcript
