Function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory)]
        [string]$QueueName,

        [Parameter(Mandatory,HelpMessage="Group or Account name, including domain name")]
        [String]$AccountName,

        [Parameter(Mandatory)]
        [ValidateSet("DeleteMessage","PeekMessage","ReceiveMessage","WriteMessage","DeleteJournalMessage","ReceiveJournalMessage","SetQueueProperties","GetQueueProperties","DeleteQueue","GetQueuePermissions","GenericWrite","GenericRead","ChangeQueuePermissions","TakeQueueOwnership","FullControl")]
        [String]$Right,

        [Parameter(Mandatory)]
        [ValidateSet("Allow","Deny")]
        [String]$Access,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure = "Present"
    )

    $queue = Get-MsmqQueue -Name $QueueName
    $ACLs = Get-MsmqQueueACL -InputObject $queue
    $thisACL = $ACLs | Where-Object {($_.AccountName -eq $AccountName) -and ($_.Right -eq $right)}

    @{
        QueueName = $queue.QueueName
        AccountName = $thisACL.AccountName
        Right = $thisACL.Right
        Access = $thisACL.Access
        Ensure = $Ensure
    }
}

Function Set-TargetResource {
    [Cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]$QueueName,

        [Parameter(Mandatory,HelpMessage="Group or Account name, including domain name")]
        [String]$AccountName,

        [Parameter(Mandatory)]
        [ValidateSet("DeleteMessage","PeekMessage","ReceiveMessage","WriteMessage","DeleteJournalMessage","ReceiveJournalMessage","SetQueueProperties","GetQueueProperties","DeleteQueue","GetQueuePermissions","GenericWrite","GenericRead","ChangeQueuePermissions","TakeQueueOwnership","FullControl")]
        [String]$Right,

        [Parameter(Mandatory)]
        [ValidateSet("Allow","Deny")]
        [String]$Access,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure = "Present"
    )
    

    $queue = Get-MsmqQueue -Name $QueueName
    Switch ($Ensure) { 
        "Present" { 
            $MSMQQueueACLSplat = @{
                UserName = $AccountName
                $Access = $Right
            }
        }
        "Absent" { 
             $MSMQQueueACLSplat = @{
                    UserName = $AccountName
                    $Access = $Right
                    Remove = $true
             }
        }
    }

    Set-MsmqQueueACL -InputObject $queue @MSMQQueueACLSplat

}

Function Test-TargetResource {
    [Cmdletbinding()]
    param (
        [parameter(Mandatory)]
        [string]$QueueName,

        [Parameter(Mandatory,HelpMessage="Group or Account name, including domain name")]
        [String]$AccountName,

        [Parameter(Mandatory)]
        [ValidateSet("DeleteMessage","PeekMessage","ReceiveMessage","WriteMessage","DeleteJournalMessage","ReceiveJournalMessage","SetQueueProperties","GetQueueProperties","DeleteQueue","GetQueuePermissions","GenericWrite","GenericRead","ChangeQueuePermissions","TakeQueueOwnership","FullControl")]
        [String]$Right,

        [Parameter(Mandatory)]
        [ValidateSet("Allow","Deny")]
        [String]$Access,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Present","Absent")]
        [String]$Ensure = "Present"
    )

    if (CheckQueueExists -queuename $QueueName) {
        $queue = Get-MsmqQueue -Name $QueueName
        $ACLs = Get-MsmqQueueACL -InputObject $queue
        $thisACL = $ACLs | Where-Object {($_.AccountName -eq $AccountName) -and ($_.Right -eq $Right)}
    } else {
        Write-Verbose "$QueueName not found"
        throw "$QueueName not found - exiting"
    }

    Switch ($Ensure) { 
        "Present" {
            if ($thisACL) {
                return $true
            } else {
                return $false
            }              
        }
        "Absent" {
            if ($thisACL) {
                return $false
            } else {
                return $true
            }         
        }
    }
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
