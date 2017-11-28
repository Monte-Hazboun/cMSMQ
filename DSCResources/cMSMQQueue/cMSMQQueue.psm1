Function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory)]
        [string] $QueueName,

        [parameter(Mandatory)]
        [ValidateSet("Public","Private")]
		[string] $QueueType
    )

    if (CheckQueueExists -queuename $QueueName) {
        $Queue = Get-MsmqQueue -Name $QueueName 
    } else { 
        Write-Verbose "$QueueName not found"
    }

	$returnValue = @{
        QueueName = $Queue.QueueName
		QueueType = CheckQueueType -queue $Queue
        Label = ($Queue.Label -split "\\")[-1]
        Authenticate = $Queue.Authenticate
        Journaling = $Queue.UseJournalQueue
        Transactional = $Queue.Transactional
        JournalQuota = $Queue.MaximumJournalSize
        MulticastAddress = $Queue.MulticastAddress
        PrivacyLevel = $Queue.EncryptionRequired
    }
    $returnValue
}

Function Set-TargetResource {
    [Cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]$QueueName,

        [parameter(Mandatory)]
        [ValidateSet("Public","Private")]
		[string]$QueueType,

        [Parameter(Mandatory=$false)]
        [String]$Label,

        [Parameter(Mandatory=$false)]
        [Switch]$Authenticate,

        [Parameter(Mandatory=$false)]
        [Switch]$Journaling,

        [Parameter(Mandatory=$false)]
        [Switch]$Transactional,

        [Parameter(Mandatory=$false)]
        [int64]$JournalQuota,

        [Parameter(Mandatory=$false)]
        [String]$MulticastAddress,

        [Parameter(Mandatory=$false)]
        [ValidateSet("None","Optional","Body")]
        [string]$PrivacyLevel
    )
    
    if (CheckQueueExists -queuename $QueueName) {                           #check to see if the queue exists, if it doesn't create it
        $Queue = Get-MsmqQueue -QueueName $QueueName 
        If ((CheckQueueType -queue $Queue) -eq $QueueType) {                #check to see if the queue type matches, if it does we can alter the existing queue. 
            $PSBoundParameters.Remove("QueueType")
            Set-MsmqQueue -InputObject $Queue @PSBoundParameters
        } else {                                                            #If the queue type doesn't match, we need to remove the existing queue and recreate it. 
            Remove-MsmqQueue -InputObject $Queue
            $PSBoundParameters.Add("Name",$PSBoundParameters["QueueName"])
            $PSBoundParameters.Remove("QueueName")
            New-MsmqQueue @PSBoundParameters
        }
    } else {
        $PSBoundParameters.Add("Name",$PSBoundParameters["QueueName"])
        $PSBoundParameters.Remove("QueueName")
        New-MsmqQueue @PSBoundParameters
    }
}

Function Test-TargetResource {
    [Cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]$QueueName,

        [parameter(Mandatory)]
        [ValidateSet("Public","Private")]
		[string]$QueueType,

        [Parameter(Mandatory=$false)]
        [String]$Label,

        [Parameter(Mandatory=$false)]
        [Switch]$Authenticate,

        [Parameter(Mandatory=$false)]
        [Switch]$Journaling,

        [Parameter(Mandatory=$false)]
        [Switch]$Transactional,

        [Parameter(Mandatory=$false)]
        [int64]$JournalQuota,

        [Parameter(Mandatory=$false)]
        [String]$MulticastAddress,

        [Parameter(Mandatory=$false)]
        [ValidateSet("None","Optional","Body")]
        [string]$PrivacyLevel
    )

    $IndesiredState = $true
    if (CheckQueueExists -queuename $QueueName) {
        $Queue = Get-TargetResource -QueueName $QueueName -QueueType $QueueType
    } else {
        Write-Verbose "$QueueName not found"
        return $false
    }

    Foreach ($key in $PSBoundParameters.keys) { 
        if ($Queue.$key -ne $PSBoundParameters[$key]) { 
            Write-Verbose "wrong setting for $key"
            $IndesiredState = $false
        }
    }
    return $IndesiredState
}


Function CheckQueueExists {
    param (
        [string]$queuename
    )    

    if (Get-MsmqQueue -Name $queuename) {
        return $true
    } else {
        return $false
    }
}

Function CheckQueueType {
    param (
        [Microsoft.Msmq.PowerShell.Commands.MessageQueue]
        $queue
    )
        Switch (($queue.FormatName -split "=")[0]) {
            "PUBLIC" {$type = "Public"}
            "DIRECT" {$type = "Private"}
        }
    return $type
}


Export-ModuleMember -Function *-TargetResource
