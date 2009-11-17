# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof Module for Wibble

namespace eval ::woof::webservers::wibble {    
    # Variable to signal that we should terminate
    variable terminate
    variable docroot
}

proc ::woof::webservers::wibble::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer
        constructor {args} {
            # Webserver interface class for wibble
            #
            next {*}$args
        }

        # method init_log - inherited
        # method log - inherited

        method request_environment {req args} {
            # Retrieves the environment passed by the web server.
            #
            # req - opaque request context handle.
            #
            # Refer to BaseWebServer for details.
            
            # TBD - optimize this to not return unnecessary values

	    dict set env SERVER_SOFTWARE "[my server_interface]/[package require wibble]"
	    # name and version of the server. Format: name/version

	    dict set env GATEWAY_INTERFACE CGI/1.1
	    # revision of the CGI specification to which this server complies.
	    # Format: CGI/revision

            dict set env HTTP_HOST [dict get $req header host]

            # TBD - SERVER_PORT may be slow as it might try to resolve host name,
            # may be explicitly pass server port(s) ?
            dict set env SERVER_PORT [lindex [fconfigure [dict get $req socket] -sockname] 2]
	    dict set env SERVER_NAME [lindex [split [dict get $env HTTP_HOST] :] 0]
	    dict set env SERVER_PROTOCOL [dict get $req protocol]
            dict set env REQUEST_URI [dict get $req uri]
	    dict set env REQUEST_METHOD [dict get $req method]
            # TBD - should we decode query ? CGI spec seems to say no but Woof Request
            # class assumes it is already decoded
            dict set env QUERY_STRING [dict get $req rawquery]
	    dict set env SCRIPT_NAME [dict get $req prefix]
            set suffix [dict get $req suffix]
	    dict set env PATH_INFO $suffix
	    dict set env PATH_TRANSLATED [file join [dict get $req fspath] $suffix]
	    dict set env REMOTE_ADDR [dict get $req peerhost]
            dict set env REMOTE_PORT [dict get $req peerport]
	    if {[dict exists $req content-type]} {
		dict set env CONTENT_TYPE [dict get $req header content-type]
            }
	    if {[dict exists $req content-length]} {
		dict set env CONTENT_LENGTH [dict get $req header content-length]
            }

            # Append all HTTP headers sent by the client
            # wibble concatenates multiple header values with \n. As
            # per HTTP spec, multiple headers are equivalent to a single
            # header with values separated with ",".
            dict for {k val} [dict get $req header] {
                dict set env "HTTP_[string map {- _} [string toupper $k]]" \
                    [string map [list \n ,] $val]
	    }

            # If any args specified, make sure they are set in returned value
            # to empty strings if not in environment
            foreach arg $args {
                if {![dict exists $env $arg]} {
                    dict set env $arg ""
                }
            }

	    return $env
        }

        # method request_init - inherited

        method request_parameters {request_context} {
            set params [dict get $request_context query]
            if {[dict get $request_context method] eq "POST"} {
                # Copied from wibble query parsing code.
                # TBD - fix, probably not quite right
                foreach elem [split [dict get $request_context content] &] {
                    regexp {^([^=]*)(?:=(.*))?$} $elem _ key val
                    # TBD - what kind of decoding need be done? URL-decoding
                    # HTML-decoding ?
                    lappend params $key $val
                }
            }
            return $params
        }

        method server_interface {} {
            # Get the webserver interface module name.
            return wibble
        }

        method output {request_context response} {
            set id [dict get $request_context woof_req_id]
            set ::woof::webservers::wibble::responses($id) \
                [dict create \
                     status [dict get $response status] \
                     content [dict get $response content] \
                     header [dict get $response headers]]
        }
    }
}

proc ::woof::webservers::wibble::request_handler {request response} {
    # Called from Wibble to handle a request
    # request - a dictionary containing client request.
    #   see Wibble documentation.
    # response - a dictionary into which the response is to be built. 
    #   See Wibble documentation.
    # 
    variable responses;         # Array indexed by request id
    variable request_id
    
    # TBD - better handling of errors and exceptions from process_request
    try {
        set id [incr request_id]
        dict set request woof_req_id $id
        ::woof::master::process_request $request
    } on error {msg eopts} {
        catch {::woof::master::log err "Error: $msg -- $::errorInfo"}
        return -options $eopts $msg
    }

    if {[info exists responses($id)]} {
        ::wibble::sendresponse "$responses($id)[unset responses($id)]"; # RETURNS TO CALLER!
    } else {
        # TBD - should we pass on the request to next handler or
        # generate an error ?
        ::wibble::nexthandler $request $response; # RETURNS TO CALLER!
    }
    # EXECUTION NEVER REACHES HERE!
}


proc ::woof::webservers::wibble::stop {rootdir args} {
    # Terminates the wibble server
    variable terminate
    set terminate true
}

proc ::woof::webservers::wibble::main {rootdir args} {
    variable terminate
    variable docroot
    array set opts {
        -port 8015
        -urlroot /
    }
    array set opts $args
    set docroot [file join $rootdir public]
    ::woof::master::init wibble $rootdir
    wibble::handle $opts(-urlroot) static root $docroot
    wibble::handle \
        $opts(-urlroot) \
        [namespace current]::request_handler \
        root $docroot
    wibble::handle / notfound;  # notfound proc defined in wibble
    wibble::listen $opts(-port)
    vwait [namespace current]::terminate
}

################################################################
# Program execution begins here

# If we are not being included in another script, off and running we go
if {[file normalize $::argv0] eq [file normalize [info script]]} {
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. .. .. lib]]]
    lappend auto_path [file normalize [file join [file dirname [info script]] .. .. .. thirdparty]]
    package require uri
    package require wibble
    source [file join [file dirname [info script]] .. .. .. lib woof master.tcl]
    ::woof::webservers::wibble::main [file normalize [file join [file dirname [info script]] .. .. ..]]
} else {
    package require uri
    package require wibble
}

