
<#
.SYNOPSIS
  Script providing a GUI to drive the native security utility WDAC (Windows Defender Application Control).
.DESCRIPTION
  This script is only valid for Windows 10/Server version 1903 and above.
  GUI is executed, choose via the drop-down menu the desired profile and finally select the mode on which this profile should be applied.his script will <Elaborate on what the sc  ript does
.PARAMETER
  The script provides a GUI, the user is prompted to select the desired profile and choose between audit and applied mode.
.INPUTS
  It needs policies in .BIN format in order to apply them and RefreshPolicy.exe software to apply the desired mode.
.OUTPUTS
  A log file in the temp directory of the user running the script
.NOTES
  Version:        1
  Author:         Fehdi Turki
  Creation Date:  September 2021
  Purpose/Change: Initial script development
#>

#requires -version 3.0

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

# Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$LogNumber            = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
$Log_Path             = "$($env:TEMP)\$($MyInvocation.MyCommand.Name) $($LogNumber).log"
$ScriptVersion        = "1"

# Define the location of profiles
$Remote_Location_WDAC = "C:\Share\WDAC\Profiles\"

# Define the location location containing RefreshPolicyTool.exe
$RefreshPolicyTool    = "C:\Share\WDAC\RefreshPolicyTool.exe"

# Define the location of Code Integrity folder
$BIN_Destination      = $env:windir+"\System32\CodeIntegrity\CIPolicies\Active\"

# $Define the location of policies for each profile
$Audit_XML            = $Remote_Location_WDAC + $Selected_Profile + "\WDAC_Audit.xml"
$Audit_temp           = $Remote_Location_WDAC + $Selected_Profile + "\WDAC_Audit_Temp.xml"
$Audit_BIN            = $Remote_Location_WDAC + $Selected_Profile + "\WDAC_Audit.bin"

$Enforce_XML          = $Remote_Location_WDAC + $Selected_Profile + "\WDAC_Enforce.xml"
$Enforce_BIN          = $Remote_Location_WDAC + $Selected_Profile + "\WDAC_Enforce.bin"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Message_Box {

   # Defines global parameters to be used in box messages.
   # Allows customization of box messages.
    param(
        [string]$Title,
        [string]$Message,
        [string]$Button,
        [string]$Icon
    )

    $Button_Codes = @{
        "OK" = 0; 
        "OKCancel" = 1; 
        "AbortRetryIgnore" = 2; 
        "YesNoCancel" = 3; 
        "YesNo" = 4; 
        "RetryCancel" = 5
    }
    
    $Icon_Codes = @{
        "IconErreur" = 16; 
        "IconQuestion" = 32; 
        "IconAvertissement" = 48; 
        "IconInformation" = 64
    }

    # Load the Windows.Forms library of graphical objects
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    
    # Display the dialog box and return the return value (button pressed)
    $Reponse = [System.Windows.Forms.MessageBox]::Show($Message, $Title , $Button_Codes[$Button], $Icon_Codes[$Icon])
    Return $Reponse

    ## Sources : 
    # https://cnf1g.com/afficher-un-messagebox-en-powershell/
    # https://ss64.com/ps/messagebox.html
}

Function GUI {

    # Initialization of PowerShell GUI.
    Add-Type -AssemblyName System.Windows.Forms

    # Creating the window.
    $Form_WDAC                           = New-Object system.Windows.Forms.Form
    $Form_WDAC.ClientSize                = '600,350'
    $Form_WDAC.text                      = "WDAC Configuration"
    $Form_WDAC.BackColor                 = "#ffffff"

    # Add a title 
    $Title                               = New-Object system.Windows.Forms.Label
    $Title.location                      = New-Object System.Drawing.Point(20,5)
    $Title.text                          = "Utility to change the state of WDAC on the machine" 
    $Title.Font                          = 'Century Ghotic,11'
    $Title.AutoSize                      = $true
    $Title.width                         = 25
    $Title.height                        = 10

    # Add some details
    $Description                         = New-Object system.Windows.Forms.Label
    $Description.location                = New-Object System.Drawing.Point(20,50)
    $Description.text                    = "If you need help or submit an issue please go to GitHub.com/Fehdi9"
    $Description.Font                    = 'Century Ghotic,11'
    $Description.AutoSize                = $true
    $Description.width                   = 400
    $Description.height                  = 40

    # List of profiles
    $Drop_down_list_title                = New-Object system.Windows.Forms.Label
    $Drop_down_list_title.location       = New-Object System.Drawing.Point(20,120)
    $Drop_down_list_title.Font           = 'Century Ghotic,11'
    $Drop_down_list_title.text           = "Please select a policy profile to apply to the machine."
    $Drop_down_list_title.AutoSize       = $true
    $Drop_down_list_title.width          = 25
    $Drop_down_list_title.height         = 10

    # Empty box containing the profiles
    $Drop_down_list                      = New-Object system.Windows.Forms.ComboBox
    $Drop_down_list.location             = New-Object System.Drawing.Point(25,150)
    $Drop_down_list.text                 = ""
    $Drop_down_list.Font                 = 'Century Ghotic,15'
    $Drop_down_list.width                = 350
    $Drop_down_list.autosize             = $true

    # Dynamic list at the path defined in the declarations containing all profiles 
    $Dynamic_Profile_List = Get-ChildItem -Path $Remote_Location_WDAC

    Foreach ($profile in $Dynamic_Profile_List){

        $Drop_down_list.Items.Add($profile)
    }

    # Left button which action "enforced" mode
    $Left_button                         = New-Object system.Windows.Forms.Button
    $Left_button.location                = New-Object System.Drawing.Point(35,200)
    $Left_button.Font                    = 'Century Ghotic,10'
    $Left_button.text                    = "Enforced mode"
    $Left_button.width                   = 150
    $Left_button.height                  = 50
    $Left_button.BackColor               = "#ffffff"
    $Left_button.ForeColor               = "#000"
    $Left_button.DialogResult            = [System.Windows.Forms.DialogResult]::Yes

    # Right button which action "Audit" mode
    $Right_button                        = New-Object system.Windows.Forms.Button
    $Right_button.location               = New-Object System.Drawing.Point(200,200)
    $Right_button.text                   = "Audit mode"
    $Right_button.Font                   = 'Century Ghotic,10'
    $Right_button.width                  = 150
    $Right_button.height                 = 50
    $Right_button.BackColor              = "#ffffff"
    $Right_button.ForeColor              = "#000"
    $Right_button.DialogResult           = [System.Windows.Forms.DialogResult]::OK

    $Form_WDAC.controls.AddRange(@($Title,$Description,$Drop_down_list_title,$Right_button,$Left_button,$Drop_down_list))

    # Depending on the user action, the script launches different functions
    $Left_button.Add_Click({ Enforce_Policy $Drop_down_list.SelectedItem })
    $Right_button.Add_Click({ Audit_policy $Drop_down_list.SelectedItem })

    Clear-Host

    [void]$Form_WDAC.ShowDialog()
}

Function Enforce_Policy { 
   
    $Selected_profile = $Drop_down_list.SelectedItem

    <# 
    # Troubleshoot
 
    Write-Host $Emplacement_Strategie
    Write-Host $Audit_XML
    Write-Host $Enforce_XML
    Write-Host $Audit_BIN
  
    Test-Path $Emplacement_Strategie
    Test-Path $Audit_XML
    Test-Path $Enforce_
    Test-Path $Audit_BIN
    #>

    # If the selected profile does not contain any strategy, the script stops and displays an error box.
    Foreach ($Path in @($Audit_XML, $Audit_BIN, $Enforce_XML)) {
    
        If (-Not (Test-Path $Path)) {
            Message_Box -Title "Erreur - Policies missing" -Message "The path $Path cannot be found. This path corresponds to a necessary strategy" -Button "OK" -Icon "IconErreur"
            Return $False
        }
    }

    Write-Host "Creating a temporary auditing strategy based on user usage." -ForegroundColor Green
    New-CIPolicy -audit -Level Hash -FilePath $Audit_temp -UserPEs

    Write-Host "Mutualization of the existing policy with the temporarily created one." -ForegroundColor Green
    Merge-CIPolicy -PolicyPaths $Audit_XML, $Audit_temp -OutputFilePath $Enforce_XML

    Write-Host "Deleting the temporary policy." -ForegroundColor Green
    Remove-Item -Path $Audit_temp -Force -Confirm:$false

    Write-Host "Removing option (3) - Audit mode." -ForegroundColor Green
    Set-RuleOption -FilePath $Enforce_XML -Option 3 -Delete

    Write-Host "Converting the strategy (.XML) to binary (.BIN)." -ForegroundColor Green
    ConvertFrom-CIPolicy $Enforce_XML $Audit_BIN

    Write-Host "Copying the binary file (.BIN) to its Windows application location." -ForegroundColor Green
    Copy-Item -Path $Audit_BIN -Destination $DestinationBinary

    Write-Host "Updating the current WDAC policy." -ForegroundColor Green
    Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName Update -Arguments @{FilePath = $DestinationBinary}
    
    Write-Warning "The operation was successful, please reboot the PC to apply the new policy."  

    End_Process  
}

#<------------------------- Fonction - Définir la stratégie WDAC en mode 'Audit'     ------------------------->#
Function Audit_policy {

    $Selected_Profile                             = $Drop_down_list.SelectedItem

    <#
    #Bloc de debug des chemins utilisées

    Write-Host $Remote_Location_WDAC
    Write-Host $Enforce_XML
    Write-Host $Audit_XML
    Write-Host $Audit_BIN
    
    Test-Path $Remote_Location_WDAC
    Test-Path $Enforce_XML
    Test-Path $Audit_XML
    Test-Path $Audit_BIN
    #>

    # If the selected profile does not contain any strategy, the script stops and displays an error box.
    Foreach ($Path in @($Audit_XML, $Audit_BIN, $Enforce_XML)) {
    
        If (-Not (Test-Path $Path)) {
            Message_Box -Title "Erreur - Policies missing" -Message "The path $Path cannot be found. This path corresponds to a necessary strategy" -Button "OK" -Icon "IconErreur"
            Return $False
        }
    }
    
    Write-Host "Duplicates the current rules for the 'Applied' strategy." -ForegroundColor Green
    cp $Enforce_XML $Audit_XML -Force -Confirm:$false

    Write-Host "Added option '3' (Audit mode)." -ForegroundColor Green
    Set-RuleOption -FilePath $Audit_XML -Option 3

    Write-Host "Convert audit rule (.XML) to binary (.BIN)". -ForegroundColor Green
    ConvertFrom-CIPolicy $Audit_XML $Audit_BIN

    Write-Host "Copy the binary file (.BIN) to its Windows application location". -ForegroundColor Green
    Copy-Item -Path $Audit_BIN -Destination $DestinationBinary

    Write-Host "Update current WDAC policy. -ForegroundColor Green"
    Invoke-CimMethod -Namespace root/Microsoft/Windows/CI -ClassName PS_UpdateAndCompareCIPolicy -MethodName Update -Arguments @{FilePath = $DestinationBinary}
	
    End_Process
}

function End_Process {
    $End = Message_Box -Title "End of process" -Message "You need to restart the computer. Would you like to do it now ?" -Button "OkCancel" -Icon "IconAvertissement"

    switch ($End) {

        "OK" {
            Stop-Logs 
            Restart-Computer
        } 

        "Cancel" {
            Stop-Logs 
        } 
    }
}

function Connection-Is-Working {

    Return (Test-Path $Remote_Location_WDAC)
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

function Main { 

    # Vérification de la connexion au serveur distant contenant les profiles.
    If (-Not (Connection-Is-Working)) {
    
        Message_Box -Title "Error - Network" -Message "The path containing the profiles is unreachable." -Button "OK" -Icon "IconErreur"
   	Exit 
    }    

    Else {

        Start-Logs
	Start-Transcript -Path $Log_Path -NoClobber
	$StopWatch = New-Object System.Diagnostics.Stopwatch
	$StopWatch.Start()
	Write-Output "Start script - version $($ScriptVersion)"

        GUI
    }
}

Main

#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed
$StopWatch.Stop()
Write-Output "Finished script - $($MyInvocation.MyCommand.Name)"
Stop-Transcript


