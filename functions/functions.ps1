#Function to check if user is logged in to Azure - Borrowed from Koko's script
function azlogin() {  
    $context = az account show --output json 2>&1 
    if ($context -like "*Please run 'az login'*") {  
        Write-Host "You are not logged in to Azure. Logging in now" -ForegroundColor yellow
        az login --only-show-errors  -o none
        $account = az account show --output json
        if ($account) {
            Write-Host "Successfully logged in to Azure." -ForegroundColor Green
        }
        else {
            Write-Host "Login failed. Exiting."
            Break
        }
    } 
    elseif ($context -like "*No subscription found*") {
        Write-Host "You are not logged in to Azure. Logging in now" -ForegroundColor yellow
        az login --only-show-errors  -o none
        $account = az account show --output json
        if ($account) {
            Write-Host "Successfully logged in to Azure CLI." -ForegroundColor Green
        } 
        else {
            Write-Host "Login failed. Exiting." -ForegroundColor Red
            Break  
        }
    }
    else {  
        Write-Host "You are already connected to Azure CLI" -foregroundcolor Green
    }  
} 

#Function to check user is logged into Azure powershell module
function pslogin() {
    $azModule = Get-Module -ListAvailable -Name Az -ErrorAction SilentlyContinue
    
    if ($azModule) {
        Write-Host "Azure PowerShell module is installed. Continuing..." -ForegroundColor yellow
    }
    
    else {
        Write-Host "Azure Powershell module is not installed. Installing now" -ForegroundColor Yellow
        Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser
        Import-Module Az
        Write-Host "Azure Powershell module installed successfully" -ForegroundColor Green
    }

    $azLoggedIn = Get-AzContext
    
    if (!$azLoggedIn) {
        Write-Host "You are not logged in to Azure Powershell. Logging in now" -ForegroundColor yellow
        Connect-AzAccount -force

        $azLoggedIn = Get-AzContext
        
        if ($azLoggedIn) {
            Write-Host "Successfully logged in to Azure Powershell" -ForegroundColor Green
        }
        else {
            Write-Host "Login failed. Exiting." -ForegroundColor Red
            Break
        }
    }
    
    else {
        $azLoggedIn = Get-AzContext
        $tenants = Get-AzTenant
        $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

        write-host ""
        Write-Host "You are connected to Azure Tenant: $($tenants.Name). Do you want to change?" -ForegroundColor yellow
        $changeTenant = Read-Host "Enter your response to continue (Y/n)"

        if ($changeTenant -eq "Y") {
            Write-host "During this process you will be prompted to sign in twice." -ForegroundColor Yellow
            write-host "The first sign-in forces a tenant change. This is useful for individuals with access to multiple tenants with different accounts." -ForegroundColor Yellow
            write-host "The second sign-in is to authenticate the account and connect to the selected tenant." -ForegroundColor Yellow
            Write-host "Use an account that has access to the Tenant you wish to target" -foregroundcolor Yellow
            Start-Sleep -Seconds 3

            Connect-AzAccount -force

            Clear-Host
            write-host "Getting Tenants..." -ForegroundColor yellow
            $tenants = Get-AzTenant
            $tenantList = @()
            $i = 1

            foreach ($tenant in $tenants) {
                $tenantList += @{
                    "Number"   = $i
                    "TenantId" = $tenant.Id
                    "Name"     = $tenant.Name
                }
                write-host "$i. $($tenant.Name) | $($tenant.TenantId)"
                $i++
            }

            write-host ""
            Write-Host "Enter the number next to the tenant you wish to target"
            Write-Host "If it is not shown in the list enter '0' to manually connect"
            Write-host ""
            $selectedTenant = read-host "Enter tenant index number you wish to connect to."
            $newTenant = $tenantList[$selectedTenant - 1]

            if ($newTenant) {
                if ($selectedTenant -eq 0) {
                    $manualTenant = Read-host "Manually enter the Tenant Id you wish to connect to"

                    Connect-AzAccount -TenantId $manualTenant
                }

                else {
                    connect-AzAccount -tenantId $newTenant.TenantId
                }
            }
        
        }

        else {

        }

    }

    $azLoggedIn = Get-AzContext
    $tenants = Get-AzTenant
    $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

    return @{
        workingSubscription = $azLoggedIn.Subscription.Name
        workingTenant       = $tenants.Name
        tenantId            = $azLoggedIn.Tenant.Id
    }
    
}

function get-subscription {
    param (
        [string]$tenantId
    )

    Clear-Host
    write-host "Getting Subscriptions..." -ForegroundColor yellow
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
    $subList = @()
    $i = 1

    foreach ($sub in $subscriptions) {
        $subList += @{
            "Number"         = $i
            "SubscriptionId" = $sub.Id
            "Name"           = $sub.Name
        }
        write-host "$i. $($sub.Name)"
        $i++
    }

    write-host ""
    Write-Host "Enter the number next to the Subscription you wish to target"
    Write-Host "If it is not shown in the list enter '0' to manually connect"
    Write-host ""
    $selectedSub = read-host "Enter subscription index number you wish to connect to."
    $newSub = $subList[$selectedSub - 1]

    if ($newSub) {
        if ($selectedSub -eq 0) {
            $manualSub = Read-host "Manually enter the Subscription Id you wish to connect to"
            write-host $manualSub

            Set-AzContext -Subscription $manualSub
            pause
        }

        else {
            Set-AzContext -Subscription $newSub.SubscriptionId
        }
    }

    $azLoggedIn = Get-AzContext
    $tenants = Get-AzTenant
    $tenants = $tenants | Where-Object { $_.Id -eq $azLoggedIn.Tenant.Id }

    return @{
        workingSubscription = $azLoggedIn.Subscription.Name
        workingTenant       = $tenants.Name
    }
}

## Function to get subscription dictionaries
function get-dict {
    write-host "Working on creating subscription dictionary ... Please wait" -ForegroundColor Yellow
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }
    $subscriptions | ForEach-Object {
        $_.Name, $_.Id
    }
    $subscriptions | Select-Object Name, Id | Export-Csv -Path .\outputs\subdict.csv -NoTypeInformation

    start-sleep -Seconds 3
    clear-host
}

## Function to get role assignments for a selected management group
function get-single-mg {
    param (
        [string]$mgName
    )
    
    $uniqueFilename = get-date -format "ddMMyyyyHHmmss"
    $scope = "/providers/Microsoft.Management/managementGroups/$mgName"

    # Get role assignments for selected management group
    $mgRoleAssignments = Get-AzRoleAssignment -Scope $scope

    # Iterate output, export to CSV and display in console
    foreach ($mgRoleAssignment in $mgRoleAssignments) {
        if ($mgRoleAssignment.Scope -eq $scope) {
            $inhereted = "N"
        }
        else {
            $inhereted = "Y"
        }

        $mgRoleAssignment | Select-Object -Property DisplayName, ObjectType, RoleDefinitionName, Scope, @{Name = "Inhereted"; Expression = { $inhereted } } | Export-Csv -Path "..\list-azure-role-assignments\outputs\$mgname-$uniqueFilename.csv" -append -NoTypeInformation
        $mgRoleAssignment | format-table -Property DisplayName, ObjectType, RoleDefinitionName, Scope, @{Name = "Inhereted"; Expression = { $inhereted } }
    }

    get-web-export -csv "$mgname-$uniqueFilename"
}

function get-all-mg {
    # Get all management groups
    $managementGroups = Get-AzManagementGroup

    $prepend = "all-mg"
    $uniqueFilename = get-date -format "ddMMyyyyHHmmss" 

    # Iterate through all management groups
    foreach ($mg in $managementGroups) {
        # Get role assignments for each management group
        $mgRoleAssignments += $mgRoleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)"

        # Iterate output, export to CSV and display in console
        foreach ($mgRoleAssignment in $mgRoleAssignments) {
            $mgRoleAssignment | Select-Object -Property DisplayName, ObjectType, RoleDefinitionName, Scope | Export-Csv -Path "..\list-azure-role-assignments\outputs\$prepend-$uniqueFilename.csv" -append -NoTypeInformation
            $mgRoleAssignment | format-table -Property DisplayName, ObjectType, RoleDefinitionName, Scope
        }
    }

    get-web-export -csv "$prepend-$uniqueFilename"
}

function get-single-sub {
    param (
        [string]$sbName,
        [string]$subName
    )

    $uniqueFilename = get-date -format "ddMMyyyyHHmmss"
    $scope = "/subscriptions/$sbName"
    
    # Get role assignments for selected management group
    $sbRoleAssignments = Get-AzRoleAssignment -Scope $scope

    # Iterate output, export to CSV and display in console
    foreach ($sbRoleAssignment in $sbRoleAssignments) {
        if ($sbRoleAssignment.Scope -eq $scope) {
            $inhereted = "N"
        }
        else {
            $inhereted = "Y"
        }

        $sbRoleAssignment | Select-Object -Property DisplayName, ObjectType, RoleDefinitionName, Scope, @{Name = "Inhereted"; Expression = { $inhereted } } | Export-Csv -Path "..\list-azure-role-assignments\outputs\$subname-$uniqueFilename.csv" -append -NoTypeInformation
        $sbRoleAssignment | format-table -Property DisplayName, ObjectType, RoleDefinitionName, Scope, @{Name = "Inhereted"; Expression = { $inhereted } }
    }

}

function get-all-sub {
    param (
        [string]$tenantId
    )

    # Get all subscriptions associated to signed in tenant
    $subscriptions = Get-AzSubscription | Where-Object { $_.TenantId -eq $tenantId }

    # Set count variable
    $subCount = $subscriptions.Count
    $progressCounter = 0
    write-host "You have $subCount subscriptions in your tenant" -ForegroundColor Yellow

    # Create a unique filename for the CSV
    $prepend = "all-sub"
    $uniqueFilename = get-date -format "ddMMyyyyHHmmss" 
    $outputPath = ".\outputs"
    $csvPath = "$outputPath\$prepend-$uniqueFilename.csv"

    # Initialize an array to store role assignments
    $subRoleAssignments = @()

    # Iterate through all subscriptions
    foreach ($sub in $subscriptions) {
        $progressCounter++

        # Show progress
        Write-Progress -Activity "Fetching Role Assignments" -Status "Processing subscription $($sub.Name)" -PercentComplete (($progressCounter / $subCount) * 100)
        
        # Get role assignments for each management group
        $subRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($sub.Id)"

        # Iterate output, export to CSV and display in console
        $subRoleAssignments | Select-Object -Property DisplayName, ObjectId, ObjectType, RoleDefinitionName, Scope | Export-Csv -Path $csvPath -append -NoTypeInformation

    }
}

function get-web-export {
    param (
        [string]$csv,
        [string]$subName
    )

    # Start HTML content
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Role Assignments for $($subName)</title>
    <link rel="stylesheet" href="../css/styles.css">
</head>

<body>
<div class="topcard">Role Assignments for $($subName)</div>
"@

    $csvPath = import-csv -path ".\outputs\$csv.csv"

    foreach ($variable in $csvPath) {
        $htmlContent += @"
        <div class="card">
        <div class="card-header">
"@
        if ($variable.ObjectType -eq "User") {
            $htmlContent += @"
            <img src="../assets/users.svg" alt="Icon" class="md-icon">
"@
        }
        elseif ($variable.ObjectType -eq "ServicePrincipal") {
            $htmlContent += @"
            <img src="../assets/entapp.svg" alt="Icon" class="md-icon">
"@
        }
        elseif ($variable.ObjectType -eq "Group") {
            $htmlContent += @"
            <img src="../assets/groups.svg" alt="Icon" class="md-icon">
"@
        }
        elseif ($variable.ObjectType -eq "Subscription") {
            $htmlContent += @"
            <img src="../assets/subs.svg" alt="Icon" class="md-icon">
"@
        }
        elseif ($variable.ObjectType -eq "ManagedIdentity") {
            $htmlContent += @"
            <img src="../assets/manid.svg" alt="Icon" class="md-icon">
"@
        }

        $htmlContent += @"
        <span class="header-variable">$($variable.DisplayName)</span>
        </div>

        <div class="card-content">
        <br/>
        Role assignment: $($variable.RoleDefinitionName)
        <br/>
        Scope: $($variable.Scope)
        </div>

        <br/>

        <div class="card-buttons">
        </div>
        </div>
        <br/>
"@
    }

    # End HTML content
    $htmlContent += @"
</body>
</html>
"@

    # Output HTML content to a file
    $outputPath = "./outputs/$csv.html"
    $htmlContent | Out-File -FilePath $outputPath

    # Optionally, open the HTML file in the default browser
    Start-Process $outputPath
}
