
function Report-Handler {

    <#

    .SYNOPSIS
        Handler to send the status of the run to Elasticsearch

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [hashtable]
        # Hash table containing the status of the run
        $status,

        [hashtable]
        # Attributes for this node
        $attributes
    )

    Write-Log -EventId PC_MISC_0001 -Extra "ElasticSearch Handler"

    # The following sets the Elastic Search server, port and index that should be used
    # to add the information
    $elasticsearch = @{
        server = $attributes.POSHChef.handlers.settings.elasticsearch.server
        port = $attributes.POSHChef.handlers.settings.elasticsearch.port
        index = "{0}-{1}" -f $attributes.POSHChef.handlers.settings.elasticsearch.index, (Get-Date -format yyyy.MM.dd)
        mapping = $attributes.POSHChef.handlers.settings.elasticsearch.mapping
        type = "poshchef"
    }

    # Determine the FQDN of the machine, this is so that the host entry in the
    # document is set correctly
    $ip_properties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    $fqdn = "{0}.{1}" -f $ip_properties.hostname, $ip_properties.domainname

    # set the succes flag based on the infromation in the status
    if ($status.status -eq "success") {
        $flag = $true
    } else {
        $flag = $false
    }

    # Build up the body of the request, that is what is to be sent to Elastic
    $body = @{
        "@timestamp" = (Get-Date -Date ([DateTime]::UTCNow) -uformat "+%Y-%m-%dT%H:%M:%SZ")
        "@source_host" = $fqdn
        "@fields" = @{
            elapsed_time = $status.elapsed
            success = $flag
            start_time = (Get-Date -Date ([datetime] $status.start) -format s)
            end_time = (Get-Date -Date ([datetime] $status.end) -format s)
            exception = ""
        }
        type = $elasticsearch.type
    }

    # if the status contains an excpetion then add it in as a backtrace
    if ($status.containskey("exception")) {
        $body."@fields".exception = $status.exception
        $body."@message" = $status.exception.ToString() | Select -First 1
    } else {
        $body."@message" = ("POSHChef client run completed in {0:F2} seconds" -f $status.elapsed)
    }

    # Build up the argument hashtable to be applied to the Invoke-RestMethod
    $splat = @{
        uri = "http://{0}:{1}/{2}/{3}" -f $elasticsearch.server, $elasticsearch.port, $elasticsearch.index, $elasticsearch.mapping
        method = "POST"
        body = ($body | ConvertTo-JSON -Depth 100)
    }


    # Send this inforamtion to the server
    $result = Invoke-RestMethod @splat

}
