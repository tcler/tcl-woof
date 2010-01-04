# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
namespace eval util {}

proc util::make_navigation_links {linkdefs selection args} {
    # Generates HTML for a list based navigation tree
    # linkdefs - a list of link definitions.
    # selection - the selected link, if any, from $linkdefs
    # -hrefcmd COMMANDPREFIX - if specified, COMMANDPREFIX is executed
    #  with an argument specifying the link reference and should return
    #  the URL to use for the link.
    # $linkdefs is a list of triples, the first element in each
    # triple being the link reference, the second being the raw HTML text to
    # be displayed, and the optional third element being the nesting level.
    # The link references are assumed to be unique.

    # Locate the selection
    # Calculate the "path" to the selected item. We basically
    # need this to figure out what the siblings are.
    set sel_path ""
    set index [lsearch -index 0 $linkdefs $selection]
    if {$index >= 0} {
        set sel_path [list [lindex $linkdefs $index 0]]
        set sel_level [lindex $linkdefs $index 2]
        if {$sel_level == ""} {
            set sel_level 0
        }
        set current_level $sel_level
        while {[incr index -1] >= 0 && $current_level > 0} {
            set level [lindex $linkdefs $index 2]
            if {$level eq ""} {
                set level 0
            }
            if {$level < $current_level} {
                lappend sel_path [lindex $linkdefs $index 0]
                set current_level $level
            }
        }
    }
        
    set sel_path [lreverse $sel_path]
    set sel_top [lindex $sel_path 0]

    # Now generate the list
    set html "<ul>"
    set current_level 0
    set path {}
    foreach def $linkdefs {
        set include false;         # Whether to display this

        lassign $def href label new_level
        if {$new_level eq ""} {
            set new_level 0
        }

        set path [lrange $path 0 [expr {$new_level-1}]]
        lappend path $href ; # Hierarchical path to this item

        #ruff
        # The returned HTML is a hierarchical unnumbered list. Each item
        # is an HTML link except for the one corresponding to $selection.
        # An item from $linkdefs is included if it matches one of the
        # following criteria:
        #  - it is a top level item
        #  - it is the selected item itself or an ancestor
        #  - it shares part of the selected items ancestral path. Intuitively,
        #    this means the item can be reached from the selection by
        #    going upward and sideways without any downward steps.
        #  - it is a child (not any descendent) of the selected item
        #  - it is a sibling of the selected item

        # Each test below matches the above criteria in order

        # Special case test for common case for speedup - if the top
        # of this path is not same as selection, item does not match except
        # that all toplevel items are included.
        if {$new_level != 0 && [lindex $path 0] ne $sel_top} {
            continue
        }
        
        # At this point, this item is definitely under the same toplevel item
        # as the selected item.

        # Because hrefs are unique, the criteria above can be boiled down
        # to the following:
        # - it is a top level item.
        # - its at a higher or same level than selection AND shares ancestors
        #   (also covers the selection itself, its ancestors)
        # - it is a child of selection
        set parent [lindex $path end-1]
        if {$new_level == 0 ||
            $parent in $sel_path } {

            # Should display this item. Figure out if we need
            # to either nest or remove nesting
            if {$new_level > $current_level} {
                append html [string repeat <ul> [expr {$new_level-$current_level}]]
            } elseif {$new_level < $current_level} {
                append html [string repeat </ul> [expr {$current_level-$new_level}]]
            }
            set current_level $new_level

            #ruff
            # The returned HTML is not styled in any fashion. It is up to the
            # caller to appropriately use stylesheets for layout
            # and appearance.

            # Now display. If not the selected item, display as link
            if {$href eq $selection} {
                append html "<li>$label</li>"
            } else {
                if {[dict exists $args -hrefcmd]} {
                    append html "<li><a href='[{*}[dict get $args -hrefcmd] $href]'>$label</a></li>"
                } else {
                    append html "<li><a href='$href'>$label</a></li>"
                }
            }
        }
    }

    append html [string repeat "</ul>" [incr current_level]]
    return $html
}

proc util::make_query_string {args} {
    # Constructs a URL query string from the given arguments
    # args - list of alternating keys and values. If a single argument
    #  is given, it is itself treated as such a list
    # If no arguments are specified, returns an empty string, otherwise
    # returns a query string prefixed with ? and suitably escaped for
    # inclusion into a URL.
    if {[llength $args] == 1} {
        set args [lindex $args 0]
    }
    if {[llength $args] == 0} {
        return ""
    }
    set query {}
    foreach {k val} $args {
        # We encode k and val separately. Else "=" might
        # will get encoded
        lappend query "[::util::url_encode $k]=[::util::url_encode $val]"
    }

    return ?[join $query &]
}

proc util::make_relative_url {base target} {
    # Construct a URL path relative to a base URL
    # base - the base URL
    # target - the URL for which a path relative to $base is to be constructed

    set base [split $base /]

    if {[llength $base] == 0} {
        return $target
    }

    set base [lrange $base 0 end-1]; # Relative is always w.r.t parent of base
    set target [split $target /]
    set i 0
    foreach bpart $base tpart $target {
        if {$bpart ne $tpart} {
            break
        }
        incr i
    }

    # First $i components are common. See what's left over
    if {$i < [llength $base]} {
        set rurl [lrepeat [expr {[llength $base]-$i} ] ..]
    } else {
        # Base is all used up.
        set rurl {}
    }

    if {$i < [llength $target]} {
        set target [lrange $target $i end]
    } else {
        # Target is also used up. Special case - pick off last
        # element of target
        #lappend rurl ..
        #set target [lrange $target end end]
        #set target [list ..]
        set target {}
        if {[llength $rurl] == 0} {
            set rurl [list .]
        }
    }

    return [file join {*}$rurl {*}$target]
}
