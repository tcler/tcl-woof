if {![package vsatisfies [package provide Tcl] 8.6]} {return}
if {[llength [info commands ::woof::version]] == 0} {
    source [file join [file dirname [info script]] woofversion.tcl]
}
package ifneeded woof [::woof::version]  [list source [file join $dir woof.tcl]]
