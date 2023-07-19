Function Invoke-AADAuthWebBrowser {
    [CmdletBinding()]Param([Parameter(Mandatory=$true)][String]$Url)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Web
    $Form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
    $WebBrowser = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($Url) }
    $DocComp  = {
        $Global:uri = $WebBrowser.Url.AbsoluteUri
        if ($Global:uri -match "error=[^&]*|code=[^&]*") {$Form.Close() }
    }
    $DocNav = {
        if($WebBrowser.DocumentText -match "SAMLResponse")
        {
            $Script:SAMLToken = (([xml]$WebBrowser.DocumentText).GetElementsByTagName("input") | Where-Object name -eq SAMLResponse).value
            $Form.Close()
        }
    }
    $WebBrowser.ScriptErrorsSuppressed = $true
    $WebBrowser.Add_DocumentCompleted($DocComp)
    $WebBrowser.Add_Navigated($DocNav)
    $Form.AutoScaleMode = 'Dpi'
    $Form.text = "Azure AD Authentication"
    $Form.ShowIcon = $False
    $Form.AutoSizeMode = 'GrowAndShrink'
    $Form.StartPosition = 'CenterScreen'
    $Form.Controls.Add($WebBrowser)
    $Form.Add_Shown({$Form.Activate()})
    [Void]$Form.ShowDialog()
    $QueryOutput = [System.Web.HttpUtility]::ParseQueryString($WebBrowser.Url.Query)
    $Output = @{}
    foreach($Key in $QueryOutput.Keys){
        $Output["$Key"] = $QueryOutput[$Key]
    }
    Return $Output
}

Function Get-AADAuthToken {
    [CmdletBinding()][OutputType([string])]Param (
        [Parameter(Mandatory=$true)][ValidateScript({try{ [System.Guid]::Parse($_) | Out-Null;$true } catch { $false }})][string]$TenantId,
        [Parameter(Mandatory=$true)][ValidateScript({try{ [System.Guid]::Parse($_) | Out-Null;$true } catch { $false }})][string]$ClientId,
        [Parameter(Mandatory=$true)][string[]]$Scopes,
        [Parameter(Mandatory=$false)][string]$Username
    )
    # Get authorization
    # $uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize"
    $body = @{
        client_id     = $ClientId
        response_type = "code"
        response_mode = "query"
        redirect_uri  = "https://login.microsoftonline.com/common/oauth2/nativeclient"
        state         = "1234"
        scope         = $Scopes
        prompt        = "select_account"
        login_hint    = $Username
    }
    $fullUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?client_id=$($body.client_id)&response_type=$($body.response_type)&redirect_uri=$($body.redirect_uri)&response_mode=$($body.response_mode)&scope=$($body.scope)&state=$($body.state)&prompt=$($body.prompt)&login_hint=$($body.login_hint)"
    $authResp = Invoke-AADAuthWebBrowser -Url $fullUri
    # Get token
    # Construct URI and body needed for authentication
    $uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        grant_type    = "authorization_code"
        scope         = ($Scopes -join " ")
        code          = $authResp.code
        redirect_uri  = "https://login.microsoftonline.com/common/oauth2/nativeclient"
    }
    $tokenRequest = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
    $tokenRequest
}
