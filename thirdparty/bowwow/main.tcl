# Standalone Woof! Web server
package require starkit
starkit::startup
# Set the Woof root to be the directory containing the starkit
if {![info exists ::env(WOOF_ROOT)]} {
    set ::env(WOOF_ROOT) [file normalize [file join $starkit::topdir ..]]
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

    uplevel #0  [list source [file join $starkit::topdir scripts installer.tcl]]
    distro::install $::starkit::topdir $::env(WOOF_ROOT) \
        -dirs {app config public} \
        -manifest $::installer::manifest_name \
        -updatesameversion false
    ::installer::write_defaults $::env(WOOF_ROOT)

    puts "Listening at URL $opts(-urlroot) on port $opts(-port)."
    puts "Restart with -urlroot and -port options to change these."
    puts "Running. Hit Ctrl-C to exit ..."

    uplevel #0  [list source [file join $starkit::topdir lib woof webservers wibble_server.tcl]]
    uplevel #0  [list source [file join $starkit::topdir lib woof master.tcl]]
    ::woof::webservers::wibble::main $::env(WOOF_ROOT) -port $opts(-port) -urlroot $opts(-urlroot)
}

if {[lindex $argv 0] in {controller url verify}} {
    source [file join $starkit::topdir scripts wag.tcl]
    wag::main {*}$::argv
} else {
    if {[catch {bowwow {*}$::argv} msg]} {
        puts stderr $msg
        if {[info exists ::env(WOOF_DEBUG)]} {
            puts stderr $::errorInfo
        }
    }
}
