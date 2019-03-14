param(
    $CSVFile = "SubOutput.csv"
)

remove-item $CSVFile -Force

$subs = Get-AzSubscription

foreach($sub in $subs){
    Select-AzSubscription $sub
    $allRoles = Get-AzRoleAssignment 
    foreach($role in $allRoles)
    {
        $role | Add-Member -Type NoteProperty -Name SubscriptionName -Value $sub.Name 
        $role | Add-Member -Type NoteProperty -Name SubscriptionID -Value $sub.Id
    }
    $allRoles | export-CSV $CSVFile -Append -NoTypeInformation
}