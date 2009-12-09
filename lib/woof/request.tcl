# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
# In Woof!, that will be the ::woof namespace


catch {Environment destroy}
oo::class create Environment {
    superclass ::woof::util::Map
    constructor {request_context} {
        # Constructs a Map object as provided by the web server.
        #
        # Application code may access the environment
        # using the standard Map interfaces.
        my variable _request_context
        set _request_context $request_context
        next 
    }

    method lazy_load {args} {
        # Loads the environment values on demand.
        # args -  See Map.lazy_load
        # Note that for performance reasons, the method loads all environment
        # values in the Map and not just the keys specified in $args.
        #
        # See Map.lazy_load for details.
        my variable _request_context

        if {[info exists _request_context]} {
            my set {*}[::woof::webserver request_environment $_request_context]
            # Once we load all that we have, unset _request_context
            # so we don't unnecessarily load again on the next call.
            unset _request_context
        }
    }
}

catch {Params destroy}
oo::class create Params {
    superclass ::woof::util::Map
    constructor {request_context} {
        # Contains the form and query string values associated with
        # a request.
        #
        # Application code may access values associated with keys
        # using the standard Map interfaces.
        my variable _request_context
        set _request_context $request_context
        next
    }

    method lazy_load {args} {
        # Loads the query parameter values on demand.
        # args -  See Map.lazy_load
        # Note that for performance reasons, the method loads all received
        # parameter values in the Map and not just the keys specified in $args.
        # See Map.lazy_load for details.
        my variable _request_context
        my set {*}[::woof::webserver request_parameters $_request_context]
    }
}


#
# The request object, contains contents of the actual request.
catch {Request destroy}; # To allow re-sourcing
oo::class create Request {
    variable _context;          # Request context from web server, opaque

    constructor {request_context} {
        # A Request object holds various attributes and context associated with
        # a received client request.
        # request_context - an opaque handle identifying the request that
        #   will be passed through to the web server module
        #
        # A Request object is associated with every incoming request.
        # Application code can use the methods of this object to retrieve
        # various pieces of information about the received request.
        #
        # This class contains default implementations of various
        # methods to retrieve request information. 
        # A web server interface may specialize this 
        # to provide more efficient means
        # of accessing data.

        
        # NOTE - experimentation shows the objects created below
        # get automatically destroyed when containing object is destroyed
        # without needing explicit destruction in a destructor.
        # TBD - Confirm with DKF

        set _context $request_context

        #ruff
        # The environment passed by the web server is encapsulated
        # as an Environment object may be accessed through the 'env' method.
        # Within application context in a Controller, this may also
        # be accessed as the 'env' object.

        ::woof::Environment create env $request_context
        oo::objdefine [self] "forward env [self namespace]::env"

        #ruff
        # The cookies contained in the request may be accessed
        # as a CookiesIn object through the 'cookies' method. Again,
        # within application context in a Controller object, this
        # can also be accessed as the 'icookies' object.
        ::woof::CookiesIn create cookies [env get HTTP_COOKIE {}]
        oo::objdefine [self] "forward cookies [self namespace]::cookies"

        #ruff
        # The query and form string values received with the request
        # may be accessed as a Params object through the 'params' method.
        # Within application context in a Controller, it
        # can also be accessed as the 'params' object.
        ::woof::Params create params $request_context
        oo::objdefine [self] "forward params [self namespace]::params"
    }

    # Define methods for accessing contained maps
    # BAD - THIS DOES NOT WORK AS ANY VARIABLES SET IN CALLER'S CONTEXT
    # WILL BE SET IN THESE METHODS AS OPPOSED TO IN THE METHOD CALLER's
    # CONTEXT. HENCE WE USE forward instead (see constructor).
    # TBD - maybe we can invoke in caller's namespace as follows:
    #       return [uplevel 1 [list [self namespace]::env] $args]
    # method env args { return [env {*}$args] }
    # method cookies args { return [cookies {*}$args] }
    # method params args { return [params {*}$args] }

    method ssl? {} {
        # Returns true if the request came over an SSL connection
        # and false otherwise.
        if {[env exists HTTPS https] && ($https eq "on")} {
            return true
        }
        if {[env exists HTTP_X_FORWARDED_PROTO https] && {$https eq "https"}} {
            return true
        }
        return false
    }

    method protocol {} {
        # Returns the connection protocol over which the request was received.
        return [expr {[my ssl?] ? "https" : "http"}]
    }

    method standard_port {} {
        # Returns the standard port used for the protocol
        # over which the connection was received.
        #
        # Note this is not necessarily the same as the port on which
        # the request actually arrived.
        return [expr {[my protocol] eq "https" ? 443 : 80}]
    }

    method _raw_host_with_port {} {

        if {[env exists HTTP_X_FORWARDED_HOST host]} {
            # List of forwards separated by commas. We are the first
            # in the list. Note whitespace may separate entries
            set host [string trim [lindex $hosts 0]]
        } elseif {(![env exists HTTP_HOST host]) &&
                  (![env exists SERVER_NAME host])} {
            # All attempts failed, use address and port
            set host "[env get SERVER_ADDR]:[env get SERVER_PORT]"
        }

        # Verify before returning that it matches allowed syntax since
        # some information comes from client side. Note this does not
        # protect against spoofing but only against potentially dangerous
        # characters like | or []
        if {[regexp {^([-_.[:alnum:]]+)(:[[:digit:]]+)?$} $host notused hostonly port]} {
            set port [string range $port 1 end]; # Get rid of :
        } else {
            throw [list WOOF BADDATA "Bad hostname:port format"] "Invalid hostname:port syntax ($host)"
        }
        
        # Return as a list. Note port may be ""
        return [list $host $hostonly $port]
    }

    method formatted_host_with_port {} {
        # Returns the host and port associated with this request.
        lassign [my _raw_host_with_port] host_and_port host port
        if {$port == "" || $port == [my standard_port]} {
            #ruff If the request came over the standard port for the
            # protocol, it is not included in the returned string.
            return $host
        } else {
            return "$host:$port"
        }
    }
    
    method port {} {
        # Returns the port on which the request was received.
        set port [lindex [my _raw_host_with_port] 2]
        if {$port ne ""} {
            return $port
        } 
        return [my standard_port]
    }

    method host {} {
        return [lindex [my _raw_host_with_port] 1]
    }

    method url {} {
        # Returns the full URL for the request
        return "[my protocol]://[my formatted_host_with_port][my request_uri]"
    }

    method request_uri {} {
        # Returns the request URI (the portion after the hostname/port)
        # for the request.

        # See if REQUEST_URI exists (Apache and its disciples),
        # or HTTP_X_ORIGINAL_URL (IIS mod_rewrite)
        # or HTTP_X_REWRITE_URL (IIS isapi_rewrite)
        if {[env exists REQUEST_URI uri] || 
            [env exists HTTP_X_ORIGINAL_URL uri] ||
            [env exists HTTP_X_REWRITE_URL uri]} {

            # Some servers like tclhttpd include protocol, hostname
            # Strip these off (basically we follow Apache)
            array set parts [uri::split $uri]
            set uri /$parts(path)
            if {$parts(query) ne ""} {
                append uri ?$parts(query)
            }
            return $uri
        }

        # None of the above env vars exists.
        # Construct it
        set uri [my resource_url]
        if {[env exists URL url]} {
            set uri "$url$uri"
        }

        # Tack on query string
        if {[env exists QUERY_STRING qs] && $qs ne ""} {
            append uri "?$qs"
        }
        return $uri
    }

    method request_method {} {
        # Returns the HTTP method in the request.
        return [string tolower [env get REQUEST_METHOD]]
    }

    method get? {} {
        # Returns true if the HTTP request method was a GET
        # and false otherwise.
        return [expr {[my request_method] eq "get"}]
    }

    method head? {} {
        # Returns true if the HTTP request method was a HEAD
        # and false otherwise.
        return [expr {[my request_method] eq "head"}]
    }

    method post? {} {
        # Returns true if the HTTP request method was a POST
        # and false otherwise.
        return [expr {[my request_method] eq "post"}]
    }

    method delete? {} {
        # Returns true if the HTTP request method was a DELETE
        # and false otherwise.
        return [expr {[my request_method] eq "delete"}]
    }

    method get_or_head? {} {
        # Returns true if the HTTP request method was a GET or HEAD
        # and false otherwise.
        if {[my request_method] in {get head}} {
            return true
        } else {
            return false
        }
    }

    method application_url {} {
        # Returns the URL path where the application is rooted.
        #
        # This is NOT necessarily
        # the same as the 'url_root' value in the Woof! config
        # dictionary and is dependent on how the web server is configured.
        # For example, with IIS using SCGI, /myapp maybe mapped to
        # /myapp/isapi_scgi.dll. This method will return the latter
        # though the former is the value of 'url_root' in the configuration
        # file.
        #
        # Note the returned path does not include the protocol, host
        # or port number.

        if {[env exists SCRIPT_NAME path]} {
            # For example, /myapp/isapi_scgi.dll -> /myapp
            set path [file dirname $path]
            if {$path eq ""} {
                set path /
            }
            return $path
        } else {
            # TBD - assume / ?
            return /
        }
    }

    method resource_url {} {
        # Returns the resource URL path within the application root URL.
        #
        # This is the portion of the request url beyond the application
        # root url and excludes the query string.
        set rurl [env get PATH_INFO ""]

        # On IIS, depending on some obscure metabase setting, PATH_INFO
        # may or may not include the path to the invoked script.
        # Check and get rid of it
        if {[env exists SCRIPT_NAME script_name]} {
            if {[string index $script_name end] ne "/"} {
                # Script name does not end with a /, get rid of it from
                # the path_info if it is a prefix
                set len [string length $script_name]
                if {[string equal -length $len $script_name $rurl] &&
                    [string index $rurl $len] eq "/"} {
                    set rurl [string range $rurl $len end]
                }
            }
        }
        return $rurl
    }

    method query_string {} {
        # Returns the query string portion of request

        # TBD - is the query string already decoded or not ?
        if {[env exists REQUEST_URI uri]} {
            return [lindex [split $uri ?] 1]
        } else {
            return [env get QUERY_STRING ""]
        }
    }

    method referer {} {
        # Returns the HTTP_REFERER header in the request
        # if present, else an empty string
        return [env get HTTP_REFERER ""]
    }

    method remote_addr {} {
        # Returns the address of the remote client if available,
        # else an empty string.
        return [env get REMOTE_ADDR ""]
    }

    method accept_languages {} {
        return [::woof::util::memoize \
                    ::woof::util::http_sorted_header_values \
                    [env get HTTP_ACCEPT_LANGUAGE {}]]
    }

}





namespace eval [namespace current] {
    namespace export Request
}
