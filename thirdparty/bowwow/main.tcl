# Standalone Woof! Web server
package require starkit
starkit::startup
# Set the Woof root to be the directory containing the starkit
if {![info exists ::env(WOOF_ROOT)]} {
    set ::env(WOOF_ROOT) [file normalize [file join $starkit::topdir ..]]
}

# TBD - need to replace this with code that will overwrite all _* files 
# and directories and make backups - basically share code with woofus
# If the WOOF_ROOT does not exist, create it and copy config file there
if {![file isdirectory $::env(WOOF_ROOT)]} {
    if {[file exists $::env(WOOF_ROOT)]} {
        error "WOOF_ROOT '$::env(WOOF_ROOT)' exists but is not a directory."
    }
    file mkdir $::env(WOOF_ROOT)
}
file mkdir [file join $::env(WOOF_ROOT) config]
if {![file exists [file join $::env(WOOF_ROOT) config _woof.cfg]]} {
    file copy -force -- [file join $starkit::topdir config _woof.cfg] [file join $::env(WOOF_ROOT) config _woof.cfg]
}
if {![file exists [file join $::env(WOOF_ROOT) config application.cfg]]} {
    file copy [file join $starkit::topdir config _application.cfg] [file join $::env(WOOF_ROOT) config application.cfg]
}

if {![file exists [file join $::env(WOOF_ROOT) app]]} {
    file copy [file join $starkit::topdir app] [file join $::env(WOOF_ROOT) app]
}
file copy -force [file join $starkit::topdir app controllers views _layout.wtf] \
    [file join $::env(WOOF_ROOT) app controllers views _layout.wtf]
if {![file exists [file join $::env(WOOF_ROOT) app controllers views layout.wtf]]} {
    file copy [file join $::env(WOOF_ROOT) app controllers views _layout.wtf] \
        [file join $::env(WOOF_ROOT) app controllers views layout.wtf]
}

if {![file exists [file join $::env(WOOF_ROOT) public]]} {
    file mkdir [file join $::env(WOOF_ROOT) public]

    if {![file exists [file join $::env(WOOF_ROOT) public images]]} {
        file copy [file join $starkit::topdir public images] [file join $::env(WOOF_ROOT) public images]
    }

    if {![file exists [file join $::env(WOOF_ROOT) public stylesheets]]} {
        file copy [file join $starkit::topdir public stylesheets] [file join $::env(WOOF_ROOT) public stylesheets]
    }
}

# TBD - put this in an appropriate place
namespace eval ::bowwow {
    variable version 0.4
    variable name "BowWow"
}

proc bowwow {args} {
    array set opts {
        -port 8015
        -urlroot /
    }
    while {[llength $args]} {
        set args [lassign $args opt]
        switch -exact -- $opt {
            -urlroot -
            -port {
                if {[llength $args] == 0} {
                    error "Option $opt requires a value to be specified."
                }
                set args [lassign $args opts($opt)]
            }
            default {
                error "Unknown option '$opt' specified."
            }
        }
    }

    if {[catch {expr {$opts(-port) > 0 && $opts(-port) < 65536}} valid] ||
        ! $valid} {
        error "Invalid value specified for option -port. Must be an integer between 1 and 65535."
    }

    puts "Listening at URL $opts(-urlroot) on port $opts(-port)..."

    uplevel #0  [list source [file join $starkit::topdir lib woof webservers wibble_server.tcl]]
    uplevel #0  [list source [file join $starkit::topdir lib woof master.tcl]]
    ::woof::webservers::wibble::main $::env(WOOF_ROOT) -port $opts(-port) -urlroot $opts(-urlroot)
}

if {[lindex $argv 0] eq "stubs"} {
    source [file join $starkit::topdir scripts woofus.tcl]
} else {
    if {[catch {bowwow {*}$::argv} msg]} {
        puts stderr $msg
    }
}
