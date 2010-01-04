# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Ruff! In A Nutshell
# Generate Woof! documentation

set woof_root [file normalize [file join [file dirname [info script]] ..]]
set auto_path [linsert $auto_path 0 [file join $woof_root lib]]

set woof_ver [package require woof]
if {0} {
    # Commented out because not sure we want to document the master interp yet
    source [file join $woof_root lib woof master.tcl]
}
package require ruff

if {[llength $argv] == 0} {
    puts stderr "Usage:\t[info nameofexecutable] $argv0 OUTPUTFILENAME"
    exit 1
}


::ruff::document_namespaces html ::woof \
    -recurse true \
    -output [lindex $argv 0] \
    -titledesc "Woof! - Web Oriented Object Framework (V$woof_ver)" \
    -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
    -includesource false \
    -preamble [dict create :: {
        Introduction {
            paragraph {
                This is the reference documentation for Woof!,
                an open-source, platform and server-independent web
                application framework. For introductory material
                and a user guide, see the Woof! home page at
                http://woof.magicsplat.com.
            }
        }
    }]
