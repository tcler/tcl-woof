#!C:/Tcl/bin/tclsh86t.exe
# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# SCGI based Woof! server

################################################################
# Core SCGI loop

# Based on the SCGI package at http://wiki.tcl.tk/19670

namespace eval ::scgi {
    variable listener_so ""

    proc listen {port} {
        variable listener_so
        set listener_so [socket -server [namespace code connect] $port]
    }

    proc connect {sock ip port} {
        # TBD - should we make output also binary? Maybe required for
        # binary content ? May even give better performance ?
        fconfigure $sock -blocking 0 -translation {binary crlf}
        fileevent $sock readable [namespace code [list read_length $sock {}]]
    }

    proc read_length {sock data} {
        append data [read $sock]
        if {[eof $sock]} {
            close $sock
            return
        }
        set colonIdx [string first : $data]
        if {$colonIdx == -1} {
            # we don't have the headers length yet
            fileevent $sock readable [namespace code [list read_length $sock $data]]
            return
        } else {
            set length [string range $data 0 $colonIdx-1]
            set data [string range $data $colonIdx+1 end]
            read_headers $sock $length $data
        }
    }

    proc read_headers {sock length data} {
        append data [read $sock]

        if {[string length $data] < $length+1} {
            # we don't have the complete headers yet, wait for more
            fileevent $sock readable [namespace code [list read_headers $sock $length $data]]
            return
        } else {
            set headers [string range $data 0 $length-1]
            set headers [lrange [split $headers \0] 0 end-1]
            set body [string range $data $length+1 end]
            set content_length [dict get $headers CONTENT_LENGTH]
            read_body $sock $headers $content_length $body
        }
    }

    proc read_body {sock headers content_length body} {
        append body [read $sock]

        if {[string length $body] < $content_length} {
            # we don't have the complete body yet, wait for more
            fileevent $sock readable [namespace code [list read_body $sock $headers $content_length $body]]
            return
        } else {
	    # TBD - handle errors and exceptions from process_request
            if {[catch {
                ::woof::master::process_request [dict create \
                                                     socket $sock \
                                                     headers $headers \
                                                     body $body]
            } msg]} {
                catch {close $sock}
                catch {::woof::master::log err "Error: $msg -- $::errorInfo"}
            }
        }
    }
}



################################################################
# 

namespace eval ::woof::webservers::scgi { }
proc ::woof::webservers::scgi::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer
        constructor {args} {
            # Webserver interface class for SCGI
            #
            next {*}$args
        }

        method request_environment {request_context args} {
            # Retrieves the environment passed by the web server.
            #
            # request_context - opaque request context handle.
            #
            # See BaseWebServer for details.

            if {[llength $args] == 0} {
                return [dict get $request_context headers]
            }
            foreach arg $args {
                if {[dict exists $request_context headers $arg]} {
                    lappend vals $arg [dict get $request_context headers $arg]
                } else {
                    lappend vals $arg ""
                }
            }
            return $vals
        }

        method request_init {request_context} {
            # Called to initialize handling of each request.
            #
            # request_context - opaque request context handle passed
            #  to ::woof::handle_request
            #
            # This method is called by Woof to allow the web server
            # interface to do any required initialization of individual
            # requests.
            #
            # For SCGI, we initialize other packages that need to be reset
            # for each request.
            #
            # The parameter $request_context should be a handle to the web 
            # server context for this request. It should be passed through 
            # by Woof as received by woof::handle_request and may
            # be required by some web server modules to distinguish
            # between multiple requests being serviced concurrently by
            # the same interpreter.
            #

            if {[dict exists $request_context headers CONTENT_TYPE]} {
                set type [dict get $request_context headers CONTENT_TYPE]
            } else {
                set type ""
            }
            
            # TBD - HACK! HACK!, ncgi expects to read from content body from
            # stdin. Set it's internal variable so it thinks it has already
            # read. Really we need to fix to not use ncgi in persistent
            # servers
            switch -exact -- [dict get $request_context headers REQUEST_METHOD] {
                GET { ::ncgi::reset [dict get $request_context headers QUERY_STRING] $type}
                POST { ::ncgi::reset [dict get $request_context body] $type}
                default { ::ncgi::reset "" }
            } 

            return $request_context
        }

        method request_parameters {args} {
            # Retrieves the parameters for the current request.
            # 
            # The method parses and returns the parameters encoded in a 
            # request. Both query and form data are returned.
            # This method must be implemented by the concrete class.
            #
            # Returns the parameters received in the current request.
            
            return [::ncgi::nvlist]
        }

        method server_interface {} {
            # Get the webserver interface name
            return SCGI
        }

        method output {request_context response} {
            # Sends a response back to the client.
            # request_context - opaque request context handle. See
            #  request_init
            # response - dict structure containing data to be sent back.
            #
            # See BaseWebServer.output for information.

            # TBD - replace multiple puts with a single one
            # TBD - add error handling

            set sock [dict get $request_context socket]
            if {[dict exists $request_context headers SERVER_SOFTWARE] &&
                [string equal -length 13 Microsoft-IIS [dict get $request_context headers SERVER_SOFTWARE]]} {
                # On IIS, isapi_scgi expects a real HTTP status line
                # TBD - should this be 1.x, 1.0 or 1.1 ?
                puts $sock "HTTP/1.0 [dict get $response status_line]"
            } else { 
                # Other servers expect a Status: dummy header
                puts $sock "Status: [dict get $response status_line]"
            }
            foreach {k val} [dict get $response headers] {
                puts $sock "$k: $val"
            }
            puts $sock ""
            puts $sock [dict get $response content]
            close $sock
        }
    }
}


proc ::scgi::stop {} {
    variable listener_so
    if {$listener_so ne ""} {
        close $listener_so
        set listener_so ""
    }
    # TBD - do we need to track and shutdown/abort open socket connections ?

    set ::scgi::terminate true
}

proc ::scgi::main {rootdir args} {
    array set opts {
        -port 9999
    }
    array set opts $args
    scgi::listen $opts(-port)
    ::woof::master::init scgi $rootdir
    vwait ::scgi::terminate
}

################################################################
# Program execution begins here

# If we are not being included in another script, off and running we go
if {[file normalize $::argv0] eq [file normalize [info script]]} {
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. .. .. lib]]]
    package require ncgi
    source [file join [file dirname [info script]] .. .. .. lib woof master.tcl]
    # package require woof
    ::scgi::main [file normalize [file join [file dirname [info script]] .. .. ..]]
} else {
    package require ncgi
}
