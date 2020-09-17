using namespace system;
using namespace system.net;
using namespace system.net.http;
using namespace microsoft.powershell.commands;

. $PSScriptRoot\Exception.ps1

Function GetSession {
    <#
    .synopsis
    Create a web session with the atom server
    .parameter AtomUrl
    URL to AtoM web application
    #>
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]
        $AtomUrl
    )
    $Response = $NULL
    $OldPreference = $ProgressPreference
    Try {
        $ProgressPreference = 'SilentlyContinue'
        $Response = Invoke-WebRequest -Uri $AtomUrl -Body $LoginData -Method POST -SessionVariable 'NewSession'
        ThrowIfUnsuccessful -Response $Response -RequestUri $AtomUrl
    }
    Catch [Exception] {
        If ($Response) {
            ThrowIfUnsuccessful -RequestUri $AtomUrl -Response $Response
        }
        ElseIf ($_.Exception.Response) {
            ThrowIfUnsuccessful -RequestUri $AtomUrl -Response $_.Exception.Response
        }
        Else {
            ThrowIfUnsuccessful -RequestUri $AtomUrl -ErrorMessage $_.Exception.Message
        }
    }
    Finally {
        $ProgressPreference = $OldPreference
    }
    Return $NewSession
}

Function LoginToF5LoadBalancer {
    <#
    .synopsis
    Get an authenticated web session with an F5 load balancer
    .description
    This function should be used when one must first log in to an F5 load balancer before being able
    to access the AtoM web application.
    .parameter AtomUrl
    URL to AtoM web application. The url plus /my.policy is used to log in to the load balancer
    #>
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]
        $AtomUrl
    )
    $OldPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    $Session = GetSession -AtomUrl $AtomUrl
    $LoginUrl = $AtomUrl.TrimEnd('/') + '/my.policy'
    $CredentialsAccepted = $False
    $OperationCancelled = $False
    $ErrorMessage = ''

    While (-Not $CredentialsAccepted -And -Not $OperationCancelled) {
        If ($ErrorMessage) {
            $Prompt = "$($ErrorMessage.TrimEnd('.')). Try re-entering your F5 credentials"
        }
        Else {
            $Prompt = "Enter your F5 credentials for $LoginUrl"
        }

        If ($PSVersionTable.PSVersion.Major -ge 6) {
            $Credentials = Get-Credential -Title $Prompt
        }
        Else {
            $Credentials = Get-Credential -Message $Prompt
        }

        If (-Not $Credentials) {
            $OperationCancelled = $True
            Continue
        }

        $NetworkCredentials = $Credentials.GetNetworkCredential()
        $LoginData = @{
            username=$NetworkCredentials.UserName;
            password=$NetworkCredentials.Password;
            vhost='standard';
        }

        If (-Not $LoginData['password']) {
            $ErrorMessage = 'You must enter your password'
            Continue
        }

        Try {
            $Response = Invoke-WebRequest -Uri $LoginUrl -Body $LoginData -Method POST -WebSession $Session
            ThrowIfUnsuccessful -Response $Response -RequestUri $LoginUrl
        }
        Catch [Exception] {
            If ($Response) {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -Response $Response
            }
            ElseIf ($_.Exception.Response) {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -Response $_.Exception.Response
            }
            Else {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -ErrorMessage $_.Exception.Message
            }
        }

        $ResponseText = $Response.RawContent
        If ($ResponseText -Match 'too many users are logged in. Could not establish connection') {
            $Msg = 'Too many users are logged in to the server. Could not establish connection.'
            Throw [LoginException]::new($Msg)
        }
        ElseIf ($ResponseText -Match 'Access was denied by the access policy') {
            $Msg = "Access to the server was denied. Make sure you have access to $LoginUrl before trying again."
            Throw [LoginException]::new($Msg)
        }
        ElseIf ($ResponseText -Match 'password is not correct') {
            $ErrorMessage = 'The username or password was not correct'
            Continue
        }
        Else {
            $CredentialsAccepted = $True
        }
    }
    $ProgressPreference = $OldPreference

    If ($OperationCancelled) {
        Throw [LoginException]::new('Login cancelled.')
    }

    Return $Session
}

Function LoginToAtom {
    <#
    .synopsis
    Log in to an AtoM instance
    .description
    This function should be used when one does not need any other credentials than their AtoM
    credentials to access the AtoM web application (e.g., no load balancer exists).
    .parameter AtomUrl
    URL to AtoM web application
    .parameter WebSession
    An intialized web session
    #>
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]
        $AtomUrl,

        [Parameter(Mandatory=$True, Position=1)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    $OldPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    $AtomUrlTrimmed = $AtomUrl.TrimEnd('/')
    $LoginUrl = "$($AtomUrlTrimmed)/index.php/user/login"
    $CredentialsAccepted = $False
    $OperationCancelled = $False
    $ErrorMessage = ''

    While (-Not $CredentialsAccepted -And -Not $OperationCancelled) {
        If ($ErrorMessage) {
            $Prompt = "$($ErrorMessage.TrimEnd('.')). Try entering your AtoM credentials again"
        }
        Else {
            $Prompt = 'Enter your AtoM credentials. Your username is your email'
        }

        If ($PSVersionTable.PSVersion.Major -ge 6) {
            $Credentials = Get-Credential -Title $Prompt
        }
        Else {
            $Credentials = Get-Credential -Message $Prompt
        }

        If (-Not $Credentials) {
            $OperationCancelled = $True
            Continue
        }

        $NetworkCredentials = $Credentials.GetNetworkCredential()
        $LoginData = @{
            email=$NetworkCredentials.UserName;
            password=$NetworkCredentials.Password;
            next=$AtomUrl.TrimEnd('/');
        }

        If (-Not $LoginData['password']) {
            $ErrorMessage = 'You must enter your password'
            Continue
        }

        Try {
            $Response = Invoke-WebRequest -Uri $LoginUrl -Body $LoginData -Method POST -WebSession $WebSession
            ThrowIfUnsuccessful -Response $Response -RequestUri $LoginUrl
            $ResponseText = $Response.RawContent
            If ($ResponseText -Match 'unrecognized email or password') {
                $ErrorMessage = 'The email or password was not correct'
                Continue
            }
            ElseIf ($ResponseText -Match 'isn.t a valid email address') {
                $ErrorMessage = 'The email address was not valid'
                Continue
            }
            Else {
                $CredentialsAccepted = $True
            }
        }
        Catch [Exception] {
            If ($Response) {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -Response $Response
            }
            ElseIf ($_.Exception.Response) {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -Response $_.Exception.Response
            }
            Else {
                ThrowIfUnsuccessful -RequestUri $LoginUrl -ErrorMessage $_.Exception.Message
            }
        }
    }
    $ProgressPreference = $OldPreference

    If ($OperationCancelled) {
        Throw [LoginException]::new('Login cancelled.')
    }
}

Function ThrowIfUnsuccessful {
    <#
    .synopsis
    Throws a Net.Http.HttpRequestException for an HTTP request if the status is not 200, or if an
    error message is supplied
    .parameter RequestUri
    The URI used in the web request
    .parameter Response
    The response object retrieved from the web request
    .parameter ErrorMessage
    An error message to place in the exception. When this parameter is used, this function is
    guaranteed to throw an exception
    #>
    [CmdletBinding(DefaultParameterSetName='Response')]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName='Response')]
        [Parameter(Mandatory=$True, ParameterSetName='ErrorMessage')]
        [Parameter(Mandatory=$True)]
        [String]
        $RequestUri,

        [Parameter(Mandatory=$True, ParameterSetName='Response')]
        [Object]
        $Response,

        [Parameter(Mandatory=$True, ParameterSetName='ErrorMessage')]
        [String]
        $ErrorMessage
    )
    If ($PSCmdlet.ParameterSetName -eq 'ErrorMessage') {
        $Message = ("Could not connect to server at $($RequestUri):`n" +
                    "$ErrorMessage")
        Throw [HttpRequestException]::new($Message)
    }
    Else {
        $Result = ExtractStatusCodeAndDescription -Response $Response
        $Code = $Result.Code
        $Description = $Result.Description
        If ($Code -ne 200) {
            $Message = ("Could not connect to server at $($RequestUri):`n" +
                        "Server responded with: $Code $Description")
            Throw [HttpRequestException]::new($Message)
        }
    }
}

Function ExtractStatusCodeAndDescription {
    <#
    .synopsis
    Retrieves the status code and description from multiple different types of HTTP response objects
    .parameter Response
    Either a System.Net.HttpWebResponse, a Microsoft.PowerShell.Commands.HtmlWebResponseObject, or
    a System.Net.Http.HttpResponseMessage
    #>
    Param(
        [Parameter(Mandatory=$True)]
        [Object]
        $Response
    )
    If ($Response -is [WebResponseObject] -or $Response -is [HttpWebResponse]) {
        $Code = [Int] $Response.StatusCode
        $Description = [String] $Response.StatusDescription
    }
    ElseIf ($Response -is [HttpResponseMessage]) {
        $Code = [Int] $Response.StatusCode
        $Description = [String] $Response.ReasonPhrase
    }
    Else {
        $Type = $Response.GetType().FullName
        Throw "Unrecognized Response object found with type $Type"
    }
    Return [PSCustomObject] @{
        Code = $Code;
        Description = $Description;
    }
}
