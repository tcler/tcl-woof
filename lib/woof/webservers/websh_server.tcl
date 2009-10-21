# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Interface to mod_websh

web::initializer {
    if {[catch {

        ##################################################################
        # Define commands that Woof! expects the webserver bridge to provide

        namespace eval ::woof::webservers::websh_server { }
        proc ::woof::webservers::websh_server::init args {
            catch {WebServer destroy}
            oo::class create WebServer {
                superclass ::woof::webservers::BaseWebServer

                constructor {} {
                    my variable _log_level_map
                    # Maps Woof! log levels to websh log levels
                    array set _log_level_map {
                        debug  debug
                        info   info
                        notice warn
                        warn   warn
                        err    error
                        crit   alert
                        alert  alert
                        emerg  alert
                    }
                }

                # Logging interfaces required by Woof!
                method init_log {fac} {
                    my variable _facility
                    set _facility $fac
                    # TBD - check this
                    web::logfilter add *.debug-alert
                    web::logdest add *.debug-alert apache
                }

                method log {level msg} {
                    my variable _facility
                    my variable _log_level_map
                    if {[info exists _log_level_map($level)]} {
                        set level $_log_level_map($level)
                    } else {
                        set msg "Warning: An attempt was made to log the following message with unknown log level '$level': $msg"
                        set level warn
                    }
                    web::log ${_facility}.$level $msg
                }

                method request_environment {req_context args} {
                    set environ {}
                    if {[llength $args] == 0} {
                        set args [::web::request -names]
                    }
                    foreach name $args {
                        lappend environ $name [web::request $name]
                    }
                    return $environ
                }

                method request_parameters {args} {
                    if {[::web::request REQUEST_METHOD GET] eq "POST"} {
                        set cmd formvar
                    } else {
                        set cmd param
                    }
                    set params {}
                    foreach key [web::$cmd -names] {
                        lappend params $key [web::$cmd $key]
                    }
                    return $params
                }

                method server_interface {} {
                    return Websh
                }

                method output {request_context response} {
                    web::response -reset
                    web::response -httpresponse "HTTP/?? [dict get $response status_line]"
                    # TBD - does headers also contain Status ?
                    # Headers may contain duplicates. Collect duplicates first
                    # TBD - do we have to be careful about the order?
                    set hdrs [dict create]
                    foreach {k val} [dict get $response headers] {
                        dict lappend hdrs $k $val
                    }
                    dict for {k val} $hdrs {
                        web::response -set $k {*}$val
                    }
                    web::put [dict get $response content]
                }
            }
        }

        set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [web::config script]] .. lib]]]
        source [file join [file dirname [web::config script]] .. lib woof master.tcl]
        ::woof::master::init websh_server [file normalize [file join [file dirname [web::config script]] ..]]

    } msg]} {
        web::put "Error: $msg, auto_path: $auto_path"
        error $msg
    }
}



# parse query-string. We need to set up param and session array
# Note this does not actually dispatch any command
# TBD - do we need this line?
web::dispatch -cmd "" 

try {
    ::woof::master::process_request
} finally {
    if {[::woof::config get reload_scripts false]} {
        web::interpcfg retire true
    }
}


