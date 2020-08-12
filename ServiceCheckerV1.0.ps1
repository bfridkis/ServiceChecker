function queryFileNameOut {
    param ([string]$_userPassedFileName)

    $defaultOutFileName = "ServiceCheckerOutput-$(Get-Date -Format MMddyyyy_HHmmss)"
    
    if(!$_userPassedFileName) {          
        write-host "`n* To save to any directory other than the current, enter fully qualified path name. *"
        write-host   "*              Leave this entry blank to use the default file name of               *"
        write-host   "*             '$defaultOutFileName.csv',                                         *"
        write-host   "*                 which will save to the current working directory.                 *"
        write-host   "*                                                                                   *"
        write-host   "*  THE '.csv' EXTENSION WILL BE APPENDED AUTOMATICALLY TO THE FILENAME SPECIFIED.   *`n"
    }

    do { 
        if (!$_userPassedFileName) { $fileName = read-host -prompt "Save Results As [Default=$defaultOutFileName]" }

        $_userPassedFileName = $null

        if ($fileName -and $fileName -eq "Q") { exit }

        if (!$fileName) { $fileName = $defaultOutFileName }

        $pathIsValid = $true
        $overwriteConfirmed = "Y"

        $fileName += ".csv"
                                        
        $pathIsValid = Test-Path -Path $fileName -IsValid

        if ($pathIsValid) {
                        
            $fileAlreadyExists = Test-Path -Path $fileName

            if ($fileAlreadyExists) {

                do {

                    $overWriteConfirmed = read-host -prompt "File '$fileName' Already Exists. Overwrite (Y) or Cancel (N) or Quit (Q)"
                                    
                    if ($overWriteConfirmed -eq "Q") { exit }

                } while ($overWriteConfirmed -ne "Y" -and $overWriteConfirmed -ne "N")
            }
        }

        else { write-output "* Path is not valid. Try again. ('q' to quit.) *" }
    }
    while (!$pathIsValid -or $overWriteConfirmed -eq "N")
    
    return $fileName
}

clear-host

$servicesToCheck = $compsToCheck = $servicesFilePath = $compsFilePath = $checkAllServices = $checkAllNodes = $outputMode = $outputFile = $helpRequest = $null

write-output "`n"
write-output "`t`t`t`t`t`t`t*%*%*  Services Compare *%*%*`n"

([string]$args).split('-') | %{ 
                                if ($_.Split(' ')[0] -eq "Services") { $servicesToCheck = $_.Split(' ')[1].Split(' ') }
                                elseif ($_.Split(' ')[0] -eq "Comps") { $compsToCheck = $_.Split(' ')[1].Split(' ') }
                                elseif ($_.Split(' ')[0] -eq "ServicesFilePath") { $servicesFilePath = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "CompsFilePath") { $compsFilePath = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "CheckAllServices") { $checkAllServices = $true }
                                elseif ($_.Split(' ')[0] -eq "CheckAllNodes") { $checkAllNodes = $true }
                                elseif ($_.Split(' ')[0] -eq "OutputMode") { $UserPassedOutputMode = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "OutputFile") { $userPassedOutputFileName = $_.Split(' ')[1] }
                                elseif ($_.Split(' ')[0] -eq "Help") { $helpRequest = $true }
                              }
if ($outputMode) {
    if ($outputMode -eq "DEFAULT") { $outputMode = 3 }
    if ($outputMode -ne 1 -and $outputMode -ne 2 -and $outputMode -ne 3) { $outputMode = $null }
    if ($outputMode -eq 1) { $CLOutput1 = $true }
}
if ($servicesFilePath) { $usePassedServicesFilePath = $true } else { $usePassedServicesFilePath = $false }
if ($compsFilePath) { $usePassedCompsFilePath = $true } else { $usePassedCompsFilePath = $false }

if (!$helpRequest) {

    $comps = New-Object System.Collections.Generic.List[System.Object]
    $services = New-Object System.Collections.Generic.List[System.Object]
    $readFileOrManualEntryOrAllServices = $readFileOrManualEntryOrAllNodes = $null

    if (!$servicesToCheck -and !$servicesFilePath) {
        do {
            $readFileOrManualEntryOrAllServices = read-host -prompt "Read Input From File (1) or Manual Entry (2) or All Services (3) [Default = All Services]"
            if (!$readFileOrManualEntryOrAllServices) { $readFileOrManualEntryOrAllServices = 3 }
        } 
        while ($readFileOrManualEntryOrAllServices -ne 1 -and $readFileOrManualEntryOrAllServices -ne 2 -and $readFileOrManualEntryOrAllServices -ne 3 -and
               $readFileOrManualEntryOrAllServices -ne "Q")
        if ($readFileOrManualEntryOrAllServices -eq "Q") { exit }
    }
    elseif (!$compsToCheck -and !$compsFilePath) {
        do {
            $readFileOrManualEntryOrAllNodes = read-host -prompt "Read Input From File (1) or Manual Entry (2) or All Nodes (3) [Default = All Nodes]"
            if (!$readFileOrManualEntryOrAllNodes) { $readFileOrManualEntryOrAllNodes = 3 }
        } 
        while ($readFileOrManualEntryOrAllNodes -ne 1 -and $readFileOrManualEntryOrAllNodes -ne 2 -and $readFileOrManualEntryOrAllNodes -ne 3 -and 
               $readFileOrManualEntryOrAllNodes -ne "Q")
        if ($readFileOrManualEntryOrAllNodes -eq "Q") { exit }
    }
        
    if ((($readFileOrManualEntryOrAllServices -or $readFileOrManualEntryOrAllServices -eq 1) -or $usePassedServicesFilePath) -or 
        (($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 1) -or $usePassedCompsFilePath)) {
        if (!$servicesToCheck) {    
            if (!$usePassedServicesFilePath) { 
                write-output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                write-output "`n`tFile must contain one service name per line.`n"
            }
            do {
                if (!$usePassedServicesFilePath) { $servicesFilePath = read-host -prompt "Service Name Input File" }
                if ($servicesFilePath -and $servicesFilePath -ne "Q") { 
                    $fileNotFound = $(!$(test-path $servicesFilePath -PathType Leaf))
                    if ($fileNotFound) { write-output "`n`tFile '$servicesFilePath' Not Found or Path Specified is a Directory!`n" }
                }
                if($usePassedServicesFilePath -and $fileNotFound) {
                    write-output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                    write-output "`n`tFile must contain one hostname per line.`n"
                }
                $usePassedServicesFilePath = $false
            }
            while ((!$servicesFilePath -or $fileNotFound) -and $servicesFilePath -ne "Q")
            if ($servicesFilePath -eq "Q") { exit }
        }

        if (!$compsToCheck) {
            if (!$usePassedCompsFilePath) {
                write-output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                write-output "`n`tFile must contain one hostname per line.`n" 
            }

            do {
                if (!$usePassedCompsFilePath) { $compsFilePath = read-host -prompt "Patches Input File" }
                if ($compsFilePath -and $compsFilePath -ne "Q") { 
                    $fileNotFound = $(!$(test-path $compsFilePath -PathType Leaf))
                    if ($fileNotFound) { write-output "`n`tFile Not Found or Path Specified is a Directory!`n" }
                }
                if($usePassedCompsFilePath -and $fileNotFound) {
                    write-output "`n** Remember To Enter Fully Qualified Filenames If Files Are Not In Current Directory **" 
                    write-output "`n`tFile must contain one patch per line.`n"
                }
                $usePassedCompsFilePath = $false 
            } 
            while ((!$compsFilePath -or $fileNotFound) -and $compsFilePath -ne "Q")
            if ($compsFilePath -eq "Q") { exit }
        }

        if (!$servicesToCheck) { $services = Get-Content $servicesFilePath -ErrorAction Stop }
        if (!$compsToCheck) { $comps = Get-Content $compsFilePath -ErrorAction Stop }
    }
        
    elseif (($readFileOrManualEntryOrAllServices -and $readFileOrManualEntryOrAllServices -eq 2) -or 
        ($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 2)) {

        $servicesCount = 0
        $compCount = 0

        if (!$servicesToCheck -and !$servicesFilePath) {
            write-output "`n`nEnter 'f' once finished. Minimum 1 entry. (Enter 'q' to exit.)`n"
            do {
                $servicesInput = read-host -prompt "Hostname ($($servicesCount + 1))"
                if ($servicesInput -and $servicesInput -ne "F" -and $servicesInput -ne "Q") {
                    $services.Add($servicesInput)
                    $servicesCount++
                    }
            }
            while (($servicesInput -ne "F" -and $servicesInput -ne "Q") -or $servicesCount -lt 1)

            if ($servicesInput -eq "Q") { exit }
		}
    
        if (!$compsToCheck -and !$compsFilePath) { 
            if (!$servicesToCheck) { write-output "============" }
            else { write-output "`n`nEnter 'f' once finished. Minimum 1 entry. (Enter 'q' to exit.)`n" }

            do {
                $compsInput = read-host -prompt "Patch ($($compsCount + 1))"
                if ($compsInput -and $compsInput -ne "F" -and $compsInput -ne "Q") {
                    $comps.Add($compsInput)
                    $compsCount++
                    }
            }
            while (($compsInput -ne "F" -and $compsInput -ne "Q") -or $compsCount -lt 1)

            if ($compsInput -eq "Q") { exit }
        }
    }

    if (($readFileOrManualEntryOrAllNodes -and $readFileOrManualEntryOrAllNodes -eq 3) -or -$checkAllNodes) {
        Get-ADObject -LDAPFilter "(objectClass=computer)" | select-object name | Set-Variable -name compsTemp
        $compsTemp | %{ $comps.Add($_.Name) }
        $compsInput = "TRUE"
    }

    if (!$outputMode) { 
        do { $outputMode = read-host -prompt "`nSave To File (1), Console Output (2), or Both (3)" ;  if (([string]$outputMode) -eq "Q") { exit } } 
        while ($outputMode -ne 1 -and $outputMode -ne 2 -and $outputMode -ne 3) 
    }

    if ($outputMode -eq 3) { queryFileNameOut ############################################


    Get-ADObject -LDAPFilter "(objectClass=computer)" | Select-Object name | Set-Variable -name compsTemp
    $compsTemp | %{ $comps.Add($_.Name) }
    $compsTest = "PCNSMS03", "PCNSMS04"
    Get-Service "SepMasterService" -ComputerName $compsTest | select-object MachineName, Name, Status | group-object MachineName | sort-object Property
}