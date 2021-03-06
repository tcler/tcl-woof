# Pure CSS interface module
#
# Copyright (c) 2014, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

# TBD - add raw/noescape support for all commands
# TBD - add text/p capability to forms.

# Commands in this file will be defined relative to whatever namespace
# they are sourced in.

namespace eval pure {
    namespace path [namespace parent]
}

proc pure::button {text args} {
    # Returns the HTML for a Pure CSS styled button
    # text - text to display in the button. 
    #    This is HTML-escaped before display.
    # -classes CSSCLASSES - additional CSS classes to style the button.
    # -enabled BOOLEAN - controls whether button is enabled (default) or not
    # -onclick JAVASCRIPT - Javascript to execute when the button is clicked
    # -pressed BOOLEAN - controls whether button is shown as pressed or not.
    #                     Default is 0.
    # -primary BOOLEAN - style as a primary button (default false)
    # -type button|submit|reset - specifies the type of the button.
    # -url - URL to link to
    #

    
    # TBD - what should the -type default be?
    array set opts {
        -classes {}
        -enabled 1
        -pressed 0
        -primary 0
        -type button
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
        if {[info exists opts(-onclick)]} {
            # TBD - does the Javascript need to be escaped?
            return "<button type='$opts(-type)' class='$classes' onClick='$opts(-onclick)'>$text</button>"
        } else {
            return "<button type='$opts(-type)' class='$classes'>$text</button>"
        }
    }
}

proc pure::menu {menudefs args} {
    # Returns the HTML for a Pure CSS styled menu
    #  menudefs - list of menu definitions
    #  -classes CLASSES - list of additional CSS classes to add to the menu
    #  -orient DIRECTION - specifies orientation of the menu. By default,
    #   it is displayed horizontally. See below for possible other values.
    #  -heading TEXT - text to display as the heading for the menu
    #  -state open|closed - specifies whether to display the menu as
    #     open (default) or closed
    
    set orient [woof::util::dict_pop args -orient horizontal]

    #ruff
    # The orientation of the menu is controlled through '-orient' option.
    # The values 'horizontal' (default) and 'vertical' display the menu in
    # the corresponding direction. The values 'sm', 'md', 'lg' and 'xl'
    # are intended to be used in responsive web pages. They correspond
    # to the small, medium, large and extra-large screen widths as
    # defined by Pure CSS. Specifying one of these values will result
    # in a menu that displays vertically at the specified screen width
    # and above while displaying horizontally at smaller screen widths.
    # For example, '-orient md' will result in a menu that displays
    # vertically at widths of medium and above, and horizontally at
    # smaller widths.

    switch -exact -- $orient {
        sm - md - lg - xl {
            # Recurse to generate two menu defs - one vertical and one
            # horizontal - wrapped by a screen size class
            set classes [woof::util::dict_pop args -classes {}]
            set html [menu $menudefs {*}$args -orient vertical -classes [linsert $classes 0 wf-r-$orient]]
            append html \n [menu $menudefs {*}$args -orient horizontal -classes [linsert $classes 0 wf-r-${orient}-]]
            return $html
        }
        default {
            # Will error out for bad values
            set classes [dict get {
                vertical "pure-menu"
                horizontal "pure-menu pure-menu-horizontal"
            } $orient]
        }
    }
    

    if {![dict exists $args -state] || [dict get $args -state] eq "open"} {
        append classes " pure-menu-open"
    }

    set html "<div class='$classes"

    if {[dict exists $args -classes]} {
        append classes " [join [dict get $args -classes]]"
    }

    set html "<div class='$classes'>"

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
    # Unknown attributes values are ignored.
    #
    # If the target URL is empty, the menu item is shown disabled.
    append html "<ul>"
    foreach def $menudefs {
        if {[llength $def] == 0} {
            append html "<li class='pure-menu-separator'></li>"
            continue
        }
        set url [lindex $def 1]
        set cssclasses {}
        set attrs [lrange $def 2 end]
        if {"selected" in $attrs} {
            lappend cssclasses "pure-menu-selected"
        }
        if {$url eq ""} {
            lappend cssclasses "pure-menu-disabled"
            # Disabled entries should even have a href attribute. An empty
            # href will take to top of page
            set href ""
        } else {
            set href " href='$url'"
        }
        if {[llength $cssclasses]} {
            append html "<li class='[join $cssclasses]'>"
        } else {
            append html "<li>"
        }
        append html "<a$href>[util::hesc [lindex $def 0]]</a></li>"
    }

    return "${html}</ul></div>"
}

proc pure::table {data args} {
    # Returns the HTML for a Pure CSS styled table
    #
    #  data - list of sublists with each sublist corresponding to a table row
    #  -borders vertical|horizontal|both - specifies which cell borders are
    #     drawn. By default only the vertical borders are drawn.
    #  -heading HEADER - specifies the table heading.
    #  -stripes BOOLEAN - if true, alternate table rows are shaded. Default
    #     is false.
    #  -raw BOOLEAN - if true, heading and cell contents are not HTML-escaped.
    #     Default is false.

    set raw [woof::util::dict_get $args -raw 0]
    set stripes [woof::util::dict_get $args -stripes 0]
    set borders [woof::util::dict_get $args -borders vertical]
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
            if {! $raw} {
                set cell [util::hesc $cell]
            }
            append html "<th>$cell</th>"
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
                if {! $raw} {
                    set cell [util::hesc $cell]
                }
                append html "<td>$cell</td>"
            }
            append html "</tr>\n"
            incr i
        }
    } else {
        foreach row $data {
            append html "<tr>"
            foreach cell $row {
                if {! $raw} {
                    set cell [util::hesc $cell]
                }
                append html "<td>$cell</td>"
            }
            append html "</tr>\n"
        }
    }

    append html </table>
    return $html
}


proc pure::paginator {range url_prefix args} {
    # Returns HTML for a Pure CSS formatted paginator
    #
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
    if {$lb < $opts(-active)} {
        append html "<li><a class='pure-button prev' href='${url_prefix}[expr {$opts(-active)-1}]'>&#171;</a></li>\n"
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

    if {$ub > $opts(-active)} {
        if {$opts(-active) < $opts(-start) || $opts(-active) >= $end} {
            append html "<li><a class='pure-button next' href='${url_prefix}[expr {$opts(-start)+$opts(-count)}]'>&#187;</a></li>\n"
        } else {
            append html "<li><a class='pure-button next' href='${url_prefix}[expr {$opts(-active)+1}]'>&#187;</a></li>\n"
        }
    } else {
        append html "<li><a class='pure-button next pure-button-disabled' href='${url_prefix}[expr {$opts(-start)+$opts(-count)-1}]'>&#187;</a></li>\n"
    }

    append html "</ul>"
    return $html
}

proc pure::img {url {alt "Image"}} {
    # Returns a Pure CSS styled image.
    # url - URL for the image
    #
    # Pure CSS styles images are automatically adjusted for the width
    # of the containing section.
    return "<img src='$url' class='pure-img' alt='$alt'>"
}

proc pure::form {formdef args} {
    # Returns a PureCSS styled form
    #
    #  formdef - form definition list as described below
    #  -layout inline|stacked|aligned - Specifies the form layout which may
    #     be aligned (labels next to entry fields), stacked
    #     (labels above entry fields) or inline
    #     (all fields on the same line, default)
    #  -title TEXT - a legend to use for the form
    #
    # The form definition is specified as a list of pairs with the first
    # element of the pair specifying the form element type, such as button,
    # and the second its definition. These form element types are described
    # below.
    # 
    # The 'fieldset' form element corresponds to a HTML <fieldset> tag.
    # The second element of the pair is itself a form definition using
    # the same format described here.
    #
    # The 'fieldgroup' form element is like fieldset except that the
    # contained controls are visually grouped together with no padding.
    #
    # The 'buttons' form element creates one or more buttons groups.
    # The second element of the pair is a list each element of which
    # is a list of arguments to pass to the [pure::button] command.
    #
    #
    # The 'button' form element creates a single button. The second
    # element of the pair is the list of arguments to pass to the 
    # [pure::button] command.
    #
    # The 'input' form element creates a label and an associated text
    # entry field.
    # The second element of the pair is a dictionary with the following keys
    # and corresponding values. Keys that are optional are indicated as such.
    #   -checked - a boolean value (optiona, default 0) that marks
    #      a checkbox or radio button in a group as selected
    #   -enabled - a boolean value (optional, default 1) that marks
    #      the field as enabled or not
    #   -id - Specifies the id attribute of the input field (optional)
    #   -label - the text to use for the text entry label (optional)
    #   -name - the name of the text entry field for the form
    #   -placeholder - Directly translates to the placeholder attribute
    #      in the generated HTML (optional)
    #   -readonly - a boolean value (optional, default 0) that specifies
    #      that the entry cannot be edited
    #   -required - a boolean value (optional, default 0) that specifies
    #      whether the form submission requires the field to be filled
    #   -rounded - a boolean value (optional, default 0) that specifies
    #      that the input field borders be rounded
    #   -type - Specifies the type of the input field. Directly passed
    #      through as the type attribute in the generated HTML.
    #   -value - Initial value to display for the field (optional)

    set need_control_group 0

    set html "<form class='pure-form"
    if {[dict exists $args -layout]} {
        switch -exact -- [dict get $args -layout] {
            stacked { append html " pure-form-stacked" }
            aligned {
                append html " pure-form-aligned"
                set need_control_group 1
            }
        }
    }
    append html "'>\n"

    if {[dict exists $args -title]} {
        append html "<legend>[util::hesc [dict get $args -title]]</legend>"
    }

    foreach {elem def} $formdef {
        append html [_parse_formdef $elem $def $need_control_group]
    }
    
    append html "</form>"
    return $html
}

proc pure::_parse_formdef {form_elem def need_control_group} {
    switch -exact -- $form_elem {
        fieldgroup -
        fieldset {
            set html "<fieldset"
            if {$form_elem eq "fieldgroup"} {
                append html " class='pure-group'"
            }
            append html ">\n"
            foreach {elem field_def} $def {
                append html [_parse_formdef $elem $field_def $need_control_group]
            }
            append html "</fieldset>\n"
            return $html
        }
        buttons {
            set html "<fieldset class='pure-controls'>\n"
            # Note whitespace separator between buttons required so
            # they do not abut each other
            set sep ""
            foreach elem $def {
                append html $sep "[button {*}$elem]"
                set sep \n
            }
            append html "</fieldset>"
        }
        input {
            set html ""
            if {[dict exists $def -type]} {
                set input_type [dict get $def -type]
            } else {
                set input_type ""
            }
            
            if {$need_control_group} {
                if {$input_type in {checkbox radio}} {
                    append html "<div class='pure-controls'>"
                } else {
                    append html "<div class='pure-control-group'>"
                }
            }
            if {[dict exists $def -label]} {
                if {$input_type in {checkbox radio}} {
                    append html "<label class='pure-$input_type'>"
                } else {
                    append html "<label>"
                }
                # For checkboxes and radio, labels will come after control
                if {$input_type ni {checkbox radio}} {
                    append html "[util::hesc [dict get $def -label]]</label>\n"
                }
            }
            append html "<input"
            # -name must exist else error
            append html " name='[util::hesc [dict get $def -name]]'"
            if {[dict exists $def -value]} {
                append html " value='[util::hesc [dict get $def -value]]'"
            }
            if {[dict exists $def -rounded]} {
                append html " class='pure-input-rounded'"
            }
            foreach {opt attr} {
                -id id -placeholder placeholder -type type
            } {
                if {[dict exists $def $opt]} {
                    append html " $attr='[util::hesc [dict get $def $opt]]'"
                }
            }
            if {[dict exists $def -readonly] && [dict get $def -readonly]} {
                append html " readonly"
            }
            if {[dict exists $def -enabled] && ![dict get $def -enabled]} {
                append html " disabled"
            }
            if {[dict exists $def -required] && [dict get $def -required]} {
                append html " required"
            }
            if {[dict exists $def -checked] && [dict get $def -checked]} {
                append html " checked"
            }
            append html ">\n"
            if {[dict exists $def -label]} {
                # For checkboxes and radio, labels will come after control
                if {$input_type in {checkbox radio}} {
                    append html "[util::hesc [dict get $def -label]]\n"
                    append html "</label>\n"
                }
            }

            if {$need_control_group} {
                append html "</div>"
            }
            return $html
        }
    }
}
