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

if {[lindex $argv 0] eq "stubs"} {
    source [file join $starkit::topdir scripts woofus.tcl]
} else {
    source [file join $starkit::topdir bin httpd.tcl]
}
