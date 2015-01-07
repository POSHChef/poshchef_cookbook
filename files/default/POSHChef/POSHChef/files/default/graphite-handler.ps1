
function Report-Handler {

    <#

    .SYNPOSIS
        Graphite Handler

    .DESCRIPTION
        Sends run time information about the previous Chef run to the configured Graphite server

    #>

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
    Write-Log -EventId PC_MISC_0001 -Extra "Graphite Handler"

    # Define the graphite server and port
    $graphite = @{
        server = $attributes.POSHChef.handlers.settings.graphite.server
        port = $attributes.POSHChef.handlers.settings.graphite.port
    }

    # Create a metrics array which will hold all the different metrics that should be
    # passed to graphite
    $metrics = @()

    # Determine the epoch time.  That is the number of seconds since 01/01/1970 00:00:00
    # This should be set to UTC or the timezone of the graphite server
    $epoch = [int](Get-Date ([DateTime]::UTCNow) -uformat %s)

    # Add a metric for the length of time the run took
    $metrics += "{0}.chef.elapsed {1} {2}" -f $env.COMPUTERNAME, $status.elapsed, $epoch

    # Add one to state if the run was successful or not
    # As the idea is to be able to draw an infinite line on the chart for a failure the success has to
    # be inversed to get the failed value
    $metrics += "{0}.chef.failed {1} {2}" -f $env.COMPUTERNAME, !$status.success, $epoch

    # Open up a socket which will be used to send the data
    $socket = New-Object Net.Sockets.Tcp.Client
    $socket.Connect($graphite.server, $graphite.port)

    # craete a stream from the socket
    $stream = $socket.GetStream()

    # craete a writer from the stream
    $writer = New-Object System.IO.StreamWriter($stream)

    # iterate around each metric and send them to the server
    foreach ($metric in $metrics) {

        # Write the metric to the stream and then flush it
        $writer.WriteLine($metric)
        $writer.Flush()
    }

    # Close the riter and stream
    $writer.Close()
    $stream.Close()

    # Close the socket
    $socket.Close()

}
