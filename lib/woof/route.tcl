# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
namespace eval route {}

proc route::read_routes {rpath} {
    # Reads a file containing route definitions.
    # rpath - path to the file
    # Reads the content of the specified file and parses it using
    # parse_routes. 
    #
    # See parse_routes for format of the routing definitions.

    set fd [open $rpath r]
    # TBD - fconfigure encoding ?
    try {
        return [parse_routes [read $fd]]
    } finally {
        close $fd
    }
}

proc route::parse_routes {route_definitions} {
    # Parses the specified routes file
    # route_definitions - string containing route definitions
    #
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
    # applicable. This may be a list of action names,
    # an empty list which
    # indicates the definition applies to all actions, or a string beginning
    # with 'implicit:'. In this last case, the URL is treated as not having
    # an action component and any remaining components after the controller
    # are matched against parameter definitions. The string after the
    # 'implicit:' prefix is treated as the action method to invoke.
    # 
    # PURL is a URL path that defines additional parameters that are
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
    # In addition, PARAMNAME field of the last path component in PURL
    # may be of the form
    #     *NAME
    # in which case the corresponding parameter is a list of all remaining URL
    # component values.
    #
    # Note that the ':' character in the default value should be
    # encoded using \u Tcl escape sequences else it will be treated
    # as the start of the default value as opposed to be embedded in
    # it.
    #
    # The returned route structures can be passed to select and construct
    # to map URL's to controller actions and vice-versa.

    # Create a safe interpreter to protect against arbitrary (malicious)
    # input in config files (although here we do not care since we
    # trust whoever wrote the routes!)
    # Creating/destroying safe interpreters is
    # cheap enough so we recreate on every call. Keeping it around would
    # require state from previous invocation to be cleaned up which is
    # a pain.

    set cinterp [interp create -safe]

    # Define the command to execute the curl routing DSL command
    $cinterp eval {
        global _routes
        set _routes {}
        proc curl {curl actions purl} {
            # TBD - check whether it would be faster to build a lambda expression
            # to evaluate at matching time instead of just storing the data

            if {[string match "implicit:*" $actions]} {
                set actions [list implicit [string range $actions 9 end]]
            } elseif {[llength $actions]} {
                set actions [list enumerated $actions]
            } else {
                set actions [list any]
            }

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

            lappend ::_routes [list $curl $actions $params]
        }
    }


    try {
        $cinterp eval $route_definitions
        #ruff
        # Returns a set of routes the structure of should be treated as opaque.
        return [$cinterp eval {set ::_routes}]
    } finally {
        interp delete $cinterp
    }
}


proc route::select {routes rurl args} {
    # Matches the specified URL against the list of route definitions
    # routes - list of routes as returned by parse_routes
    # rurl - relative URL, without query or fragment components
    # -defaultaction ACTION - action name if none specified in URL (default
    #   is 'index')
    # It is expected that $rurl is in normalized and decoded form.

    set opts [dict merge {-defaultaction index} $args]
    
    foreach r $routes {
        if {[string compare -length [string length [lindex $r 0]] [lindex $r 0] $rurl]} {
            continue;           # Prefix does not match
        }

        lassign $r curl actions pdefs

        # The prefix matches but make sure it is not a partial fragment match
        if {[string length $curl]} {
            if {[string length $rurl] != [string length $curl] &&
                [string index $rurl [string length $curl]] != "/"} {
                # E.g. r = a/b, rurl = a/bc is not a match
                continue
            }
            # Where the action component starts
            set curl_end [expr {[string length $curl]+1}]
        } else {
            # Controller URL is empty.
            set curl_end 0
        }

        # url_parts are remaining pieces after the controller components
        set url_parts [split [string range $rurl $curl_end end] /]

        if {[lindex $actions 0] eq "implicit"} {
            # Action is "implicit" and not part of the URL
            set action [lindex $actions 1]
        } else {
            # "any" or "enumerated"
            set url_parts [lassign $url_parts action]
        }

        if {$action eq ""} {
            set action [dict get $opts -defaultaction]
        }
        if {[lindex $actions 0] eq "enumerated" &&
            $action ni [lindex $actions 1]} {
            # Action does not match the enumerated action list in route
            continue
        }
        # We have the controller and action, now match up the parameters
        # $url_parts contains all the parameter components
        set params {}
        set param_index 0
        set match true
        foreach pdef $pdefs {
            set pname [lindex $pdef 0]
            if {[string index $pname 0] eq "*"} {
                # Collect all remaining parameters as a list
                set pname [string range $pname 1 end]
                if {[string length [lindex $pdef 1]]} {
                    # Verify that regexp matches all parameters
                    foreach url_part [lrange $url_parts $param_index end] {
                        if {![regexp -- [lindex $pdef 1] $url_part]} {
                            set match false
                            break
                        }
                    }
                    if {! $match} {
                        # Parameter did not match regexp. Break out of
                        # parameter matching to continue with next route
                        break
                    }
                }
                lappend params $pname [lrange $url_parts $param_index end]

                # Keep looping, remaining parameter defs if any
                # would need to have default values as the * consumes
                # everything specified in the URL. This is not really
                # a sensible configuration but...
                set param_index [llength $url_parts]; # We have consumed all
                continue
            }
            # As an aside, note that URLs can never have empty
            # path components. So url_part == "" means we have finished
            # up all URL parts
            set url_part [lindex $url_parts $param_index]
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
            incr param_index
        }
        
        # Note for a match, all URL components must also have been used up
        # $param_index may be > num url_parts when defaults are used
        if {$match && $param_index >= [llength $url_parts]} {
            return [list $curl $action $params]
        }
    }

    # No match found
    return [list ]
}


proc route::construct {routes curl action args} {
    # Returns a URL constructed from specified controller, action
    # and parameters
    # curl - relative URL for the controller
    # action - name of the action
    # -parameters PARAMLIST - dictionary containing parameter values

    foreach route [lsearch -all -inline -index 0 $routes $curl] {
        #ruff
        # The command searches for route definitions whose
        # controller URL matches the one passed in and whose action
        # definitions include the action passed in.
        lassign $route curl actions pdefs

        if {[lindex $actions 0] eq "implicit"} {
            # Action is not to be put into URL
            if {[lindex $actions 1] ne $action} {
                continue;       # Action does not match
            }
            set action "";      # Action not to be put in URL
        } else {
            if {[lindex $actions 0] eq "enumerated" &&
                $action ni [lindex $actions 1]} {
                continue;           # Action not in enumerated list
            }
        }

        #ruff
        # In addition, if the route being matched has parameter definitions,
        # each parameter must be included in PARAMLIST or have a default
        # specified. In the former case, the parameter value must satisfy
        # the match expression of the route definition, if any.

        if {[dict exists $args -parameters]} {
            set params [dict get $args -parameters]
        } else {
            set params {}
        }
        set url_params {}
        set match true
        foreach pdef $pdefs {
            set pname [lindex $pdef 0]
            if {[string index $pname 0] eq "*"} {
                set pname [string range $pname 1 end]
            }
            if {[dict exists $params $pname]} {
                set pval [dict get $params $pname]
                # If a regexp specified, param value must match it
                if {[string length [lindex $pdef 1]] &&
                    ![regexp -- [lindex $pdef 1] $pval]} {
                    set match false
                    break
                }
                dict unset params $pname
            } else {
                # The param is not passed in, a default better exist
                if {[llength $pdef] < 3} {
                    # No default
                    set match false
                    break
                }
                set pval [lindex $pdef 2]
            }
            if {[string index [lindex $pdef 0] 0] eq "*"} {
                # The parameter is a "*name" which is a list
                foreach val $pval {
                    lappend url_params [::woof::url_encode $val]
                }
            } else {
                lappend url_params [::woof::url_encode $pval]
            }
        }                

        #ruff
        # The first route matching the above conditions is used to construct
        # a relative URL. If any parameters from PARAMLIST were left over,
        # they are included as query parameters.

        if {$match} {
            # We have a winner!
            if {$action eq ""} {
                # Implicit action - do not include in URL
                set url [file join $curl {*}$url_params]
            } else {
                set url [file join $curl $action {*}$url_params]
            }
            set query {}
            foreach {k val} [dict get $params] {
                # We encode k and val separately. Else "=" might
                # will get encoded
                lappend query "[::woof::url_encode $k]=[::woof::url_encode $val]"
            }
            if {[llength $query]} {
                append url ?[join $query ";"]
            }
            return $url
        }
    }

    # If no route matches, an empty string is returned
    return ""
}


namespace eval route::test {
    variable test_routes
    set test_routes {
        curl ctrl_one act param
        curl ctrl_one act {}
        curl ctrl_one act *param
        curl ctrl_two act {paramA:[[:digit:]]+:}
        curl ctrl_three {} {paramA/paramB::30}
        curl ctrl_four {implicit:foo} {p1/p2}
        curl ctrl_four {implicit:bar} {}
        curl "" {} {*params}
    }
    proc init {} {
        variable test_routes
        return [route::parse_routes $test_routes]
    }
}