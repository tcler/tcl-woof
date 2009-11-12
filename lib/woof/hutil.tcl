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
    # linkdefs - a tree of link definitions.
    # selection - the selected link, if any, from $linkdefs
    # -hrefcmd COMMANDPREFIX - if specified, COMMANDPREFIX is executed
    #  with an argument specifying the link reference and should return
    #  the URL to use for the link.
    # $linkdefs is a flat list of triples, the first element in each
    # triple being the link reference, the second being the raw HTML text to
    # be displayed, and the third being a nested list of children in the
    # same format.
    #
    # The returned HTML is not styled in any fashion. It is up to the
    # caller to appropriately use stylesheets for layout
    # and appearance.

    set items [_flatten_navigation $linkdefs]

    # Locate the selection
    set selection_path {}
    foreach item $items { 
        # First element in $item is the path to the link. The selection
        # is matched against the last item in the path.
        if {[lindex [lindex $item 0] end] eq $selection} {
            # Matched. As an aside, note we assume each link appears
            # only once or if not, then the first match is to be used.
            set selection_path [lindex $item 0]
            break
        }
    }

    # Now generate the list
    set html ""

    set current_level 0
    foreach item $items {
        set include false;         # Whether to display this
        set path [lindex $item 0]; # Hierarchical path to this item

        #ruff
        # The returned HTML is a hierarchical unnumbered list. Each item
        # is an HTML link except for the one corresponding to $selection.
        # An item from $linkdefs is included if it matches one of the
        # following criteria:
        #  - it is a top level item
        #  - it is the selected item, 
        #  - it is an ancestor of the selected item
        #  - it is a child (not any descendent) of the selected item
        #  - it is a sibling of the selected item

        # Each test below matches the above criteria in order
        if {([llength $path] == 1) ||
            ($path eq $selection_path) ||
            [string match "${path}*" [lrange $selection_path 0 end-1]] ||
            [string equal [lrange $path 0 end-1] $selection_path] ||
            [string equal [lrange $path 0 end-1] [lrange $selection_path 0 end-1]]} {
            # Should display this item. Figure out if we need
            # to either nest or remove nesting
            set new_level [llength $path]
            if {$new_level > $current_level} {
                append html [string repeat <ul> [expr {$new_level-$current_level}]]
            } elseif {$new_level < $current_level} {
                append html [string repeat </ul> [expr {$current_level-$new_level}]]
            }
            set current_level $new_level

            # Now display. If not the selected item, display as link
            if {$path eq $selection_path} {
                append html "<li>[lindex $item 1]</li>"
            } else {
                if {[dict exists $args -hrefcmd]} {
                    append html "<li><a href='[{*}[dict get $args -hrefcmd] [lindex $path end]]'>[lindex $item 1]</a></li>"
                } else {
                    append html "<li><a href='[lindex $path end]'>[lindex $item 1]</a></li>"
                }
            }
        }
    }

    append html [string repeat "</ul>" $current_level]
}