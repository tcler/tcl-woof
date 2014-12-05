# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof Module for Wibble

namespace eval ::woof::webservers::wibble {    
    # Variable to signal that we should terminate
    variable terminate
    variable docroot

    variable wibble_version;    # Version of wibble server
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

        method request_environment {state args} {
            # Retrieves the environment passed by the web server.
            #
            # state - State dictionary passed by wibble
            #
            # Refer to BaseWebServer for details.
            
            set req [dict get $state request]

            # TBD - optimize this to not return unnecessary values

	    dict set env SERVER_SOFTWARE "[my server_interface]/$::woof::webservers::wibble::wibble_version"
	    # name and version of the server. Format: name/version

	    dict set env GATEWAY_INTERFACE CGI/1.1
	    # revision of the CGI specification to which this server complies.
	    # Format: CGI/revision

            dict set env HTTP_HOST [dict get $req header host]

            dict set env SERVER_PORT [dict get $req port]
	    dict set env SERVER_NAME [lindex [split [dict get $env HTTP_HOST] :] 0]
	    dict set env SERVER_PROTOCOL [dict get $req protocol]
            dict set env REQUEST_URI [dict get $req uri]
	    dict set env REQUEST_METHOD [dict get $req method]

            # TBD - should we decode query ? CGI spec seems to say no but Woof Request
            # class assumes it is already decoded

            # rawquery includes "?" prefix - remove it
            if {[dict exists $req rawquery]} {
                dict set env QUERY_STRING [string range [dict get $req rawquery] 1 end]
            } else {
                dict set env QUERY_STRING ""
            }
	    dict set env SCRIPT_NAME [dict get $state options prefix]
            set suffix [dict get $state options suffix]
	    dict set env PATH_INFO /[string trimleft $suffix /]
	    dict set env PATH_TRANSLATED [file join [dict get $state options fspath] $suffix]
	    dict set env REMOTE_ADDR [dict get $req peerhost]
            dict set env REMOTE_PORT [dict get $req peerport]
	    if {[dict exists $req content-type]} {
		dict set env CONTENT_TYPE [dict get $req header content-type]
            }
	    if {[dict exists $req content-length]} {
		dict set env CONTENT_LENGTH [dict get $req header content-length]
            }

            # Append all HTTP headers sent by the client
            # wibble overwrites multiple header values in the header key
            # so we process the rawheader field ourselves. As
            # per HTTP spec, multiple headers are equivalent to a single
            # header with values separated with ",".
            set hdrs {}
            foreach line [dict get $req rawheader] {
                set pos [string first : $line]
                if {$pos > 0} {
                    set hdrkey "HTTP_[string map {- _} [string toupper [string range $line 0 $pos-1]]]"
                    # TBD - any decoding to be done on values?
                    dict lappend hdrs $hdrkey [string trim [string range $line [incr pos] end]]
                }
            }
            dict for {hdrkey hdrvals} $hdrs {
                dict set env $hdrkey [join $hdrvals ,]
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

        method request_parameters {ctx} {
            set params {}
            # Wibble query and post dictionaries are strucured such
            # that keys with non-empty values have the value stored
            # in a sub-dictionary with key ""
            if {[dict exists $ctx request query]} {
                set query [dict get $ctx request query]
                dict for {k val} $query {
                    if {[dict exists $val ""]} {
                        lappend params $k [dict get $val ""]
                    } else {
                        lappend params $k ""
                    }
                }
            }
            if {[dict get $ctx request method] eq "POST" &&
                [dict exists $ctx request post]} {
                set query [dict get $ctx request post]
                dict for {k val} $query {
                    if {[dict exists $val ""]} {
                        lappend params $k [dict get $val ""]
                    } else {
                        lappend params $k ""
                    }
                }
            }
            return $params
        }

        method server_interface {} {
            # Get the webserver interface module name.
            return wibble
        }

        method output {state response} {
            set id [dict get $state woof_req_id]

            set need_server_header 1
            dict for {k v} [dict get $response headers] {
                if {$k eq "Server"} {
                    set need_server_header 0
                    break
                }
            }
            if {$need_server_header} {
                dict set response headers Server "[string totitle [my server_interface]]/$::woof::webservers::wibble::wibble_version"
            }
            set ::woof::webservers::wibble::responses($id) \
                [dict create \
                     status [dict get $response status] \
                     status_line [dict get $response status_line] \
                     content [dict get $response content] \
                     encoding [dict get $response encoding] \
                     headers [dict get $response headers]]
        }
    }
}

proc ::woof::webservers::wibble::request_handler {state} {
    # Called from Wibble to handle a request
    # state - a dictionary containing keys 'request', 'response' and 'options'.
    #   See Wibble documentation.
    # 
    variable responses;         # Array indexed by request id
    variable request_id
    
    # TBD - better handling of errors and exceptions from process_request

    try {
        set id [incr request_id]
        dict set state woof_req_id $id
        ::woof::master::process_request $state
    } on error {msg eopts} {
        catch {::woof::master::log err "Error: $msg -- $::errorInfo"}
        return -options $eopts $msg
    }

    if {[info exists responses($id)]} {
        set response $responses($id)
        unset responses($id)
        # We do not use the default wibble sendcommand because
        # it uses a different format for the header structure
        dict set response sendcommand [namespace current]::sendcommand
        ::wibble::sendresponse $response; # RETURNS TO CALLER!
    } else {
        # TBD - should we pass on the request to next handler or
        # generate an error ?
        ::wibble::nexthandler $state; # RETURNS TO CALLER!
    }
    # EXECUTION NEVER REACHES HERE!
}

proc xxx {} {
    set persist 0


}

proc ::woof::webservers::wibble::sendcommand {sock request response} {
    set persist [expr {
        [dict get $request protocol] >= "HTTP/1.1"
        && (! [dict exists $request header connection] ||
            ![string equal -nocase [dict get $request header connection] close])
    }]

    chan configure $sock -translation binary
    set head "[dict get $request protocol] [dict get $response status_line]\r\n"
    foreach {k val} [dict get $response headers] {
        append head "$k: $val\r\n"
    }

    set content [encoding convertto [dict get $response encoding] [dict get $response content]]

    if {!$persist} {
        append head "Connection: close\r\n"
    }
    append head "Content-Length: [string length $content]\r\n\r\n"
    puts -nonewline $sock $head
    if {![string equal -nocase [dict get $request method] HEAD]} {
        puts -nonewline $sock $content
    }

    return $persist
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
    wibble::handle / contenttype typetable {
        application/javascript  ^js$                  application/json  ^json$
        application/pdf ^pdf$                         audio/mid      ^(?:midi?|rmi)$
        audio/mp4       ^m4a$                         audio/mpeg     ^mp3$
        audio/ogg       ^(?:flac|og[ag]|spx)$         audio/vnd.wave ^wav$
        audio/webm      ^webm$                        image/bmp      ^bmp$
        image/gif       ^gif$                         image/jpeg     ^(?:jp[eg]|jpeg)$
        image/png       ^png$                         image/svg+xml  ^svg$
        image/tiff      ^tiff?$                       text/css       ^css$
        text/html       ^html?$                       text/plain     ^txt$
        text/xml        ^xml$                         video/mp4      ^(?:mp4|m4[bprv])$
        video/mpeg      ^(?:m[lp]v|mp[eg]|mpeg|vob)$  video/ogg      ^og[vx]$
        video/quicktime ^(?:mov|qt)$                  video/x-ms-wmv ^wmv$
    }
    wibble::handle $opts(-urlroot) staticfile root $docroot
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
    set ::woof::webservers::wibble::wibble_version [package require wibble]
    source [file join [file dirname [info script]] .. .. .. lib woof master.tcl]
    ::woof::webservers::wibble::main [file normalize [file join [file dirname [info script]] .. .. ..]] {*}$::argv
} else {
    package require uri
    set ::woof::webservers::wibble::wibble_version [package require wibble]
}

