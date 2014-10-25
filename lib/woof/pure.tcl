# Copyright (c) 2014, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

# Commands in this file will be defined relative to whatever namespace
# they are sourced in.

namespace eval pure {
    namespace path [namespace parent]
}

proc pure::button {text args} {
    # Returns the HTML for a Pure CSS styled button
    #  text - text to display in the button. 
    #    This is HTML-escaped before display.
    #  -classes CSSCLASSES - additional CSS classes to style the button.
    #  -enabled BOOLEAN - controls whether button is enabled (default) or not
    #  -pressed BOOLEAN - controls whether button is shown as pressed or not.
    #                     Default is 0.
    #  -primary BOOLEAN - style as a primary button (default false)
    #  -url - URL to link to
    
    array set opts {
        -classes {}
        -enabled 1
        -pressed 0
        -primary 0
    }
        
    array set opts $args

    set classes [list pure-button]
    if {! $opts(-enabled)} {
        lappend classes pure-button-disabled
    }
    if {$opts(-pressed)} {
        lappend classes pure-button-active
    }
    if {$opts(-primary)} {
        lappend classes pure-button-primary
    }
    lappend classes {*}$opts(-classes)

    set text [util::hesc $text]
    if {[info exists opts(-url)]} {
        return "<a href='$opts(-url)' class='$classes'>$text</a>"
    } else {
        return "<button class='$classes'>$text</button>"
    }
}

proc pure::menu {menudefs args} {
    # Returns the HTML for a Pure CSS styled menu
    #  menudefs - list of menu definitions
    #  -direction horizontal|vertical - specifies whether the menu is 
    #   displayed horizontally (default) or vertically
    #  -heading TEXT - text to display as the heading for the menu
    #  -state open|closed - specifies whether to display the menu as
    #     open (default) or closed
    
    set html "<div class='pure-menu"

    if {![dict exists $args -state] || [dict get $args -state] eq "open"} {
        append html " pure-menu-open"
    }

    if {![dict exists $args -direction] || [dict get $args -direction] eq "horizontal"} {
        append html " pure-menu-horizontal"
    }

    append html "'>"

    if {[dict exists $args -heading]} {
        append html "<a class='pure-menu-heading'>[util::hesc [dict get $args -heading]]</a>"
    }

    #ruff
    # $menudefs should be a list with each element defining one item
    # in the menu. Each element is a sublist consisting of the text
    # to display, the target URL for the item and zero or more
    # attributes for the menu item.
    # Currently defined attributes are 
    #  selected - the menu item is shown selected
    #  disabled - the menu item is shown disabled
    # Unknown attributes values are ignored.
    append html "<ul>"
    foreach def $menudefs {
        if {[llength $def] == 0} {
            append html "<li class='pure-menu-separator'></li>"
            continue
        }
        set cssclasses {}
        set attrs [lrange $def 2 end]
        if {"selected" in $attrs} {
            lappend cssclasses "pure-menu-selected"
        }
        if {"disabled" in $attrs} {
            lappend cssclasses "pure-menu-disabled"
        }
        if {[llength $cssclasses]} {
            append html "<li class='[join $cssclasses]'>"
        } else {
            append html "<li>"
        }
        append html "<a href='[lindex $def 1]'>[util::hesc [lindex $def 0]]</a></li>"
    }

    return "${html}</ul></div>"
    


}

proc pure::table {data args} {
    # Returns the HTML for a Pure CSS styled table
    #  data - list of sublists with each sublist corresponding to a table row
    #  -borders vertical|horizontal|both - specifies which cell borders are
    #     drawn. By default only the vertical borders are drawn.
    #  -heading HEADER - specifies the table heading.
    #  -stripes BOOLEAN - if true, alternate table rows are shaded. Default
    #     is false.

    set borders vertical
    if {[dict exists $args -borders]} {
        set borders [dict get $args -borders]
    }

    set stripes 0
    if {[dict exists $args -stripes]} {
        set stripes [dict get $args -stripes]
    }

    switch -exact -- $borders {
        horizontal {
            set html "<table class='pure-table pure-table-horizontal'>"
        }
        both {
            set html "<table class='pure-table pure-table-bordered'>"
        }
        default {
            set html "<table class='pure-table'>"
        }
    }
    
    
    if {[dict exists $args -heading]} {
        append html "<thead><tr>"
        foreach cell [dict get $args -heading] {
            append html "<th>[util::hesc $cell]</th>"
        }
        append html "</tr></thead>\n"
    }

    if {$stripes} {
        # Longer way because pure-table-striped does not work with IE7/8
        set i 0
        foreach row $data {
            if {$i & 1} {
                append html "<tr class='pure-table-odd'>"
            } else {
                append html "<tr>"
            }
            foreach cell $row {
                append html "<td>[util::hesc $cell]</td>"
            }
            append html "</tr>\n"
            incr i
        }
    } else {
        foreach row $data {
            append html "<tr>"
            foreach cell $row {
                append html "<td>[util::hesc $cell]</td>"
            }
            append html "</tr>\n"
        }
    }

    append html </table>
    return $html
}
