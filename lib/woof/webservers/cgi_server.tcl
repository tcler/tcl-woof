# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

package require ncgi

namespace eval ::woof::webservers::cgi_server {}
proc ::woof::webservers::cgi_server::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer
        constructor {args} {
            # Webserver interface class for CGI using the ncgi package.
            #
            next {*}$args
        }

        method request_parameters {args} {
            # Retrieves the parameters for the current request.
            # 
            # The method parses and returns the parameters encoded in a 
            # request. Both query and form data are returned.
            #
            # Returns the parameters received in the current request.
            
            # TBD - placeholder for returning values in canonical format
            return [::ncgi::nvlist]
        }

        method server_interface {} {
            # Get the webserver interface name.
            return CGI
        }

        method output {request_context response} {
            # Sends a response back to the client.
            # response - Response dict containing data to be sent back.
            #
            puts -nonewline "Status: [dict get $response status_line]\r\n"
            foreach {k val} [dict get $response headers] {
                puts -nonewline "$k: $val\r\n"
            }
            puts -nonewline "\r\n"
            puts [dict get $response content]
        }
    }

    return [namespace current]::WebServer
}

# The woof root is expected to be our parent directory
if {[catch {
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. lib]]]
    source [file join [file dirname [info script]] .. lib woof master.tcl]
    ::woof::master::init cgi_server [file normalize [file join [file dirname [info script]] ..]]
    set output_done [::woof::master::process_request]
} msg]} {
    if {[info exists output_done] && $output_done} {
	# handle_request would have sent the output so we do not need to.
	# (where output may have been even an error message)
    } else {
	puts -nonewline "Content-type: text/html\r\n\r\n"
	puts "<p>Error: [::woof::util::hesc $msg]</p>"
    }
    error $msg
}



