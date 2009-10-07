# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
# In Woof!, that will be the ::woof namespace

catch {CookiesIn destroy}; # To allow resourcing
oo::class create CookiesIn {
    superclass ::woof::util::Map
    variable _raw_cookie
    constructor {raw_cookie} {
        # Provides an interface to contains cookies received as part
        # of a request as a Map object.
        #
        # The cookies and corresponding values can be accessed using
        # the standard Map methods.
        set _raw_cookie $raw_cookie
        next
    }

    method lazy_load {args} {
        # Loads the cookie values on demand.
        # args -  list of cookie keys
        #
        # Note that for performance reasons, the method loads all cookie
        # values in the Map and not justthe keys specified in $args.
        #
        # See Map.lazy_load for details of this call back method.
        
        # TBD - right now this is always called because the session
        # code always checks for existence of session id in cookie.
        # At some point session need to be created in lazy fashion
        # as well

        if {[info exists _raw_cookie]} {
            my _decode_cookie $_raw_cookie
            unset _raw_cookie
        }
    }

    method _decode_cookie {raw_cookie} {
        # raw_cookie - the raw cookies received in the request
        # The cookies and corresponding values can be accessed
        # using the standard Map methods.

        # Contains expiry etc. for cookies
        my variable _attrs
        # Duplicate cookie values stored here
        my variable _duplicates

        set _attrs [dict create]
        set _duplicates [dict create]

        # Following parsing code from Libes' cgi.tcl library
        foreach pair [split $raw_cookie ";"] {
            # pairs are actually split by "; ", sigh
            set pair [string trimleft $pair " "]
            # spec is not clear but seems to allow = unencoded
            # only sensible interpretation is to assume no = in var names
            # appears MS IE can omit "=val"
            set val ""
            regexp (\[^=\]*)=?(.*) $pair dummy varname val
                    
            # Decode the varname and the value
            set varname [::woof::util::cookie_decode $varname]
            set val     [::woof::util::cookie_decode $val]
                    
            if {[my exists $varname]} {
                # TBD - what interface do we make duplicates available ?
                dict lappend _duplicates $varname $val
            } else {
                my set $varname $val
            }
        }

        # Commented out - unnecessary perf cost: my freeze; # No modifications
    }
}

# This could possibly be derived from Map as well
# but too much difference in behaviour to do it without
# overriding most things. So we have to reimplement
# most of the interface.
catch {CookiesOut destroy}; # To allow resourcing
oo::class create CookiesOut {

    constructor {} {
        # The CookiesOut class encapsulates cookies that are
        # to be sent in the response to the client.
        #
        # The class does not have Map as a base class but
        # implements the same interface.
        #
        # In addition to the associated value, cookies
        # may have associated attributes as well which
        # may be set with the setwithattr method.
        my variable _jar
        array set _jar {}
    }

    method set args {
        # Sets the values of one or more cookies.
        # args - a list of key and value elements
        # The value of each key specified is
        # set to the corresponding specified value.
        # No attributes are associated with the cookie.
        foreach {name val} $args {
            my setwithattr $name $val
        }
    }

    method setwithattr {name value args} {
        # Sets the value and attributes of a cookie
        # name - name of the cookie
        # value - the value to associate with the cookie
        # args - optional arguments to set attributes
        # 
        my variable _jar

        array set opts {-httponly false -secure false}
        array set opts $args

        # TBD - can value be "" ?
        set cookie [dict create -value $value]

        if {[info exists opts(-expires)]} {
            #ruff
            # -expires EXPIRYTIME - sets the expiration for
            #  the cookie. If the option is not specified, 
            #  the cookie expiration is 24 hours. If EXPIRYTIME
            #  is 'never', the cookie is set to never expire.
            #  A value of 'now' expires the cookie immediately
            #  (in essence used to delete the cookie from the client).
            #  Otherwise, EXPIRYTIME must be a positive integer
            #  and interpreted as the number of seconds since
            #  00:00:00 Jan 1, 1970.
            switch -exact -- {
                now {
                    # Expire the cookie - set any time in the past
                    # We pick Jan 1 2000
                    set opts(-expires) 946684800
                }
                never {
                    # TBD - is this the right value for never?
                    #"Friday, 11-Jan-2038 23:59:59 GMT"
                    set opts(-expires) 2146867199
                }
                default {
                    # Assume an integer value representing number of seconds
                    if {![string is integer -strict $opts(-expires)]} {
                            throw [list WOOF INTERNAL "Invalid value specified for cookie attribute -expires"] "Invalid value '$opts(-expires)' specified for cookie attribute -expires."
                        }
                }
            }
        } else {
            # TBD - this does not seem right? We should just not set
            # this attribute if not specified.
            set opts(-expires) [clock add [clock seconds] 24 hours]
        }
        dict set cookie expires [::woof::util::format_http_date $opts(-expires)]

        #ruff
        # -domain DOMAIN - sets the domain attribute which
        #  associates the cookie with a specific domain
        # -path PATH - sets the path attribute which
        #  associates the cookie with the specific URL path
        foreach attr {domain path} {
            if {[info exists opts(-$attr)]} {
                if {$opts(-$attr) eq ""} {
                    throw [list WOOF INTERNAL "Empty value specified for cookie attribute $attr"] "Empty value specified for cookie attribute $attr"
                }
                dict set cookie $attr $opts(-$attr)
            }
        }

        #ruff
        # -secure BOOLEAN - if true, includes the secure attribute in the cookie
        # -httponly BOOLEAN - if true, includes the httponly attribute in the cookie
        foreach attr {secure httponly} {
            if {$opts(-$attr)} {
                dict set cookie $attr true
            }
        }

        lappend _jar($name) $cookie
    }

    method get {args} {
        # Retrieves the value associated with a cookie
        # args - optional arguments

        my variable _jar

        #ruff
        # If the method is invoked with no parameters, the cookies
        # are returned as a flat list of cookie name-value pairs.
        if {[llength $args] == 0} {
            set ret {}
            foreach {name cookielist} [array get _jar] {
                lappend ret $name [dict get [lindex $cookielist 0] -value]
            }
            return $ret
        }

        set args [lassign $args name]

        #ruff
        # If a single argument is specified, the method returns the
        # associated value if the cookie exists. Otherwise
        # an exception is generated.
        if {[info exists _jar($name)]} {
            return [dict get [lindex $_jar($name) 0] -value]
        }

        if {[llength $args] == 0} {
            set msg "Response cookie $name does not exist"
            throw [list WOOF [self class] $msg] $msg
        } else {
            #ruff
            # If more than one argument is specified, the first argument
            # is the cookie whose value is to be returned, and the second
            # argument is the default value to be returned if the cookie
            # does not exist.
            return [lindex $args 0]
        }
    }

    method cookies {} {
        # Returns a list of all cookies.
        # Each element of the returned list is a cookie value,
        # including attributes if any, that can be used
        # as the value of a HTTP Set-Cookie header.

        # TBD - does order matter?
        my variable _jar
        set cookie_list {}
        foreach {key cookies} [array get _jar] {
            foreach cookie $cookies {
                set c "$key=[::woof::util::cookie_encode [dict get $cookie -value]];"
                if {[dict exists $cookie expires]} {
                    # Note no need to encode date time string
                    append c " expires=[dict get $cookie expires];"
                }
                foreach attr {domain path} {
                    if {[dict exists $cookie $attr]} {
                        # TBD - what encoding to use? cookie_encode/url_encode
                        # encodes / as %5f as well which browsers do not match
                        # properly in paths. For now do not encode
                        append c " $attr=[dict get $cookie $attr];"
                    }
                }
                foreach attr {secure httponly} {
                    if {[dict exists $cookie $attr]} {
                        # Note no value associated
                        append c " $attr;"
                    }
                }

                lappend cookie_list $c
            }
        }
        return $cookie_list
    }

    method unset {cookie_name} {
        # Removes a previously defined cookie.
        # cookie_name - name of the cookie to be removed
        # Note this does not remove the cookie from the
        # client side, only from the outgoing response.

        my variable _jar
        unset -nocomplain _jar($cookie_name)
    }

    method clear {{pattern *}} {
        # Removes all cookies matching a pattern .
        # pattern - pattern to match using the same
        #  syntax as the Tcl string match command.
        # Note this does not remove the cookies from the
        # client side, only from the outgoing response.
        my variable _jar
        array unset _jar $pattern
    }

    method keys {{pattern *}} {
        # Returns a list of defined cookie names matching a pattern
        # pattern - pattern to match using the same
        #  syntax as the Tcl string match command.
        my variable _jar
        return [array names _jar]
    }


    method freeze {} {
        # Makes the object read-only so no further updates to cookies
        # are possible.

        # Be VERY careful about modifying the escapes when constructing
        # the redefinitions!
        
        set msg "Attempt to modify frozen object \[self] through method \[self method]"
        set methods {set setwithattr unset clear}
        foreach m  $methods {
            oo::objdefine [self] method $m args "throw \[list WOOF INTERNAL \"$msg\"] \"$msg\""
        }
        # The following is just so we get consistent error messages whether
        # access attempt to frozed methods is attempted directly or through
        # the unknown handler
        oo::objdefine [self] "export {*}$methods"
    }

    method exists {cookie_name {v_val {}}} {
        # Check the existence of a cookie and optionally return its value.
        # cookie_name - cookie whose existence is to be checked
        # v_val - name of a variable in the caller's context
        # The method checks if the specified cookie exists in the object.
        # The method returns false if the cookie does not exist.
        # If the cookie exists, the method returns true and if
        # $v_val is specified, stores the value in the variable $v_val
        # in the caller's context.

        my variable _jar
        if {[info exists _jar($cookie_name)]} {
            if {$v_val ne ""} {
                upvar $v_val val
                # Use the method, not direct access
                # so derived class get expected behaviour
                # if they override get method
                set val [my get $cookie_name]
            }
            return true
        } else {
            return false
        }
    }

    method count {} {
        # Returns the number of defined cookies.
        my variable _jar
        return [array size _jar]
    }

    method unknown {args} {
        # Provides shorthand methods for setting and getting cookie values.
        # args - The first parameter must be a cookie prefixed with a ":". The
        #   second optional parameter may be the value to associate with
        #   the key.
        # The following two methods are equivalent:
        #   ocookies set humpty dumpty
        #   ocookies :humpty dumpty
        # Similarly, the following two are equivalent:
        #   set cookie [ocookies get humpty]
        #   set cookie [ocookies :humpty]
        #
        my variable _jar
        
        # If no args, return list of cookie names
        set nargs [llength $args]
        if {$nargs == 0} {
            return [array names $_jar]
        }

        set name [lindex $args 0]

        # If a single arg, return the first value of the cookie
        # Exception if no such cookie
        if {$nargs == 1} {
            return [my get $name]
        }
                    
        my setwithattr $name [lindex $args 1] {*}[lrange $args 2 end]
    }

    export get setwithattr set exists unset clear keys freeze cookies count
}


namespace eval [namespace current] {
    namespace export CookiesIn CookiesOut
}
