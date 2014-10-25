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


proc pure::paginator {range url_prefix args} {
    # Returns HTML for a Pure CSS formatted paginator
    #   range - list of one or two integers denoting the range of page numbers.
    #     If the second number is omitted, there is no upper limit.
    #   url_prefix - the prefix of the URL to use for each page. The page
    #     number is appended to this when constructing the URL for each
    #     button.
    #   -active NUMBER - the page number that is currently active
    #   -start START - First page number to show
    #   -count COUNT - Number of page buttons
    
    lassign $range lb ub
    if {$ub eq ""} {
        set ub 2000000000;      # Some large number
    }

    array set opts {
        -start 1
        -count 5
        -active -1
    }
    array set opts $args
    if {$lb > $opts(-start)} {
        set opts(-start) $lb
    }
    if {($opts(-start) + $opts(-count) - 1) > $ub} {
        set opts(-count) [expr {$ub - $opts(-start) + 1}]
    }

    set html "<ul class='pure-paginator'>\n"
    if {$lb < $opts(-start)} {
        append html "<li><a class='pure-button prev' href='${url_prefix}[expr {$opts(-start)-1}]'>&#171;</a></li>\n"
    } else {
        append html "<li><a class='pure-button prev pure-button-disabled' href='${url_prefix}$opts(-start)'>&#171;</a></li>\n"
    }

    set i $opts(-start)
    set end [expr {$opts(-start)+$opts(-count)-1}]
    while {$i <= $end} {
        if {$i == $opts(-active)} {
            append html "<li><a class='pure-button pure-button-active' href='${url_prefix}$i'>$i</a></li>\n"
        } else {
            append html "<li><a class='pure-button' href='${url_prefix}$i'>$i</a></li>\n"
        }
        incr i
    }

    if {$ub >= ($opts(-start) + $opts(-count))} {
        append html "<li><a class='pure-button next' href='${url_prefix}[expr {$opts(-start)+$opts(-count)}]'>&#187;</a></li>\n"
    } else {
        append html "<li><a class='pure-button next pure-button-disabled' href='${url_prefix}[expr {$opts(-start)+$opts(-count)-1}]'>&#187;</a></li>\n"
    }

    append html "</ul>"
    return $html
}
