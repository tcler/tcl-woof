# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

namespace eval ::woof::webservers::console {}
proc ::woof::webservers::console::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer

        constructor {} {
            # Nothing to do here
            next
        }

        # Logging interfaces required by Woof!
        method init_log {fac} {
            my variable _facility
            set _facility $fac
        }

        method log {level msg} {
            my variable _facility
            puts stderr "${_facility}.$level $msg"
        }

        method request_init {args} {
            ::ncgi::reset;                      # Clear out old data from ccgi
            ::ncgi::parse
        }

        method request_environment {args} {
            return [array get ::env]
        }

        # Parse query parameters
        method request_parameters {args} {
            return [::ncgi::nvlist]
        }

        method server_interface {} {
            return console
        }

        method output {request_context response} {
            upvar 0 $request_context out
            set out "HTTP/?? [dict get $response status_line]\n"
            foreach {k val} [dict get $response headers] {
                append out "$k: $val\n"
            }
            append out \n
            append out [dict get $response content]\n
        }
    }
}
