# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

namespace eval wtf {}

# From the Tcl Wiki (thanks to jcw and apw)
proc wtf::substify {in {var OUT}} {
    set script ""
    set pos 0
    foreach pair [regexp -line -all -inline -indices {^%.*$} $in] {
        foreach {from to} $pair break
        set s [string range $in $pos [expr {$from-2}]]
        if {[string length $s] > 0} {
            append script "append $var \[" [list subst $s] "]\n"
        }
        append script "[string range $in [expr {$from+1}] $to]\n"
        set pos [expr {$to+2}]
    }
    set s [string range $in $pos end]
    if {[string length $s] > 0} {
        append script "append $var \[" [list subst $s] "]\n"
    }
    return $script
}

proc wtf::compile_template {in {var OUT}} {
    return [list $var [substify $in $var]]
}

proc wtf::run_compiled_template {ct} {
    uplevel 1 [lindex $ct 1]
    return [lindex $ct 0]
}

proc wtf::html_frag {content args} {

    variable name_counter;    # Set up the temp variable for this fragment

    set varname [namespace current]::frag[incr name_counter]
    upvar $varname frag
    set frag ""

    if {[llength $args]} {
        set html "<[lindex $args 0] [join [lrange $args 1 end] { }]>"
    } else {
        set html ""
    }

    set script [substify $content $varname]
    uplevel 1 $script
    append html $frag
    if {[llength $args]} {
        append html "\n</[lindex $args 0]>\n"
    }

    unset $varname
    return $html
}


proc wtf::table {data {ncols 2} args} {
    array set opts $args

    return [html_frag {
% foreach {x y} $data {
<tr><td>$x</td><td>$y</td></tr>
% }
} table]
}


namespace eval wtf {
    namespace export html_frag
}