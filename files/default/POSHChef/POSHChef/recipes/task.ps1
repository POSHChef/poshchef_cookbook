Configuration POSHChef_Task {

    <#

    .SYNOPSIS
    Configures POSHChef to run as a task on the target machine

    .DESCRIPTION
    This recipe configures two tasks on the server.

        1.  Task to run every x minutes
        2.  Task to run at startup

    #>

    [CmdletBinding()]
    param (

        [hashtable] 
        [Parameter(Mandatory=$true)]
        [validateScript({
            $_.contains("POSHChef") -and
            $_.POSHChef.contains("interval") -and
            $_.POSHChef.interval -is [Int] -and
            $_.POSHChef.contains("task") -and
            $_.POSHChef.task.contains("name") -and
            $_.POSHChef.task.name -is [String] -and
            $_.POSHChef.task.contains("folder") -and
            $_.POSHChef.task.folder -is [String] -and
            $_.POSHChef.task.contains("triggers") -and
            $_.POSHChef.task.triggers -is [Array]
        })]
        $node
    )

    # Set local variables
    $POSHChef = $node.POSHChef

    # If credentials have been specified for the task then ensure they are truned into a PSCredential object
    # to be used by the Scheduling resource
    if (![String]::IsNullOrEmpty($node.POSHChef.task.credentials.username) -and 
        ![String]::IsNullOrEmpty($node.POSHChef.task.credentials.password)) {

        # Create the credentials to be used to run the job
        $secpasswd = ConvertTo-SecureString $node.POSHChef.task.credentials.password -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ($node.POSHChef.task.credentials.username, $secpasswd)

    }

    Turtlesystems_AddTask $node.poshchef.task.name {
        Ensure = "Present"
        Name = $node.poshchef.task.name
        Description = $node.poshchef.task.description
        Folder = $node.poshchef.task.folder
        Triggers = ($node.poshchef.task.triggers | ConvertTo-Json -Depth 100)
        Credential = $mycreds
        RunElevated = $true
        Command = "Import-Module POSHChef; Invoke-POSHChef"
        ScriptBlock = $true
    }
}