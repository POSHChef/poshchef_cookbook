function Report-Handler {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [hashtable]
        # Hash table containing the the status of the last run
        $status,

        [hashtable]
        # Attributes that have been resolved for this node
        $attributes
    )

    # Write out the name of the Handler
    Write-Log -EventId PC_MISC_0001 -Extra "Logstash Handler"

    # Set the values required in order to connect to redis
    $redis = @{
        server = $attributes.POSHChef.handlers.settings.redis.server
        queue = $attributes.POSHChef.handlers.settings.redis.queue
    }

    # Create array of Data that will be send to the Redis Server
    $data = @()

    # Import the module to work with Redis
    Import-Module PowerRedis

    $ip_properties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    $fqdn = "{0}.{1}" -f $ip_properties.hostname, $ip_properties.domainname

    # create the timestamp so that all events have the same one
    $timestamp = (Get-Date -Date ([DateTime]::UTCNow) -uformat "+%Y-%m-%dT%H:%M:%SZ")

    # Build up the payload of json to send to Redis
    # This item holds the elapsed time for the chef-run and will be passed onto graphite
    $data += @{
        "@timestamp" = $timestamp
        host = $env:COMPUTERNAME
        plugin = "chef.elapsed"
        value = $status.elapsed
    } | ConvertTo-Json

    # Add the status of the run to the data
    $data += @{
        "@timestamp" = $timestamp
        host = $env:COMPUTERNAME
        plugin = "chef.failed"
        value = !$status.success
    } | ConvertTo-Json

    # Now add an item for the entire run status, this will be more useful for debugging
    # but the previous items assist with graphing
    $item = @{
        "@timestamp" = $timestamp
        "@source_host" = $fqdn
        "@fields" = @{
            elapsed_time = $status.elapsed
            success = $flag
            start_time = (Get-Date -Date ([datetime] $status.start) -format s)
            end_time = (Get-Date -Date ([datetime] $status.end) -format s)
            exception = ""
        }
        type = "poshchef-handler"
    }

    # add in extra information based on whther there was an exception or not
    if ($status.containskey("exception")) {
        $item."@fields".exception = $status.exception
        $item."@message" = $status.exception.ToString() | Select -First 1
    } else {
        $item."@message" = ("POSHChef client run completed in {0:F2} seconds" -f $status.elapsed)
    }

    # Add the item to the data array
    $data += $item | ConvertTo-Json

    # Connect to the redis server
    Connect-RedisServer -RedisServer $redis.server | Out-Null

    # iterate around the data items and send each one to redis
    foreach ($item in $data) {
        # Send the data to the list
        Add-RedisListItem -Name $redis.queue -ListItem $item
    }

    Disconnect-RedisServer | Out-Null

}
