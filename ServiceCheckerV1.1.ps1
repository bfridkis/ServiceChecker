function queryFileNameOut {
    param ([string]$_userPassedFileName)

    $defaultOutFileName = "ServiceCheckerOutput-$(Get-Date -Format MMddyyyy_HHmmss)"
    
    if(!$_userPassedFileName) {          
        write-host "`n* To save to any directory other than the current, enter fully qualified path name. *"
        write-host   "*              Leave this entry blank to use the default file name of               *"
        write-host   "*                  '$defaultOutFileName.csv',                      *"
        write-host   "*                 which will save to the current working directory.                 *"
        write-host   "*                                                                                   *"
        write-host   "*  THE '.csv' EXTENSION WILL BE APPENDED AUTOMATICALLY TO THE FILENAME SPECIFIED.   *`n"
    }

    do { 
        if (!$_userPassedFileName) { $fileName = Read-Host -prompt "Save Results As [Default=$defaultOutFileName]" }
        else { $fileName = $_userPassedFileName }

        $_userPassedFileName = $null

        if ($fileName -and $fileName -eq "Q") { exit }

        if (!$fileName -or $filename -eq "DEFAULT") { $fileName = $defaultOutFileName }

        $pathIsValid = $true
        $overwriteConfirmed = "Y"

        $fileName += ".csv"
                                        
        $pathIsValid = Test-Path -Path $fileName -IsValid

        if ($pathIsValid) {
                        
            $fileAlreadyExists = Test-Path -Path $fileName

            if ($fileAlreadyExists) {
                Write-Host "`r"
                
                do {
                    
                    $overWriteConfirmed = Read-Host -prompt "File '$fileName' Already Exists. Overwrite (Y) or Cancel (N) or Quit (Q)"
                                    
                    if ($overWriteConfirmed -eq "Q") { exit }

                } while ($overWriteConfirmed -ne "Y" -and $overWriteConfirmed -ne "N")
            }
        }

        else { Write-Output "* Path is not valid. Try again. ('q' to quit.) *" }
    }
    while (!$pathIsValid -or $overWriteConfirmed -eq "N")

    return $fileName
}

clear-host

$servicesToCheck = $compsToCheck = $servicesFilePath = $compsFilePath = $checkAllServices = $checkAllNodes = $outputMode = 
$outputFile = $helpRequest = $QFNInstructionPrinted = $groupByMachineName = $CLOutput1 = $results = $unavailableComps = $null

Write-Output "`n"
Write-Output "`t`t`t`t`t`t`t*%*%*  Service Checker *%*%*"

#Write-Output "`n`nARGS: $args`n`n"

([string]$args).split('-') | %{ 
                                if ($_.Split(' ')[0] -eq "Services") { $servicesToCheck = $_.TrimEnd().Split(' ')[1..$($_.TrimEnd().Split(' ').Length - 1)] }
                                elseif ($_.Split(' ')[0] -eq "Comps") { $compsToCheck = $_.TrimEnd().Split(' ')[1..$($_.TrimEnd().Split(' ').Length - 1)] }
                                elseif ($_.Split(' ')[0] -eq "ServicesFilePath") { $servicesFilePath = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "CompsFilePath") { $compsFilePath = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "CheckAllServices") { $checkAllServices = $true }
                                elseif ($_.Split(' ')[0] -eq "CheckAllNodes") { $checkAllNodes = $true }
                                elseif ($_.Split(' ')[0] -eq "OutputMode") { $outputMode = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "OutputFile") { $userPassedOutputFileName = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "GroupByMachine") { $groupByMachineName = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "Help") { $helpRequest = $true }
                              }
if ($outputMode) {
    if ($outputMode -eq "DEFAULT") { $outputMode = 3 }
    if ($outputMode -ne 1 -and $outputMode -ne 2 -and $outputMode -ne 3) { $outputMode = $null }
    if ($outputMode -eq 1) { $CLOutput1 = $true }
}
if ($servicesFilePath -and !$checkAllServices) { $usePassedServicesFilePath = $true } else { $usePassedServicesFilePath = $false }
if ($compsFilePath -and !$checkAllNodes) { $usePassedCompsFilePath = $true } else { $usePassedCompsFilePath = $false }
if ($checkAllServices) { $sevicesToCheckCL = "ALL" }
if ($servicesToCheck -eq "ALL") { $checkAllServices = $true }
if ($checkAllNodes) { $nodesToCheck = "ALL" }
if ($compsToCheck -eq "ALL") { $checkAllNodes = $true }
if ($groupByMachineName -and ($groupByMachineName -eq 0 -or $groupByMachineName -eq "FALSE" -or $groupByMachineName -eq "N")) { $groupByMachineName = "N" }
elseif ($groupByMachineName -and ($groupByMachineName -eq 1 -or $groupByMachineName -eq "TRUE" -or $groupByMachineName -eq "Y")) { $groupByMachineName = "Y"}
elseif ($groupByMachineName) { $groupByMachineName = $null }

if (!$helpRequest) {

    $readFileOrManualEntryOrAllServices = $readFileOrManualEntryOrAllNodes = $null

    if (!$servicesToCheck -and !$servicesFilePath -and !$checkAllServices) {
        do {
            $readFileOrManualEntryOrAllServices = Read-Host -prompt "`nServices to Check:`n`n`tRead Input From File (1) or Manual Entry (2) or All Services (3) [Default = All Services]"
            if (!$readFileOrManualEntryOrAllServices) { $readFileOrManualEntryOrAllServices = 3 }
        } 
        while ($readFileOrManualEntryOrAllServices -ne 1 -and $readFileOrManualEntryOrAllServices -ne 2 -and $readFileOrManualEntryOrAllServices -ne 3 -and
               $readFileOrManualEntryOrAllServices -ne "Q")
        if ($readFileOrManualEntryOrAllServices -eq "Q") { exit }
    }
    if (($readFileOrManualEntryOrAllServices -and $readFileOrManualEntryOrAllServices -eq 1) -or $usePassedServicesFilePath) {  
        if (!$usePassedServicesFilePath) { 
            Write-Output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
            Write-Output "`n`tFile must contain one service name per line.`n"
            $QFNInstructionPrinted = $true
        }
        do {
            if (!$usePassedServicesFilePath) { $servicesFilePath = Read-Host -prompt "Services Input File" }
            if ($servicesFilePath -and $servicesFilePath -ne "Q") { 
                $fileNotFound = $(!$(test-path $servicesFilePath -PathType Leaf))
                if ($fileNotFound) { Write-Output "`n`tFile '$servicesFilePath' Not Found or Path Specified is a Directory!`n" }
            }
            if($usePassedServicesFilePath -and $fileNotFound) {
                Write-Output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                Write-Output "`n`tFile must contain one hostname per line.`n"
            }
            $usePassedServicesFilePath = $false
        }
        while ((!$servicesFilePath -or $fileNotFound) -and $servicesFilePath -ne "Q")
        if ($servicesFilePath -eq "Q") { exit }
        if ($servicesFilePath -and !$servicesToCheck) { 
        $servicesToCheck = New-Object System.Collections.Generic.List[System.Object]
        $servicesToCheck = Get-Content $servicesFilePath -ErrorAction Stop 
        }
    }
    elseif ($readFileOrManualEntryOrAllServices -and $readFileOrManualEntryOrAllServices -eq 2) {
        Write-Output "`n`rEnter 'f' once finished. Minimum 1 entry. (Enter 'q' to exit.)`n"
        $servicesCount = 0
        $servicesToCheck = New-Object System.Collections.Generic.List[System.Object]
        do {
            $servicesInput = Read-Host -prompt "Service ($($servicesCount + 1))"
            if ($servicesInput -and $servicesInput -ne "F" -and $servicesInput -ne "Q") {
                $servicesToCheck.Add($servicesInput)
                $servicesCount++
                }
        }
        while ($servicesInput -ne "Q" -and ($servicesInput -ne "F" -or $servicesCount -lt 1))

        if ($servicesInput -eq "Q") { exit }
	}

    if (!$compsToCheck -and !$compsFilePath -and !$checkAllNodes) {
        do {
            $readFileOrManualEntryOrAllNodes = Read-Host -prompt "`nNodes to Check:`n`n`tRead Input From File (1) or Manual Entry (2) or All Nodes (3) [Default = All Nodes]"
            if (!$readFileOrManualEntryOrAllNodes) { $readFileOrManualEntryOrAllNodes = 3 }
        } 
        while ($readFileOrManualEntryOrAllNodes -ne 1 -and $readFileOrManualEntryOrAllNodes -ne 2 -and $readFileOrManualEntryOrAllNodes -ne 3 -and 
               $readFileOrManualEntryOrAllNodes -ne "Q")
        if ($readFileOrManualEntryOrAllNodes -eq "Q") { exit }
    }

    if (($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 1) -or $usePassedCompsFilePath) {
        if (!$usePassedCompsFilePath -and !$QFNInstructionPrinted) {
            Write-Output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
            Write-Output "`n`tFile must contain one hostname per line.`r" 
        }
        Write-Output "`r"
        do {
            if (!$usePassedCompsFilePath) { $compsFilePath = Read-Host -prompt "Nodes Input File" }
            if ($compsFilePath -and $compsFilePath -ne "Q") { 
                $fileNotFound = $(!$(test-path $compsFilePath -PathType Leaf))
                if ($fileNotFound) { Write-Output "`n`tFile Not Found or Path Specified is a Directory!`n" }
            }
            if($usePassedCompsFilePath -and $fileNotFound) {
                Write-Output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                Write-Output "`n`tFile must contain one patch per line.`n"
            }
            $usePassedCompsFilePath = $false 
        } 
        while ((!$compsFilePath -or $fileNotFound) -and $compsFilePath -ne "Q")
        if ($compsFilePath -eq "Q") { exit }

        if ($compsFilePath -and !$compsToCheck) { 
        $compsToCheck = New-Object System.Collections.Generic.List[System.Object]
        $compsToCheck = Get-Content $compsFilePath -ErrorAction Stop 
        }
    }    
    elseif ($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 2) { 
        Write-Output "`n`rEnter 'f' once finished. Minimum 1 entry. (Enter 'q' to exit.)`n"    
        $compsCount = 0
        $compsToCheck = New-Object System.Collections.Generic.List[System.Object]
        do {
            $compsInput = Read-Host -prompt "Hostname ($($compsCount + 1))"
            if ($compsInput -and $compsInput -ne "F" -and $compsInput -ne "Q") {
                $compsToCheck.Add($compsInput)
                $compsCount++
            }
        }
        while ($compsInput -ne "Q" -and ($compsInput -ne "F" -or $compsInput -lt 1))

        if ($compsInput -eq "Q") { exit }
    }

    if ($readFileOrManualEntryOrAllServices -and $readFileOrManualEntryOrAllServices -eq 3) { $checkAllServices = $true }

    if (($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 3) -or $checkAllNodes) {
        $compsToCheck = New-Object System.Collections.Generic.List[System.Object]
        Get-ADObject -LDAPFilter "(objectClass=computer)" | Select-Object name | Set-Variable -name compsTemp
        $compsTemp | ForEach-Object { $compsToCheck.Add($_.Name) }
    }

    if (!$outputMode) { 
        do { 
            $outputMode = Read-Host -prompt "`nSave To File (1), Console Output (2), or Both (3) [Default=3]"
            if (([string]$outputMode) -eq "Q") { exit } 
            if (!$outputMode) { $outputMode = 3 }
        }
        while ($outputMode -ne 1 -and $outputMode -ne 2 -and $outputMode -ne 3) 
            
    }
    if ($outputMode -eq 1 -or $outputMode -eq 3) { $outputFileName = queryFileNameOut $userPassedOutputFileName }

    if (!$groupByMachineName -and $compsToCheck.Count -gt 1) { 
        do {
            $groupByMachineName = Read-Host -prompt "`nGroup by Machine Name? (Y or N) [Default=N]" 
            if (!$groupByMachineName) { $groupByMachineName = "N" }
            elseif ($groupByMachineName -eq "Q") { exit }
        }
        while ($groupByMachineName -ne "Y" -and $groupByMachineName -ne "N")
    }

    Write-Output "`nRunning...Please wait..."

    $results = New-Object System.Collections.Generic.List[System.Object]
    $unavailableComps = New-Object System.Collections.Generic.List[System.Object]
    if ($checkAllServices) { 
        $compsToCheck | ForEach-Object {
            $compToCheck = $_
            Try { 
                Get-Service -ComputerName $_ -ErrorAction Stop | Set-Variable resultsTemp
                $results += $resultsTemp
            }
            Catch { $unavailableComps.Add([PSCustomObject]@{'MachineName'=$compToCheck ; 'Exception'=$_.Exception.Message}) }
        }
    }
    else { 
        $compsToCheck | ForEach-Object {
            $compToCheck = $_
            Try { 
                Get-Service -ComputerName $_ -ErrorAction Stop >$null 
                $servicesToCheck | ForEach-Object {
                    Try { $results.Add($(Get-Service $_ -ComputerName $compToCheck -ErrorAction Stop)) }
                    Catch { }
                }
            }
            Catch { $unavailableComps.Add([PSCustomObject]@{'MachineName'=$compToCheck ; 'Exception'=$_.Exception.Message}) }
        }
    }
    $outputResults = New-Object System.Collections.Generic.List[System.Object]
    $results | ForEach-Object { $outputResults.Add([PSCustomObject]@{'Service'=$_.Name ; 'MachineName'=$_.MachineName ; 'Status'=$_.Status})}
   
    if (!$checkAllServices) {
        $outputResultsTemp = New-Object System.Collections.Generic.List[System.Object]
        $compsToCheck | ForEach-Object {
            $compUnreachable = $false
            $thisComp = $_
            $unavailableComps | ForEach-Object  { if ($_.MachineName -eq $thisComp) { $compUnreachable = $true } }
            if (!$compUnreachable) {
                $results | Select-Object MachineName, Name, Status | Where-Object { $_.MachineName -eq $thisComp } |
                    ForEach-Object { $outputResultsTemp.Add([PSCustomObject]@{'Service'=$_.Name ; 'MachineName'=$_.MachineName ; 'Status'=$_.Status})}
                $servicesToCheck | ForEach-Object {
                    $thisService = $_
                    if (!($outputResultsTemp | Select-Object | Where-Object { $_.Service -eq $thisService })) { 
                        $outputResults.Add([PSCustomObject]@{'Service'=$thisService ; 'MachineName'=$thisComp ; 'Status'="Missing"})}
                    }
                $outputResultsTemp.Clear()
            }
        }
    }
    
    if ($groupByMachineName -eq "Y" -and $outputMode -eq 1) { 
        $outputResults | Select-Object @{n='MachineName' ; e={"$($_.MachineName)"}}, @{n='Service' ; e={"$($_.Service)"}}, @{n='Status' ; e={"$($_.Status)"}} | 
            Group-Object MachineName | 
            Select-Object @{n='Count' ; e={"$($_.Count)"}}, @{n='MachineName' ; e={"$($_.Name)"}}, @{n='Group' ; e={$_.Group | % { "$($_.Service)=$($_.Status)"} | Sort-Object $_.Service}} |
            Sort-Object MachineName -OutVariable Export > $null
    }
    elseif ($outputMode -eq 1) { 
        $outputResults | Select-Object @{n='MachineName' ; e={"$($_.MachineName)"}}, @{n='Service' ; e={"$($_.Service)"}}, @{n='Status' ; e={"$($_.Status)"}} | 
            Sort-Object MachineName, Service, Status -OutVariable Export > $null
    }
    elseif ($groupByMachineName -eq "Y") { 
        $outputResults | Select-Object @{n='MachineName' ; e={"$($_.MachineName)"}}, @{n='Service' ; e={"$($_.Service)"}}, @{n='Status' ; e={"$($_.Status)"}} | 
            Group-Object MachineName | 
            Select-Object @{n='Count' ; e={"$($_.Count)"}}, @{n='MachineName' ; e={"$($_.Name)"}}, @{n='Group' ; e={$_.Group | % { "$($_.Service)=$($_.Status)"} | Sort-Object $_.Service}} |
            Sort-Object MachineName -OutVariable Export | Format-Table
    }
    else {
        $outputResults | Select-Object @{n='MachineName' ; e={"$($_.MachineName)"}}, @{n='Service' ; e={"$($_.Service)"}}, @{n='Status' ; e={"$($_.Status)"}} | 
            Sort-Object MachineName, Service, Status -OutVariable Export | Format-Table
    }

    $totalMissingServices = $totalStoppedServices = $totalRunningServices = 0

    $outputResults | ForEach-Object {
        if (!$checkAllServices -and $_.Status -eq "Missing") { $totalMissingServices++ }
        elseif ($_.Status -eq "Stopped") { $totalStoppedServices++ }
        elseif ($_.Status -eq "Running") { $totalRunningServices++ }
    }
    if ($outputMode -eq 1 -or $outputMode -eq 3) { 
        $Export | ConvertTo-CSV -NoTypeInformation | Add-Content -Path $outputFileName
        $outputString = "$(if (!$checkAllServices) {
                            "`r`nTotal Missing: $($totalMissingServices)`r`nTotal Stopped: $($totalStoppedServices)`r`nTotal Running: $($totalRunningServices)"
                           }
                           else {
                            "`r`nTotal Stopped: $($totalStoppedServices)`r`nTotal Running: $($totalRunningServices)"
                           })"
        Add-Content -Path $outputFileName -Value $outputString
        if ($unavailableComps.Count -gt 0) {
            Add-Content -Path $outputFileName -Value "`r`n** Unavailable Comps **"
            $unavailableComps | ConvertTo-CSV -NoTypeInformation | Add-Content -Path $outputFileName
        }
    }
    

    if (!$CLOutput1) {
         if ($outputResults.Count -gt 0) {   
            Write-Host "`r"
            if (!$checkAllServices) { Write-Host "Total Missing: $($totalMissingServices)"}
            Write-Host "Total Stopped: $($totalStoppedServices)"
            Write-Host "Total Running: $($totalRunningServices)"
        }
        
        $unavailableComps | Format-Table @{n='Unavailable Nodes' ; e={"$($_.MachineName)"} ; a="LEFT"},  @{n='Exception' ; e={"$($_.Exception)"} ; a="LEFT"}
        #if ($unavailableComps.Count -gt 0) { $unavailableComps | Select-Object @{n='Unavailable Nodes' ; e={"$($_.MachineName)"}},  @{n='Exception' ; e={"$($_.Exception)"}} | Format-Table -force }

        Write-Host "`nPress enter to exit..." -NoNewLine
        $Host.UI.ReadLine()
    }

}
else {
    clear-host

    write-output "`n"
    write-output "`t`t`t`t`t`t`t`t`t*!*!* Services Checker - Help Page*!*!*"

    write-output "SYNTAX"
    write-output "`tServiceCheckerV1.0.ps1 [-Services <string> {Space seperated services. e.g. `"SEPMasterService xblgamesave`"}]"
    write-output "`t                       [-Comps <string> {Space seperated nodes. e.g. `"alkesc20 devesc10`"}]"
    write-output "`t                       [-ServicesFilePath <string[]>]"
    write-output "`t                       [-CompsFilePath <string[]>]"
    write-output "`t                       [-CheckAllServices <switch>]"
    write-output "`t                       [-CheckAllNodes <switch>]"
    write-output "`t                       [-OutputMode <int32> {1 = Save to File; 2 = Console Output; 3 = Save to File and Console Output}]"
    write-output "`t                       [-OutputFile <string[]> (Note: '.csv' is automatically appended to specified file name. Use `"Default`" for pre-assigned filename.)]"
    write-output "`t                       [-GroupByMachine <string[]> {'Y' or 'TRUE' or 'N' or 'FALSE'}]"
    write-output "`n"

    write-host "Press enter to exit..." -NoNewLine
    $Host.UI.ReadLine()
}

# References
# https://docs.microsoft.com/en-us/dotnet/api/system.collections.hashtable.containsvalue?view=netcore-3.1#System_Collections_Hashtable_ContainsValue_System_Object_
# https://powershellexplained.com/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_object_creation?view=powershell-7
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-content?view=powershell-7
# https://stackoverflow.com/questions/17434151/writing-new-lines-to-a-text-file-in-powershell
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_break?view=powershell-7
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally?view=powershell-7
# https://devblogs.microsoft.com/scripting/use-powershell-to-test-connectivity-on-remote-servers/