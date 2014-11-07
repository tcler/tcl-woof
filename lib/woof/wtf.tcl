# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

namespace eval wtf {}

# From the Tcl Wiki (thanks to jcw and apw)
proc wtf::substify {in {var OUT}} {
    set script ""
    set pos 0
    set in_percent_plus false
    foreach pair [regexp -line -all -inline -indices {^%.*$} $in] {
        # $from and $to contain the indices of string between % marker and
        # the end of its line.
        # $pos is the position of the character after the last % marker line
        # if not inside a command block, and the character after the %(
        # marker if inside a command block.
        lassign $pair from to
        if {$in_percent_plus} {
            # If we are inside a %(, then every line implicitly starts
            # with a %. No line should start with a % unless it is a %)
            if {[string index $in [expr {$from+1}]] ne ")"} {
                error "'%' command line not allowed inside %( %) block"
            }
            # Command block terminated with %)
            # $from is the % char, so $from-1 will include the newline
            # as we wish
            append script "[string range $in $pos [expr {$from-1}]]"
            set in_percent_plus false
            set pos [expr {$to+2}]
        } else {
            # We are not inside a command block.
            # Collect the string to be substited since last marker line
            set s [string range $in $pos [expr {$from-2}]]
            if {[string length $s] > 0} {
                append script "append $var \[" [list subst $s] "]\n"
            }
            # See if this is the beginning of a command block
            if {[string index $in [expr {$from+1}]] eq "("} {
                # Start of a command block
                # Command will be added at the end of the block. Just
                # mark its starting position
                set pos [expr {$from+2}]; # Char after the %(
                set in_percent_plus true
            } else {
                # Single command line
                append script "[string range $in [expr {$from+1}] $to]\n"
                # $to points to last char of line before %. Add two - one
                # to skip the char and then one more to skip newline after it
                set pos [expr {$to+2}]
            }
        }
    }
    set s [string range $in $pos end]
    if {[string length $s] > 0} {
        # There is a fragment left.
        if {$in_percent_plus} {
            # It is a command fragment
            append script $s
        } else {
            # It is substituable fragment
            append script "append $var \[" [list subst $s] "]\n"
        }
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

proc wtf::compile {in} {
    variable _wtf_output_ctr
    set var [namespace current]::_wtf_output_[incr _wtf_output_ctr]
    return [list $var [substify $in $var]]
}

proc wtf::render {ct} {
    # The first element is the name of the variable that will contain
    # generated output. Second element is the string to execute in caller's
    # context. The variable might have been used before so empty it
    # first.
    set var [lindex $ct 0]
    set $var "";                 # Just to be sure
    uplevel 1 [lindex $ct 1]

    # Return the output at the same time resetting to "" so memory
    # gets freed when request ends
    return [set $var][set $var ""]
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
    namespace export html_frag compile render

    namespace ensemble create
}
