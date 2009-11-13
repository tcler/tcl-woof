# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
namespace eval hutil {}

proc hutil::_flatten_navigation {linkdefs {ancestors {}}} {
    # Given a tree of link definitions as accepted by make_navigation_links
    # returns a flattened list of link definitions where the first element
    # of each is a list containing the path to that item.
    set flat {}
    foreach linkdef $linkdefs {
        lassign $linkdef link label children
        set linkpath [concat $ancestors [list $link]]
        lappend flat [list  $linkpath $label]
        if {[llength $children]} {
            lappend flat {*}[_flatten_navigation $children $linkpath]
        }
    }
    return $flat
}

proc hutil::make_navigation_links {linkdefs selection args} {
    # Generates HTML for a list based navigation tree
    # linkdefs - a list of link definitions.
    # selection - the selected link, if any, from $linkdefs
    # -hrefcmd COMMANDPREFIX - if specified, COMMANDPREFIX is executed
    #  with an argument specifying the link reference and should return
    #  the URL to use for the link.
    # $linkdefs is a list of triples, the first element in each
    # triple being the link reference, the second being the raw HTML text to
    # be displayed, and the optional third element being the nesting level.
    #

    # Locate the selection
    # Calculate the "path" to the selected item. We basically
    # need this to figure out what the siblings are.
    set sel_path ""
    set index [lsearch -index 0 $linkdefs $selection]
    if {$index >= 0} {
        set sel_path [list [lindex $linkdefs $index 0]]
        set current_level [lindex $linkdefs $index 2]
        if {$current_level == ""} {
            set current_level 0
        }
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
    set sel_toplevel [lindex $sel_path 0]
    set sel_parent [lindex $sel_path end-1]

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
        #  - it is a child (not any descendent) of the selected item
        #  - it is a sibling of the selected item

        # Each test below matches the above criteria in order

        # Special case test for common case for speedup - if the toplevel
        # of this path is not same as selection, item does not match except
        # that all toplevel items are included.
        if {$new_level != 0 && [lindex $path 0] ne $sel_toplevel} {
            continue
        }
        
        if {$new_level == 0 ||
            $href in $sel_path ||
            [lindex $path end-1] eq $selection  ||
            [lindex $path end-1] eq $sel_parent
        } {
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