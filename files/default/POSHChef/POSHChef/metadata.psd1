# PowerShell version of the metadata.rb file
# When a cookbook is uploaded this file will be used to generated the metadata.rb file
# that is required by Chef and the native client

@{

    # Name of the cookbook
    name = "POSHChef"

    # Version of the cookbook
    # Chef stores versions of cookbooks that have been uploaded
    version = '0.0.10'

    # Who is the maintainer of the cookbook?
    maintainer = "Russell Seymour"
    maintainer_email = "russell.seymour@turtlesystemsconsulting.co.uk"

    # What is the licence of the cookbook
    # NOTE:  This must be set as 'license'
    license = "GPL v2"

    # A short description of the cookbook
    description = "Cookbook to assist with the configuration of POSHChef on a server."

    # The long description about the cookbook
    # It is expected to be a file in the root of the cookbook
    long_description = "README.md"

}
