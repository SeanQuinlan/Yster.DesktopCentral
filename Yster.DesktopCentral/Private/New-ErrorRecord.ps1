function New-ErrorRecord {
    <#
    .SYNOPSIS
        Create an ErrorRecord object that can be used to output a custom error message.
    .DESCRIPTION
        Create a custom ErrorRecord object using a number of input parameters, in order to pass a better error message up the stack.
    .EXAMPLE
        $Terminating_ErrorRecord_Parameters = @{
            'Exception'    = 'Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException'
            'ID'           = 'ADObjectNotFound'
            'Category'     = 'ObjectNotFound'
            'TargetObject' = $DN_Search_Return
            'Message'      = ('Cannot find group with identity: {0}' -f $DN_Search_Object)
        }
        $Terminating_ErrorRecord = New-ErrorRecord @Terminating_ErrorRecord_Parameters
    #>

    [CmdletBinding()]
    param(
        # The category of the exception.
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            # From: https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.errorcategory?view=powershellsdk-1.1.0
            'AuthenticationError',
            'CloseError',
            'ConnectionError',
            'DeadlockDetected',
            'DeviceError',
            'FromStdErr',
            'InvalidArgument',
            'InvalidData',
            'InvalidOperation',
            'InvalidResult',
            'InvalidType',
            'LimitsExceeded',
            'MetadataError',
            'NotEnabled',
            'NotImplemented',
            'NotInstalled',
            'ObjectNotFound',
            'OpenError',
            'OperationStopped',
            'OperationTimeout',
            'ParserError',
            'PermissionDenied',
            'ProtocolError',
            'QuotaExceeded',
            'ReadError',
            'ResourceBusy',
            'ResourceExists',
            'ResourceUnavailable',
            'SecurityError',
            'SyntaxError',
            'WriteError'
        )]
        [System.Management.Automation.ErrorCategory]
        $Category,

        # The exception used to describe the error.
        [Parameter(Mandatory = $true)]
        [String]
        $Exception,

        # The ID of the exception.
        [Parameter(Mandatory = $true)]
        [String]
        $ID,
        # The inner exception that is the cause of this exception.
        [Parameter(Mandatory = $false)]
        [Object]
        $InnerException,

        # A custom error message to display with the error.
        [Parameter(Mandatory = $false)]
        [String]
        $Message,

        # The object against which the cmdlet was operating when the error occurred.
        [Parameter(Mandatory = $false)]
        [Object]
        $TargetObject = $null
    )

    $Function_Name = (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('{0}|Arguments: {1} - {2}' -f $Function_Name, $_.Key, ($_.Value -join ' ')) }

    if ($PSBoundParameters.ContainsKey('Message') -and $PSBoundParameters.ContainsKey('InnerException')) {
        $Exception_Arguments = $Message, $InnerException
    } elseif ($PSBoundParameters.ContainsKey('Message')) {
        $Exception_Arguments = $Message
    }
    $ErrorException = New-Object -TypeName $Exception -ArgumentList $Exception_Arguments
    $ErrorRecord_Arguments = @($ErrorException, $ID, $Category, $TargetObject)

    # Return the ErrorRecord object
    New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList $ErrorRecord_Arguments
}
