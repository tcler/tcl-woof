# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Console based interface that executes http commands. Used for
# development and testing

set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. lib]]]

package require uri
package require uri::urn
package require ncgi

namespace eval ::woof::console {}

################################################################
# Dummy console web server interface
source [file join [file dirname [info script]] .. lib woof webservers console_server.tcl]


################################################################
# Command line loop

# Asynch command line adapted from Welch.
# Reads commands from standard input and executes them.
proc ::woof::console::start {{prompt "woof>"}} {
    variable command_line
    set command_line ""
    puts -nonewline $prompt
    flush stdout
    fileevent stdin readable [list [namespace current]::run_command $prompt]
}

# Callback from file event to execute a command
proc ::woof::console::run_command {prompt} {
    variable command_line

    if {[eof stdin]} { exit }
    
    append command_line [gets stdin]
    if {[info complete $command_line]} {
        
        if {[catch {uplevel \#0 $command_line} result]} {
            set chan stderr
        } else {
            set chan stdout
        }
        set command_line ""
        puts $chan $result
        flush $chan
        puts -nonewline $prompt
        flush stdout
    } else {
        # Command not complete
        append command_line "\n"
    }
    return
}


# Stops the command line loop
proc ::woof::console::stop {} {
    variable command_line
    set command_line ""
    fileevent stdin readable {}
}


################################################################
# Console commands
proc ::woof::console::get_env {{name ""}} {
    variable _env

    if {$name eq ""} {
        return $_env
    } else {
        return $_env($name)
    }
}

proc ::woof::console::setup_dummy_env {method url} {
    # Based on the url, set up the request environment as Apache would
    array set url_parts [::uri::split $url]
    if {$url_parts(host) eq ""} {
        set url_parts(host) localhost
    }
    
    if {$url_parts(scheme) ni {http https}} {
        error "URL scheme '$url_parts(scheme)' is not supported."
    }
    
    # Construct the URI
    set uri /$url_parts(path)
    if {$url_parts(query) ne ""} {
        append uri ?$url_parts(query)
    }
    # fragment is not always there
    if {[info exists url_parts(fragment)] &&
        $url_parts(fragment) ne ""} {
        append uri #$url_parts(fragment)
    }

    set port $url_parts(port)
    if {$port eq ""} {
        set host_and_port $url_parts(host)
        set port [expr {$url_parts(scheme) eq "https" ? 443 : 80}]
    } else {
        set host_and_port $url_parts(host):$port
    }

    # Below assumes Woof is rooted at URL /
    set dummy_env [list \
             SERVER_NAME [info hostname] \
             SERVER_PORT $port \
             SERVER_SOFTWARE "woof_console" \
             SERVER_PROTOCOL $url_parts(scheme)/1.0 \
             REQUEST_METHOD  $method \
             REMOTE_HOST localhost \
             REMOTE_ADDR 127.0.0.1 \
             REQUEST_URI $uri \
             SCRIPT_INFO / \
             PATH_INFO [string range $uri 1 end] \
            ]

    if {$url_parts(query) ne ""} {
        lappend dummy_env QUERY_STRING $url_parts(query)
    }

    # Info supposedly sent by client
    lappend dummy_env \
             HTTP_HOST $host_and_port \
             HTTP_ACCEPT */*

    return $dummy_env
}

proc ::woof::console::execute {method url} {
    variable _env;              # Will be the environ passed to woof
    variable _server_output;    # The "web server" will write to this

    array unset _env

    # Based on the url, set up the request environment as Apache would
    array set _env [setup_dummy_env method $url]

    try {
        array set saved_env [array get ::env]
        array set ::env [array get _env]; # Since ncgi uses env
        ::woof::master::process_request [namespace current]::_server_output
    } finally {
        # Restore environment
        # We cannot just unset ::env and restore from saved_env
        # because unsetting the ::env array will permanently break
        # Tcl's link between the array and the process environment
        # variables. So we have to unset one element at a time
        array set ::env [array get saved_env]
        foreach name [array names ::env] {
            if {![info exists saved_env($name)]} {
                # Name was not in original env, so delete it
                unset ::env($name)
            }
        }
    }

    return $_server_output
}

proc ::woof::console::restart {} {
    # Restart the program
    exec [info nameofexecutable] $::argv0 {*}$::argv &
    exit
}

proc ::woof::console::testpage {{action welcome} {controller woof/_manage} } {
    get http://localhost/$controller/$action
}

interp alias {} ::woof::console::get {} ::woof::console::execute GET
interp alias {} ::woof::console::head {} ::woof::console::execute HEAD
interp alias {} ::woof::console::post {} ::woof::console::execute POST
interp alias {} ::woof::console::delete {} ::woof::console::execute DELETE

namespace eval ::woof::console {
    namespace export get head post delete
    namespace export restart
    namespace export testpage
}

# Figure out where we are. The woof root is one directory above us

source [file join [file dirname [info script]] .. lib woof master.tcl]

set ::woof::console::_safe_interp [::woof::master::init console_server [file normalize [file join [file dirname [info script]] ..]]]
# For debugging, enable puts in the safe interpreter. THIS MUST NOT BE
# DONE IN A REAL WEB SERVER MODULE
interp alias $::woof::console::_safe_interp puts {} puts

namespace import ::woof::console::*

# Unlink ::env from process environment to speed it up
apply {{} {set e [array get ::env] ; unset ::env ; array set ::env $e}}

if {[llength [info commands tkcon]] == 0} {
    if {[string match *wish* [info nameofexecutable]]} {
        wm withdraw .
        console show
        console eval {focus .console}
    } else {
        woof::console::start
        vwait ::until_exit
    }
}


