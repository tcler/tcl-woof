# Copyright (c) 2014, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

# Commands in this file will be defined relative to whatever namespace
# they are sourced in.

namespace eval pure {
    namespace path [namespace parent]
}

proc pure::button {text args} {
    # Returns the HTML for a button
    #  text - text to display in the button. 
    #    This is HTML-escaped before display.
    #  -classes CSSCLASSES - additional CSS classes to style the button.
    #  -enabled BOOLEAN - controls whether button is enabled (default) or not
    #  -pressed BOOLEAN - controls whether button is shown as pressed or not.
    #                     Default is 0.
    #  -primary BOOLEAN - style as a primary button (default false)
    #  -url - URL to link to
    #
    # Constructs and returns the HTML fragment for displaying a Pure CSS button.
    #
    
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
