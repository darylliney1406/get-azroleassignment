## Start logging
try {
    Start-Transcript -Path .\logs\role-assignments.log -Append
}
catch {
    Write-Error "Failed to start transcript: $_"
}

## Pre-requisites
#Load the required functions
try {
    # Dot source functions.ps1
    Write-Host "Locating and loading required functions... Please wait" -ForegroundColor Green
    . ".\functions\functions.ps1"
    
    $functionCheck = Get-Command -Name get-all-mg, get-all-mg, get-single-mg, get-dict, get-single-sub -CommandType Function

    # Check if the function exists
    if ($functionCheck) {
        Write-Host "Functions have been found. Continuing..." -ForegroundColor Green
    } 
        
    else {
        Write-Host "Functions not found. Check that 'functions.ps1' exists in path './functions/functions.ps1'" -ForegroundColor Red
    }
} 
    
catch {
    Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
    Write-host "$_" -ForegroundColor Red
    pause
}

Write-host "Checking Az CLI and PowerShell prereqs... Please wait" -ForegroundColor Yellow

#Call the function 'azlogin'
#azlogin #This is not required as need for dictionary creation is removed, keeping incase of future need
$azContext = pslogin #pslogin is called into a string to pull the values from the function

write-host ""
write-host "Prereqs complete. Starting..." -ForegroundColor Green
start-sleep -Seconds 3

## Main script
#Variables
$termLoop #Deliberately not setting this to force entering the loop

#Menu screen loop
while ($termLoop -ne 0 ) {
    clear-host
    write-host "########################################################################################################################" -ForegroundColor Cyan
    write-host "##                                                                                                                    ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "Get Role Assignments" -NoNewLine -ForegroundColor Darkcyan; write-host "                                                                                              ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewLine; Write-host "********************" -NoNewLine -ForegroundColor Darkcyan; write-host "                                                                                              ##" -ForegroundColor Cyan
    write-host "##                                                                                                                    ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "1. " -ForegroundColor blue -NoNewline; write-host "Get Role Assignments for a Subscription" -NoNewLine -ForegroundColor white; write-host "                                                                        ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "2. " -ForegroundColor blue -NoNewline; write-host "Get Role Assignments for a Management Group" -NoNewLine -ForegroundColor white; write-host "                                                                    ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "3. " -ForegroundColor blue -NoNewline; write-host "Get Role Assignments for a User" -NoNewLine -ForegroundColor white; write-host "                                                                                ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "4. " -ForegroundColor blue -NoNewline; write-host "Get full tenant audit" -NoNewLine -ForegroundColor white; write-host "                                                                                          ##" -ForegroundColor Cyan
    write-host "##                                                                                                                    ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "9. " -ForegroundColor blue -NoNewline; write-host "Choose new Tenant and/or Subscription" -NoNewLine -ForegroundColor white; write-host "                                                                          ##" -ForegroundColor Cyan
    #write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "9. " -ForegroundColor yellow -NoNewline; write-host "Create/Update Dictionaries" -NoNewLine -ForegroundColor white; write-host "                                                                                     ##" -ForegroundColor Cyan
    write-host "##  " -ForegroundColor Cyan -NoNewline; write-host "0. " -ForegroundColor red -NoNewline; write-host "Exit" -NoNewLine -ForegroundColor white; write-host "                                                                                                           ##" -ForegroundColor Cyan
    write-host "##                                                                                                                    ##" -ForegroundColor Cyan
    write-host "########################################################################################################################" -ForegroundColor Cyan
    write-host "You are connected to tenant: " -NoNewLine; write-host $azContext.workingTenant -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $azContext.workingSubscription -ForegroundColor Yellow

    $termLoop = Read-Host "Select an option"

    if ($termLoop -eq 1) {
        clear-host
        write-host "Get role assignments for a Subscription" -ForegroundColor Cyan
        write-host "***************************************" -ForegroundColor Cyan
        write-host ""
        write-host "You are connected to Subscription: " -NoNewline; Write-host $azContext.workingSubscription -ForegroundColor Yellow
        write-host ""
        Write-Host "To search " -noNewLine; write-host $azContext.workingSubscription -ForegroundColor Yellow -noNewLine; write-host " press" -noNewLine; write-host " enter" -ForegroundColor blue
        Write-Host "To search " -noNewLine; write-host "all" -foregroundcolor yellow -noNewLine; write-host " Subscriptions, enter" -NoNewline; write-host " 'all'" -ForegroundColor blue
        write-host ""
        Write-Host "If you would like to search a different subscription, exit to main menu by entering" -NoNewline; write-host " '0'" -ForegroundColor red -NoNewline; write-host " and select option" -NoNewline; write-host " 9" -ForegroundColor blue
        write-host ""
        write-host "To exit back to main menu enter" -NoNewline; write-host " '0'" -ForegroundColor red
        write-host ""
        $sbName = Read-Host "Enter 0 or all to continue or press enter to continue with current subscription"

        if ($sbName -eq 0) {
        }

        elseif ($sbName -eq "all") {
            try {
                clear-host
                get-all-sub -tenantId $azContext.tenantId
            } 
                
            catch {
                Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
                Write-host "$_" -ForegroundColor Red
                pause
            }
        }

        else {
            try {
                #Execute the function 'get-single-sub'
                $sbName = Get-AzSubscription -SubscriptionName $azContext.workingSubscription
                get-single-sub -sbName $sbName.Id -subName $azContext.workingSubscription
            } 
                
            catch {
                Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
                Write-host "$_" -ForegroundColor Red
                pause
            }
        }
    }

    elseif ($termLoop -eq 2) { 
        clear-host
        write-host "Get role assignments for a Management Group" -ForegroundColor Cyan
        write-host "*******************************************" -ForegroundColor Cyan
        write-host ""
        write-host "You are connected to Tenant: " -NoNewline; Write-host $azContext.workingTenant -ForegroundColor Yellow
        write-host ""
        Write-Host "To search a Management Group enter its" -noNewLine; write-host " Id" -ForegroundColor blue
        Write-Host "To search " -noNewLine; write-host "all" -foregroundcolor yellow -noNewLine; write-host " Management Groups, enter" -NoNewline; write-host " 'all'" -ForegroundColor blue
        write-host ""
        write-host "To exit back to main menu enter" -NoNewline; write-host " '0'" -ForegroundColor red
        write-host ""
        $mgName = Read-Host "Enter the MG ID, or 'all' for all Management Groups. Enter '0' to exit"

        if ($mgName -eq 0) {
        }

        elseif ($mgName -eq "all") {
            try {
                #Execute the function 'get-all-mg'
                get-all-mg
                get-web-export
            } 
                
            catch {
                Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
                Write-host "$_" -ForegroundColor Red
                pause
            }
        }

        else {
            try {
                #Execute the function 'get-single-mg'
                get-single-mg -mgName $mgName
                pause
            } 
                
            catch {
                Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
                Write-host "$_" -ForegroundColor Red
                pause
            }
        }
    }

    elseif ($termLoop -eq 3) {

    }

    elseif ($termLoop -eq 4) {

    }

    elseif ($termLoop -eq 9) {
        try {
            clear-host
            write-host "Change Subscription or Tenant" -ForegroundColor Cyan
            write-host "*****************************" -ForegroundColor Cyan
            write-host ""
            write-host "You are connected to tenant: " -NoNewLine; write-host $azContext.workingTenant -ForegroundColor Yellow -NoNewline; write-host " and subscription: " -noNewLine; write-host $azContext.workingSubscription -ForegroundColor Yellow
            write-host ""
            Write-Host "To change Subscriptions enter" -NoNewline; write-host " '1'" -ForegroundColor blue
            Write-Host "To change Tenants enter" -NoNewline; write-host " '2'" -ForegroundColor blue
            write-host ""
            $sbName = Read-Host "Enter 1 or 2"
            
            if ($sbName -eq 1) {
                #Execute the function 'get-subscription'
                $azContext = get-subscription -tenantId $azContext.tenantId
            }

            elseif ($sbName -eq 2) {
                #Execute the function 'pslogin'
                $azContext = pslogin
            }

            else {
                write-host "Invalid selection. Exiting to menu" -ForegroundColor Red
                pause
            }
            
        } 
            
        catch {
            Write-Host "An error occurred. Check logs at './logs/role-assignments.log' for more info" -ForegroundColor Red
            Write-host "$_" -ForegroundColor Red
            pause
        }
    }
}

## Graceful exit - termloop
Write-Host "Bye!" -ForegroundColor Green
Start-Sleep -Seconds 1
Clear-Host
exit
