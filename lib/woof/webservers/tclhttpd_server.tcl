# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Module for tclhttpd

# Figure out where we are. The woof root is one directory above us.
# We do not catch the error - let tclhttpd handle errors.

namespace eval ::woof::webservers::tclhttpd {}
proc ::woof::webservers::tclhttpd::init {args} {
    catch {WebServer destroy}
    oo::class create WebServer {
        superclass ::woof::webservers::BaseWebServer
        constructor {args} {
            # Webserver interface class for tclhttpd
            #
            next {*}$args
        }

        method server_interface {} {
            # Get the webserver interface module name.
            #
            # This method must be overridden by the concrete class.
            return tclhttpd
        }

        #
        # NOTE: we do not override the default logging interface to
        # use tclhttpd logging because that always requires a connection
        # socket to be passed in which is problematic in many cases as
        # it is not always available (e.g. on startup)

        method request_environment {request_context} {
            # Retrieves the environment passed by the web server.
            #
            # request_context - request context
            # 
            # Returns the environment as a key value list.

            array set cgienv [array get ::env]
            dict with request_context {
                Cgi_SetEnvAll $socket {} $suffix $prefix cgienv
            }
            return [array get cgienv]
        }

        method request_parameters {request_context} {
            # Retrieves the parameters for the current request.
            # 
            # The method parses and returns the parameters encoded in a 
            # request. Both query and form data are returned.
            # This method must be implemented by the concrete class.
            #
            # Returns the parameters received in the current request.
            
            upvar #0 Httpd[dict get $request_context sock] data
            if {[info exist data(query)]} {
                # TBD - confirm that this returns POST data as well
                return [Url_DecodeQuery $data(query)]
            }
            return {}
        }

        method output {request_context response} {
            # Sends a response back to the client.
            # request_context - opaque request context handle. See
            #  request_init
            # response - dict structure containing data to be sent back.
            #
            # See BaseWebServer.output for information.

            set sock [dict get $request_context socket]
            foreach {k val} [dict get $response headers] {
                if {[string equal -nocase content-type $k]} {
                    set ctype $val
                }
                Httpd_AddHeaders $sock $k $val
            }

            Httpd_ReturnData $sock \
                $ctype \
                [dict get $response content] \
                [dict get $response status]
        }
    }
}

source [file join [file dirname [info script]] .. lib woof master.tcl]
::woof::master::init tclhttpd

# Tell tclhttpd what our URL root is
Url_PrefixInstall [::woof::master::configuration get url_root] \
    [list ::woof::webservers::tclhttpd::request_callback \
         [::woof::master::configuration get url_root]]

# Ditto for the document root
#Doc_Root [::woof::master::configuration get public_dir]

namespace eval ::woof::webservers::tclhttpd {
    proc request_callback {prefix sock suffix} {
	# Emulating (somewhat) Apache's rewrite rule set up for Woof, we
	# if the file exists, we handle it as a real file, and not
	# a Woof script. The file must lie in the public area.
        if {[string length $suffix]} {
            set fn [file join [::woof::master::configuration get public_dir] $suffix]
            if {[file exists $fn]} {
                Httpd_ReturnFile $sock [Mtype $fn] $fn
                return
            }
        }

        # TBD - do we need to call tclhttpd Url_PathCheck somewhere?
        ::woof::master::process_request [dict create socket $sock prefix $prefix suffix $suffix]
    }
}
