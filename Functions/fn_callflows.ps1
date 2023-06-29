Function OutputMenu {
    [CmdletBinding()]Param ([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$MenuOptions)
    $menu = @()
    foreach ($menuOption in ($menuOptions)) {
        if ($menuOption.Action -eq "Announcement") {
            if ($menuOption.Prompt.ActiveType -eq "TextToSpeech") { $target = ("TextToSpeech: " + $menuOption.Prompt.TextToSpeechPrompt) }
            elseif ($menuOption.Prompt.ActiveType -eq "AudioFile") { $target = ("AudioFile: " + $menuOption.Prompt.AudioFilePrompt) }
        }
        elseif ($menuOption.Action -eq "DisconnectCall") { $target = "Disconnect" }
        elseif ($menuOption.Action -eq "TransferCallToOperator") { $target = $operator }
        elseif ($menuOption.Action -eq "TransferCallToTarget") {
            # 
            # The New-CsAutoAttendantCallableEntity cmdlet lets you create a callable entity for use with call transfers from the Auto Attendant service.
            # Callable entities can be created using either Object ID or TEL URIs and can refer to any of the following entities:
            # 
            # User
            # ApplicationEndpoint
            # ExternalPstn
            # SharedVoicemail
            # 
            if ($menuOption.CallTarget.Type -eq "User") { $target = ("User: " + (Get-CsOnlineUser -Identity $menuOption.CallTarget.Id).UserPrincipalName) }
            elseif ($menuOption.CallTarget.Type -eq "ApplicationEndpoint") {
                $appInstance = (Get-CsOnlineApplicationInstance -Identity $menuOption.CallTarget.Id)
                if ($raApplicationIds[$appInstance.ApplicationId]) {
                    $raAssociation = Get-CsOnlineApplicationInstanceAssociation -Identity $appInstance.ObjectId
                    $hashMatch = $acdHash[$raAssociation.ConfigurationId]
                    if ($raAssociation.ConfigurationType -eq "CallQueue") { $target = ("CallQueue: " + $hashMatch.Name) }
                    else { $target = ("AutoAttendant: " + $hashMatch.Name) }
                }
                else { $target = ("ResourceAccount: " + (Get-CsOnlineApplicationInstance -Identity $menuOption.CallTarget.Id).UserPrincipalName) } 
            }
            elseif ($menuOption.CallTarget.Type -eq "ExternalPstn") { $target = ("ExternalPSTN: " + $menuOption.CallTarget.Id) }
            elseif ($menuOption.CallTarget.Type -eq "SharedVoicemail") { $target = ("Voicemail: " + (Find-CsGroup -SearchQuery $menuOption.CallTarget.Id).DisplayName) }
        }
        $menu += [PSCustomObject]@{
            DtmfResponse = $menuOption.DtmfResponse
            Action       = $menuOption.Action
            Target       = $target
        }
    }
    $menu
}

Function OutputGreetings {
    [CmdletBinding()]Param ([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$Menu)
    $greetings = New-Object -TypeName "System.Collections.ArrayList"
    $Menu.Greetings | foreach {
    if ($_.ActiveType -eq "TextToSpeech") { $greeting = ("TextToSpeech: " + $_.TextToSpeechPrompt) }
        elseif ($_ -eq "AudioFile") { $greeting = ("AudioFile: " + $_.AudioFilePrompt) }
        $item = [PSCustomObject]@{Type='Greeting';Greeting=$greeting}
        [void]$greetings.Add($item)
    }
    $Menu.Menu.Prompts | foreach {
        if ($_.ActiveType -eq "TextToSpeech") { $prompt = ("TextToSpeech: " + $_.TextToSpeechPrompt) }
        elseif ($_ -eq "AudioFile") { $prompt = ("AudioFile: " + $_.AudioFilePrompt) }
        $item = [PSCustomObject]@{Type='Menu Prompt';Greeting=$prompt}
        [void]$greetings.Add($item)
    }
    $greetings
}
