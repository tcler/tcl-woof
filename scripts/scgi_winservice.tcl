# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Wrapper to run Woof! with an SCGI interface as a Windows service
# (c) Ashok P. Nadkarni, 2009

if {! [package vsatisfies [info tclversion] 8.6]} {
    puts stderr "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
    error "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
}

namespace eval ::woof::winsvc {
    variable usage_string "[info nameofexecutable] ?OPTIONS? run|install|uninstall"
    variable service
    set service(state) "stopped"
    set service(name) "woofscgi"
    set service(port) 9999
    set service(last_control_seq) 0; # Needed when stopping

    variable opt_defs
    set opt_defs [list \
                      [list service.arg $service(name) "Service name"] \
                      [list port.arg $service(port) "Port number"]]

    variable script [file normalize [info script]]
}


#
# Update the SCM with our state
proc ::woof::winsvc::report_state {{seq -1}} {
    variable service

    if {$seq == -1} {
        set seq $service(last_control_seq)
    }
    if {[catch {
        twapi::update_service_status $service(name) $seq $service(state)
    } msg]} {
        ::twapi::eventlog_log "Service $service(name) failed to update status: $msg"
    }
}

# Callback handler from Windows Service Control Manager
proc ::woof::winsvc::service_control_handler {control {name ""} {seq 0} args} {
    variable service

    switch -exact -- $control {
        start {
            # Setting service_state will also end the toplevel vwait
            # which will then call scgi_main
            set service(state) running
            report_state $seq
        }
        stop {
            # Note we do not report_state here.
            # Once the SCGI server stops, its main routine will
            # return at which point we will report_state
            set service(state) stopped
            set service(last_control_seq) $seq
            ::scgi::stop
        }
        continue -
        pause {
            # We cannot pause/continue the service, Report current state
            report_state $seq
        }
        default {
            # Ignore - note we must NOT call report_state
        }
    }
}

proc ::woof::winsvc::run {} {
    variable service
    variable script

    set dir [file dirname [file dirname $script]]; # Woof installation
    if {[catch {
        twapi::run_as_service [list [list $service(name) [namespace current]::service_control_handler]]
        vwait [namespace current]::service(state)
        uplevel #0 [list source [file join $dir lib woof webservers scgi_server.tcl]]
        ::scgi::main $dir -port $service(port)
        # Service stopped
        ::woof::winsvc::report_state
    } msg]} {
        twapi::eventlog_log "Service error: $msg: Stack: $::errorInfo"
    }
}

proc woof::winsvc::install {args} {
    variable service

    array set opts {startup manual}
    array set opts $args

    switch -exact -- $opts(startup) {
        manual -
        demand_start { set opts(startup) demand_start }
        auto -
        auto_start  { set opts(startup) auto_start }
        default {
            error "Invalid value $opts(startup) for -startup option"
        }
    }
    
    if {[twapi::service_exists $service(name)]} {
        puts stderr "Service $service(name) already exists"
        exit 1
    }

    # Make the names a short name to not have to deal with
    # quoting of spaces in the path
    set exe [file nativename \
                 [file attributes [info nameofexecutable] -shortname]]
    set script [file nativename \
                    [file attributes \
                         [file normalize [info script]] \
                         -shortname]]
    twapi::create_service $service(name) \
        "$exe $script -service $service(name) -port $service(port) run" \
        -account "NT Authority\\LocalService" -password "" \
        -starttype $opts(startup)
}

proc woof::winsvc::uninstall {} {
    variable service
    if {[twapi::service_exists $service(name)]} {
        # Wait up to 5 secs for it to stop
        twapi::stop_service $service(name) -wait 5000
        twapi::delete_service $service(name)
    }
}

#
# Main proc
proc ::woof::winsvc::main {} {
    variable service
    variable usage_string
    variable opt_defs

    array set opts [::cmdline::getoptions ::argv $opt_defs "Usage: $usage_string"]
    
    if {[info exists opts(service)]} {
        set service(name) $opts(service)
        unset opts(service)
    }

    if {[info exists opts(port)]} {
        set service(port) $opts(port)
        unset opts(port)
    }
    if {(![string is integer -strict $service(port)]) ||
        $service(port) < 1 || $service(port) > 65535} {
        error "Invalid SCGI port ($service(port)) specified. Must be an integer between 1 and 65535."
    }

    if {[llength $::argv]} {
        set command [lindex $::argv 0]
    } else {
        set command run
    }

    switch -exact -- $command {
        install { install {*}[array get opts]}
        uninstall { uninstall {*}[array get opts] }
        run { run {*}[array get opts] }
        default { 
            error "Unknown command: $command"
        }
    }
}

################################################################
# Script execution starts here

set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. lib]]]
::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. lib]]

if {[catch {
    package require twapi
}]} {
    # For development purposes
    ::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. thirdparty lib]]
    package require twapi
}
package require cmdline
source [file join [file dirname [info script]] .. lib woof master.tcl]
#package require woof

if {[catch {
    ::woof::winsvc::main 
} msg]} {
    # Do not know if running as a command line or service so we first log
    # to the event log, and then to the stderr
    catch {::twapi::eventlog_log $msg}
    puts stderr $msg
}
exit 0
