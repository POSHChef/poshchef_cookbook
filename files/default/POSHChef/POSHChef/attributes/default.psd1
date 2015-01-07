
# This file holds default attributes for the cookbook
# Any of these can be overridden using a Role or an Environment

# The format of the file is important due to the necessary interaction with Chef server
# It is a PowerShell based hashtable, but th names of the variables are very crucial
#

@{

	# Default attributes
	default = @{

        POSHChef = @{

            # The interval at which POSHChef will run
            # This value should be in minutes
            interval = 30

            task = @{
                name = "POSHChef"
                description = "Scheduled task to run POSHChef every 30 minutes"
                folder = "POSHChef"

                triggers = @(
                    @{
                        type = "once"
                        minutes = 30
                    }
                    @{
                        type = "boot"
                        delay = @{
                            minutes = 2
                        }
                    }
                )

                credentials = @{
                    username = ""
                    password = ""
                }
            }

            # Confgiuration for WINRM settings
            wsman = @{
                "MaxEnvelopeSizekb" = 2048
				"shell\MaxMemoryPerShellMB" = 1024
            }

            # Define paths that will be used to store files such as scripts and data
            paths = @{
                scripts = "C:\Utilities\scripts"
                data = "C:\Utilities\data"
            }

            # Setup settings for the handlers
            handlers = @{

                settings = @{
                    graphite = @{
                        server = "localhost"
                        port = 2003
                    }

                    redis = @{
                        server = "localhost"
                        queue = "logstash"
                    }

                    elasticsearch = @{
                        server = "localhost"
                        port = 9200
                        index = "logstash"
                        mapping = "logs"
                    }
                }

                enabled = @(
                    "logstash-handler.ps1"
                )
            }
        }

	}
}
