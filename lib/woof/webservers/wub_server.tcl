# Copyright (c) 2009, Colin McCormack
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof Module for Wub

namespace eval ::woof::webservers::wub_server {}
proc ::woof::webservers::wub_server::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer
	variable fields
        constructor {args} {
            # Webserver interface class for wub
            #
	    set fields {}
            next {*}$args
        }

        method init_log {fac} {
            # Called to initialize the logging facility.
            # fac - the facility name to use for logging.
            #
            # The Woof logging facility calls this method to initialize
            # the logging component of the web server interface.
            #
            # The concrete web server interface class can override this
            # method.
            return
        }

        method log {level msg} {
            # Called to log a message
            # level - logging level for the message. Possible values
            #  are defined in Log.
            # msg - text of the message
            #
            # The default implementation is very simplistic. It opens the
            # log file on every write, does not buffer, does not rollover
            # log files. Concrete implementations should override the method.
            # 

            return
        }

        method request_environment {r} {
	    lappend env SERVER_SOFTWARE $::Httpd::server_id
	    # name and version of the server. Format: name/version

	    lappend env GATEWAY_INTERFACE CGI/1.1
	    # revision of the CGI specification to which this server complies.
	    # Format: CGI/revision

	    lappend env SERVER_NAME [dict get? $r -host]
	    # server's hostname, DNS alias, or IP address
	    # as it would appear in self-referencing URLs.

	    lappend env SERVER_PROTOCOL [dict get? $r -scheme]
	    # name and revision of the information protcol this request came in with.
	    # Format: protocol/revision

	    lappend env SERVER_PORT [dict get? $r -port]
	    # port number to which the request was sent.
	    
	    set url [Url parse [dict get? $r -uri]]
	    lappend env REQUEST_URI [dict get? $r -uri]
	    lappend env REQUEST_METHOD [dict get? $r -method]
	    # method with which the request was made.
	    # For HTTP, this is "GET", "HEAD", "POST", etc.

	    lappend env HTTP_HOST [dict get? $r -host]:[dict get? $r -port]

	    if {[dict get? $url -query] ne ""} {
		lappend env QUERY_STRING [dict get? $url -query]
		# information which follows the ? in the URL which referenced this script.
		# This is the query information. It should not be decoded in any fashion.
		# This variable should always be set when there is query information,
		# regardless of command line decoding.
	    }

	    lappend env PATH_INFO [dict get? $r -info]
	    # extra path information, as given by the client.
	    # Scripts can be accessed by their virtual pathname, followed by
	    # extra information at the end of this path.
	    # The extra information is sent as PATH_INFO.
	    # This information should be decoded by the server if it comes
	    # from a URL before it is passed to the CGI script.

	    lappend env PATH_TRANSLATED [dict get? $r -translated]
	    # server provides a translated version of PATH_INFO,
	    # which takes the path and does any virtual-to-physical mapping to it.
	    
	    lappend env SCRIPT_NAME [dict get? $r -script]
	    # A virtual path to the script being executed, used for self-referencing URLs.
	    
	    lappend env REMOTE_ADDR [dict get? $r -ipaddr]
	    # IP address of the remote host making the request.

	    if {[dict exists $r -entity]} {
		lappend env CONTENT_TYPE [dict get? $r content-type]
		# For queries which have attached information, such as HTTP POST and PUT,
		# this is the content type of the data.

		lappend env CONTENT_LENGTH [dict get? $r content-length]
		# The length of the said content as given by the client.
	    }

	    # Header lines received from the client, if any, are placed
	    # into the environment with the prefix HTTP_ followed by the header name.
	    # If necessary, the server may choose to exclude any or all of these headers
	    # if including them would exceed any system environment limits.
	    foreach field $fields {
		if {[dict exists $r $field]} {
		    lappend env [string map {- _} [string toupper $field]] [dict get $r $field]
		}
	    }
	    return $env
	}

        method request_parameters {r} {
            # Retrieves the parameters for the current request.
            # 
            # The method parses and returns the parameters encoded in a 
            # request. Both query and form data are returned.
            # This method must be implemented by the concrete class.
            #
            # Returns the parameters received in the current request.
            set result {}
	    set qd [Query parse $r]
	    foreach n [Query vars $qd] {
		foreach v [Query values $qd $n] {
		    lappend result $n $v
		}
	    }
	    return $result
        }

        method server_interface {} {
            # Get the webserver interface name.
            #
            return Wub
        }

        method output {r response} {
            # Sends a response back to the client.
            # response - Response object containing data to be sent back.
            #
            # The method retrieves the headers and content from the
            # Response dict passed in and sends them to the client.

	    # add in the normally modified headers
            foreach {k val} [dict get $response headers] {
                dict set r [string tolower $k] $val
            }

	    # add in the meta-headers
	    dict set r -code [dict get $response status]
	    dict set r -content [dict get $response content]
	    dict set r content-length [string length [dict get $r -content]]
	    dict set r content-type [dict get $response content_type]

	    # send the result back to the network coro
	    corovars reader
	    Httpd csend $reader [Httpd post $r]
        }
    }
}

package require woof
package require Woof;  # TBD Note upper case W, talk to Colin about fixing to avoid confusion

# Initialize woof
::woof::master::init wub_server

