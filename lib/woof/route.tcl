# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
namespace eval route {
    variable routes
    set routes {}
}

proc route::add_route_alias {route} {
    variable routes
    lappend routes $route
    return
}


proc route::clear {} {
    variable routes
    set routes {}
}

proc route::read_routes {rpath} {
    # Reads a file containing route definitions.
    # rpath - path to the file
    # Reads the content of the specified file and parses it using
    # parse_routes. The parsed routes are appended to existing routes
    # for mapping URL's.
    #
    # See parse_routes for format of the routing definitions.

    set fd [open $rpath r]
    # TBD - fconfigure encoding ?
    try {
        parse_routes [read $fd]
    } finally {
        close $fd
    }
    return
}

proc route::parse_routes {route_definitions args} {
    # Parses the specified routes file
    # route_definitions - string containing route definitions
    # The string is evaluated as a Tcl script in a safe interpreter.
    # It may include any Tcl code and in addition the following
    # commands that set up the dispatch routes.
    #
    #   curl CURL ACTIONS PURL
    # The command curl defines a controller route.
    # CURL - controller URL path (relative URL)
    # ACTIONS - list of actions included in this definition
    # PURL - URL for parameter definitions
    # The command creates a definition mapping a (relative) URL to
    # a controller.
    #
    # CURL specifies the URL for the controller and may include a module path.
    # The last component of CURL is the controller name and any prior
    # components specify the module
    #
    # ACTIONS specifies the action methods for which the definition is
    # applicable. This may be a list of action names or an empty list which
    # indicates the definition applies to all actions.
    # 
    # PURL is a URL path that defines additional parameters that be
    # supplied in the rest of the URL. Note these are not the explicit
    # parameters sent as part of a query or form post but rather additional
    # parameters that may be merged with them. Each component in this
    # PURL should have the format
    #    PARAMNAME:REGEXP:DEFAULT
    # where PARAMNAME specifies the name of the parameter, REGEXP, if not
    # empty, specifies a regular expression that the URL component should
    # match, and DEFAULT is the default value to be used if the URL 
    # component is missing. DEFAULT is actually passed through the
    # Tcl subst command with -nocommands options hence variable
    # definitions and backslash sequences can be used.
    #
    # In addition, the last path component in PURL may be of the form
    #     *PARAMNAME:REGEXP
    # in which case the corresponding parameter is a list of all remaining URL
    # component values
    #
    # Note that the ':' character in the default value should be
    # encoded using \u Tcl escape sequences else it will be treated
    # as the start of the default value as opposed to be embedded in
    # it.
    #

    # Create a safe interpreter to protect against arbitrary (malicious)
    # input in config files (although here we do not care since we
    # trust whoever wrote the routes!)
    # Creating/destroying safe interpreters is
    # cheap enough so we recreate on every call. Keeping it around would
    # require state from previous invocation to be cleaned up which is
    # a pain.

    if {[dict exists $args -clear] && [dict get $args -clear]} {
        clear
    }

    set cinterp [interp create -safe]

    # Define the command to execute the curl routing DSL command
    $cinterp alias add_route [namespace current]::add_route_alias
    $cinterp eval {
        proc curl {curl actions purl} {
            # TBD - check whether it would be faster to build a lambda expression
            # to evaluate at matching time instead of just storing the data

            # Parse the parameter expression into list form. The regexp itself
            # may have the ":" character so look for the last ":" character
            # to split the fields.
            set params {}
            foreach param [split $purl /] {
                set first [string first : $param]
                if {$first < 0} {
                    # No regexp and no default, whole string is parameter name
                    lappend params [list $param]
                    continue
                }
                set name [string range $param 0 ${first}-1]
                
                set last [string last : $param]
                if {$first == $last} {
                    # Only one : so no default value specified
                    lappend params [list $name [string range $param ${first}+1 end]]
                } else {
                    lappend params [list $name \
                                        [string range $param ${first}+1 ${last}-1] \
                                        [subst -nocommands [string range $param ${last}+1 end]]]
                }
            }
            
            add_route [list $curl $actions $params]            
        }
    }


    if {[catch {
        $cinterp eval $route_definitions
    } msg]} {
        interp delete $cinterp
        error $msg
    }

    interp delete $cinterp
}


proc route::select {rurl args} {
    # Matches the specified URL against the list of route definitions
    # rurl - relative URL, without query or fragment components
    # -defaultaction ACTION - action name if none specified in URL (default
    #   is 'index')
    # It is expected that $rurl is in normalized and decoded form.
    variable routes

    set opts [dict merge {-defaultaction index} $args]
    
    foreach r $routes {
        if {[string compare -length [string length [lindex $r 0]] [lindex $r 0] $rurl]} {
            continue;           # Prefix does not match
        }
        lassign $r curl actions pdefs
        if {[string length $rurl] != [string length $curl] &&
            [string index $rurl [string length $curl]] != "/"} {
            # E.g. r = /a/b, rurl = /a/bc
            continue
        }
        set url_parts [split [string range $rurl [string length $curl]+1 end] /]
        set action [lindex $url_parts 0]
        if {$action eq ""} {
            set action [dict get $opts -defaultaction]
        }
        if {[llength $actions] &&
            $action ni $actions} {
            # Action does not match
            
            continue
        }

        # We have the controller and action, now match up the parameters
        set params {}
        set i 1;                # Index 0 - > action
        set match true
        foreach pdef $pdefs {
            set pname [lindex $pdef 0]
            if {[string index $pname 0] eq "*"} {
                # Collect all remaining parameters as a list
                lappend params [string range $pname 1 end] [lrange $url_parts $i end]
                # Keep looping, remaining parameter defs if any
                # would need to have default values
                set i [llength $url_parts]; # We have consumed all
                continue
            }
            # As an aside, note that URLs can never have empty
            # path components. So url_part == "" means we have finished
            # up all URL parts
            set url_part [lindex $url_parts $i]
            if {$url_part eq ""} {
                # No URL, the pdef better have default else no match
                if {[llength $pdef] < 3} {
                    # No default
                    set match false
                    break
                } else {
                    # Note defaults are not checked against the regexp, if any
                    lappend params $pname [lindex $pdef 2]
                }
            } else {
                # If a regexp specified, match the URL component against it
                if {[string length [lindex $pdef 1]] &&
                    ![regexp -- [lindex $pdef 1] $url_part]} {
                    set match false
                    break
                }
                lappend params $pname $url_part
            }
            incr i
        }
        
        # Note for a match, all URL components must also have been used up
        # $i may be > num url_parts when defaults are used
        if {$match && $i >= [llength $url_parts]} {
            return [list $curl $action $params]
        }
    }

    # No match found
    return [list ]
}


namespace eval route::test {
    variable test_routes
    set test_routes {
        curl ctrl_one act param
        curl ctrl_one act {}
        curl ctrl_one act *param
        curl ctrl_two act {paramA:[[:digit:]]+:}
        curl ctrl_three {} {paramA/paramB::30}
   }
    proc init {} {
        variable test_routes
        route::parse_routes $test_routes -clear true
    }
}