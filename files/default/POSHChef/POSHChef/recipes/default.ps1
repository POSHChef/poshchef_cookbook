
# Recipes in POSHChef are built up using the new 'Configuration' keyword from DSC
# The follwing snippet shows how to build up the Default recipe

Configuration POSHChef_Default {

    <#

    .SYNOPSIS
        Recipe that will configure basic things that should exists on a machine

    .DESCRIPTION
        As scripts and things are dropped onto the filesystem for use in other applications
        directories etc need to be configured to handle these

        This recipe will setup the necessary paths

    #>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$true)]
        [hashtable]
        [ValidateScript({
            $_.contains("POSHChef") -and
            $_.POSHChef.contains("paths") -and
            $_.POSHChef.paths -is [hashtable]
        })]
        # Node attributes
        $node
    )

    # Configure any WSMAN settings
    # This will not be done within DSC as this is required by DSC
    # Iterate around each of the keys int he wsman object for POSHChef
    foreach ($item in $node.POSHChef.wsman.keys) {

        # set the path to contain the full WSMAN path
        $path = "WSMAN:\localhost\{0}" -f $item

        # attempt to get the value for this setting
        $value = (Get-Item $path).value

        # if the values are different then set them
        if ($value -ne $node.poshchef.wsman.$item) {
            Write-Log ("Setting WSMan '{0}' to '{1}', was '{2}'" -f $item, $node.poshchef.wsman.$item, $value)
            Set-Item $path -Value $node.poshchef.wsman.$item
        }

    }

    # Iterate around the paths and make sure that they all exist
    foreach ($pathname in $node.POSHChef.paths.keys) {
        $resource_name = "Directory_{0}" -f $pathname
        File $resource_name {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $node.POSHChef.paths.$pathname
        }
    }

    # Check the enabled handlers and ensure they are updated
    # Iterate around the enabled ones
    foreach ($handler in $node.poshchef.handlers.enabled) {

        # Use the template resource to write the file out
        CookbookFile ("Handler {0}" -f $handler) {
            Ensure = "Present"
            Source = $handler
            Destination = ("{0}\report\{1}" -f $node.POSHChef.handlers_path, $handler)
            Cookbook = "POSHChef"
        }
    }

}
