function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name
	)

	@{
		Name = $name
	}

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$returnValue = @{
		Name = [System.String]
		Description = [System.String]
		Folder = [System.String]
		Triggers = [System.String]
		Credential = [System.Management.Automation.PSCredential]
		RunElevated = [System.Boolean]
		Command = [System.String]
		ScriptBlock = [System.Boolean]
		Ensure = [System.String]
	}

	$returnValue
	#>
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String]
		$Description,

		[System.String]
		$Folder,

		[System.String]
		$Triggers,

		[System.Management.Automation.PSCredential]
		$Credential,

		[System.Boolean]
		$RunElevated,

		[System.String]
		$Command,

		[System.Boolean]
		$ScriptBlock,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	# The task does not exist so it needs to be created
	Write-Verbose ("Creating task '{0}' in folder '{1}'" -f $name, $folder)

	# perform the most appropriate action based on the Ensure
	switch ($Ensure) {
		"Present" {

			# Call the Add-Task function to create this task
			# Create an argument hash to pass to the function
			$splat = @{
				name = $name
				description = $description
				triggers = $triggers | ConvertFrom-JsonToHashtable
				credential = $credential
				runelevated = $runelevated
				command = $command
				scriptblock = $scriptblock
				folder = $folder
			}
			Add-Task @splat

		}

		"Absent" {

		}
	}
	


}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String]
		$Description,

		[System.String]
		$Folder,

		[System.String]
		$Triggers,

		[System.Management.Automation.PSCredential]
		$Credential,

		[System.Boolean]
		$RunElevated,

		[System.String]
		$Command,

		[System.Boolean]
		$ScriptBlock,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	# Set the test variable to return
	$test = $true

	# Determine if the task exists
	$exists = Find-Task -name $name -folder $folder

	# Set the value of the test based on what was retruned by the FindTask
	# a null value denotes that the task cannot be found
	if ([String]::IsNullOrEmpty($exists)) {
		$test = $false
	} else {
		Write-Verbose ("Task '{0}' already exists" -f $name)
	}

	# Invert the test if the Ensure is absent
	if ($Ensure -eq "Absent") {
		$test = !$test
	}

	# return the value of the test
	$test
}

function Get-TasksService {

    <#
    
    .SYNOPSIS
        Returns an object on the local machine to the Schedule.Service
    
    #>

    $service = New-Object -ComObject Schedule.Service
    $service.connect("localhost")
    
    # return the service to the calling function
    $service
}

function Find-Task {

    <#
    
    .SYNOPSIS
        Attempts to find the named task in the service
    
    #>
    
    param (
        [Parameter(Mandatory=$true)]
        [string]
        # name of the task to find
        $name,
        
        [string]
        # The folder to look in for the tasks
        $foldername = "\"
    )

    # ensure that the folder starts with a \
    if (!$foldername.startswith("\")) {
        $foldername = "\{0}" -f $foldername
    }

    # Get a reference to the folder to work with
    # But the folder may not exist to trap this and return if does not 
    try {
    	$folder = (Get-TasksService).GetFolder($foldername)
    } catch {
    	Write-Verbose ("Folder '{0}' does not exist" -f $foldername)
    	return [String]::Empty
    }
    
    # return a list of the tasks
    $tasks = $folder.GetTasks(0)
    
    # Attempt to find the named task in the list
    $tasks | Where-Object { $_.name -eq $name }
}

function Add-Task {

    <#
    
    .SYNOPSIS
        Adds a task to the Windows Task Scheduler
    
    #>
    
    param (
    
        [Parameter(Mandatory=$true)]
        [string]
        # Name of the task to create
        $name,
        
        [string]
        # Description for the task that is being added
        $description,
    
        [array]
        # Array of hashtables containing the triggers to be applied to this task
        $triggers,
    
        # Credential under which the job should run
        $credential,
    
        [switch]
        # Whether or not the script should run with elevated permissions
        $runelevated,
    
        [string]
        # Path to the script to run
        $command,
        
        [switch]
        # Switch to denote if the command is a script block or a path to a script to be run
        $scriptblock,
        
        [string]
        # List of arguments that need to be passed to the script
        $arguments = [String]::Empty,
    
        [string]
        # Folder where the task should be created
        $foldername = "\"
    )
    
    # Define the trigger constants
    $trigger_types = @{
        once = 1
        boot = 8
    }
    
    # Get a reference to the service
    $service = Get-TasksService
    
    # ensure that the folder starts with a \
    if (!$foldername.startswith("\")) {
        $foldername = "\{0}" -f $foldername
    }
    
    # Get the folder that has been specified
    # If it cannot be found, create it
    try {
        $folder = $service.GetFolder($foldername)
    } catch {
    	Write-Verbose ("Creating new folder '{0}'" -f $foldername)
        $toplevel = $service.GetFolder("\")
        $folder = $toplevel.CreateFolder($foldername)
    }
    
    # create a new task object
    $task = $service.NewTask(0)
    
    # Set the registration information
    $registration = $task.RegistrationInfo
    $registration.Description = $description
    $registration.Author = $credential.username
    
    # Define the settings for the task
    $settings = $task.settings
    $settings.StartWhenAvailable = $true
    
    # Configure the trigger for the task
    $task_triggers = $task.Triggers
    
    # iterate around the triggers that have been passed to the function
    foreach ($trigger in $triggers) {
    
        # Create a new taskTrigger to work with
        $task_trigger = $task_triggers.Create($trigger_types.$($trigger.type))
        
        # switch on the trigger type to specify the correct parameters
        switch ($trigger.type) {
            "once" {
                
                foreach ($time in @("minutes", "hours")) {
                    if ([String]::IsNullOrEmpty($trigger.$time)) {
                        $trigger.$time = 0
                    }
                }
            
                # Set te start time of the task which is 1 minute from Now
                $TaskStartTime = [datetime]::Now.AddMinutes($trigger.minutes) 
                $task_trigger.StartBoundary = $TaskStartTime.ToString("yyyy-MM-dd'T'HH:mm:ss")

                $repetition = New-TimeSpan -Hours $trigger.hours -Minutes $trigger.minutes
                $task_trigger.Repetition.Interval = "PT{0}H{1}M" -f $repetition.Hours, $repetition.Minutes

                Write-Verbose ("Adding 'once' trigger with repetition interval: {0}" -f $task_trigger.repetition.interval)

            }
            
            "boot" {
                
                # if there is a delay object in the configuration set it
                if ($trigger.containskey("delay")) {
                
                    foreach ($time in @("minutes", "hours")) {
                        if ([String]::IsNullOrEmpty($trigger.delay.$time)) {
                            $trigger.delay.$time = 0
                        }
                    }
                
                    $delay = New-TimeSpan -Hours $trigger.delay.hours -Minutes $trigger.delay.minutes
                    $task_trigger.delay = "PT{0}H{1}M" -f $delay.Hours, $delay.Minutes
                }

              	Write-Verbose ("Adding 'boot' trigger")
            }
        }
    }
    
    # Configure the principal
    # This is required if the task is to run with the highest privileges
    if ($runelevated) {
        $principal = $task.Principal
        $principal.RunLevel = 1
    }
    
    # Create the action for this task
    $action = $task.Actions.Create(0)
    $action.path = "C:\windows\system32\windowspowershell\v1.0\powershell.exe"
    
    # Determine if the scriptblock has been set, if so set the arguments accordingly
    if ($scriptblock) {
        $args = '-Command " & {{{0}}}"' -f ([ScriptBlock]::Create($command))
    } else {
        $args = $command
    }
    $action.arguments = $args
    
    # Finally register the task in the folder that has been specified
    $folder.RegisterTaskDefinition($name, $task, 6, $credential.username, (ConvertFrom-SecureToPlain $credential.password), 1) | Out-Null
}

function ConvertFrom-SecureToPlain {
    
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)
    
    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    
    # Get the plain text version of the password
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    
    # Return the plain text password
    $PlainTextPassword
    
}


function ConvertFrom-JsonToHashtable {

	<#

	.SYNOPSIS
		Helper function to take a JSON string and turn it into a hashtable

	.DESCRIPTION
		The built in ConvertFrom-Json file produces as PSCustomObject that has case-insensitive keys.  This means that
		if the JSON string has different keys but of the same name, e.g. 'size' and 'Size' the comversion will fail.

		Additionally to turn a PSCustomObject into a hashtable requires another function to perform the operation.
		This function does all the work in step using the JavaScriptSerializer .NET class

	#>

	[CmdletBinding()]
	param(

		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
		[AllowNull()]
		[string]
		$InputObject
	)
	
	# Perform a test to determine if the inputobject is null, if it is then return an empty hash table
	if ([String]::IsNullOrEmpty($InputObject)) {

		$dict = @{}

	} else {

		# load the required dll
		[void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
		$deserializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
		$dict = $deserializer.DeserializeObject($InputObject)

	}
	
	return $dict
}


Export-ModuleMember -Function *-TargetResource

