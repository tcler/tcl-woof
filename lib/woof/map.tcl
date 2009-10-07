# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.

# To allow re-sourcing
namespace eval util {}
catch {util::Map destroy}
oo::class create util::Map {
    # IMPLEMENTOR'S NOTE: 
    #  There is an assumption that all methods that modify the map go
    #  through one of the methods set, unset, init and clear. For example,
    #  the freeze method assumes this and so does the derived class
    #  DirtyMap. TBD - perhaps a trace mechanism would be a better way
    #  to track modifications.

    constructor {{map {}}} {
        # Constructs a dictionary-like object with additional functionality.
        # map - is a list of key value pairs that will be used to initialize
        #  the list
        # In addition to the defined methods, the object also creates dynamic
        # methods based on the key names stored in the object. The value
        # associated with any key can be retrieved or set 
        # by invoking a method whose
        # name is the key prefixed with a ':' character.
        #
        # The class also provides some support for acting as a cache for
        # data stored in a backend. A derived class can redefine the
        # lazy_load method to retrieve (but not set) key values
        # on demand from some arbitrary source.

        # TBD - see if _map should be a dict instead of an array
        my variable _map
        array set _map $map
    }

    method get {args} {
        # Retrieves values associated with keys.
        # args - optional arguments
        my variable _map

        #ruff
        # If the method is invoked with no parameters, the content
        # of the object is returned as a flat list of key value pairs.
        if {[llength $args] == 0} {
            my lazy_load
            return [array get _map]
        }
        set args [lassign $args key]
        
        #ruff
        # If the key exists in the object, its value is returned.
        if {[info exists _map($key)]} {
            return $_map($key)
        }

        #ruff
        # If the key does not currently exist in the object, the method
        # lazy_load is called to attempt to retrieve it and if
        # successful the value is returned.
        my lazy_load $key
        if {[info exists _map($key)]} {
            return $_map($key)
        }

        #ruff
        # If still unsuccessful and exactly two arguments are specified, the
        # second argument is treated as the default value and returned.
        # Otherwise, an error is generated.
        switch -exact -- [llength $args] {
            0 {
                set msg "Key '$key' does not exist in instance [self]"
                throw [list WOOF [self class] $msg] $msg
            }
            1 {
                return [lindex $args 0]
            }
            default {
                return -code error "Invalid number of arguments specified."
            }
        }
    }

    method hget {key} {
        # Retrieves the value of a key in HTML encoded form.
        # key - key whose associated value is to be retrieved
        # An exception is generated if the key does not exist
        # in the object.

        # TBD - fix hardcoded namespace reference
        return [::woof::util::hesc [my get $key]]
    }

    method pop {key {defval ""}} {
        # Retrieves the value associated with a key and removes
        # the key from the object.
        # key - key whose associated value is to be returned.
        # defval - default value to be returned if the key does
        #  not exist in the object.
        set val [my get $key $defval]
        my unset $key
    }

    method exists {key {v_val {}}} {
        # Check the existence of a key and optionally return its value.
        # key - key whose existence is to be checked
        # v_val - name of a variable in the caller's context
        # The method checks if the specified key exists in the object.
        # The method returns false if the key does not exist.
        # If the key exists, the method returns true and if
        # $v_val is specified, stores the value in the variable $v_val
        # in the caller's context.

        my variable _map
        if {![info exists _map($key)]} {
            my lazy_load $key
        }
        if {[info exists _map($key)]} {
            if {$v_val ne ""} {
                upvar $v_val val
                # Use the method, not direct access
                # so derived class get expected behaviour
                # if they override -get method
                set val [my get $key]
            }
            return true
        } else {
            return false
        }
    }

    method keys {} {
        # Returns the list of keys contained in the object.
        #
        # Note this does NOT return keys that are present
        # in the back end (if any) but not in this object.
        # Caller may explicitly call lazy_load
        # before calling this method if that is desired.
        my variable _map
        return [array names _map]
    }

    method count {} {
        # Returns the number of keys in the object.
        my variable _map
        return [array size _map]
    }

    method freeze {} {
        # Makes the object read-only.
        #
        # After freeze is invoked, the object cannot be modified and any
        # call to a method that would modify the object will raise an
        # exception instead.

        # Be VERY careful about modifying the escapes when constructing
        # the redefinitions!

        set msg "Attempt to modify frozen object \[self] through method \[self method] with arguments \[join \$args ,]"
        set methods {set init unset clear}
        foreach m  $methods {
            oo::objdefine [self] method $m args "throw \[list WTF INTERNAL \"$msg\"] \"$msg\""
        }
        # The following is just so we get consistent error messages whether
        # access attempt to frozen methods is attempted directly or through
        # the unknown handler
        oo::objdefine [self] "export {*}$methods"
    }

    method set args {
        # Sets the values of one or more keys in the object.
        # args - a list of key value elements
        # The value of each key specified is
        # set to the corresponding specified value.
        my variable _map
        array set _map $args
    }

    method init {args} {
        # Initialize uninitialized keys.
        # args - a list of key value elements
        # The value of each key specified is
        # set to the corresponding specified value if the key
        # did not already exist in the object.

        my variable _map
        set newvals {}
        foreach {k val} $args {
            if {![info exists _map($k)]} {
                lappend newvals $k $val
            }
        }
        my set {*}$newvals

        return
    }

    method unset {args} {
        # Removes one or more keys from the object.
        # args - list of keys to be removed
        my variable _map
        foreach key $args {
            unset -nocomplain _map($key)
        }
    }

    method clear {{pattern *}} {
        # Removes all keys matching the specified pattern from the object.
        # pattern - the pattern to match
        # The keys are matched againt $pattern using the matching rules
        # of the Tcl string match command.
        my variable _map
        array unset _map $pattern
    }
    
    method unknown args {
        # Provides shorthand methods for setting and getting key values.
        # args - The first parameter must be a key prefixed with a ":". The
        #   second optional parameter may be the value to associate with
        #   the key.
        # The following two methods are equivalent:
        #   last_names set humpty dumpty
        #   last_names :humpty dumpty
        # Similarly, the following two are equivalent:
        #   set last_name [last_names get humpty]
        #   set last_name [last_names :humpty]
        #
        if {[llength $args] == 1} {
            if {[string index [lindex $args 0] 0] eq ":"} {
                return [my get [string range [lindex $args 0] 1 end]]
            }
        } elseif {[llength $args] == 2} {
            if {[string index [lindex $args 0] 0] eq ":"} {
                return [my set [string range [lindex $args 0] 1 end] [lindex $args 1]]
            }
        }
        next {*}$args
    }

    method lazy_load {args} {
        # Abstract method to fill in missing values for keys.
        # args - keys whose values are to be filled in.
        # This method is called when an attempt is made to retrieve
        # the values for keys that are not present. This method
        # is a no-op but may be overridden by a derived class
        # to return a value for the key. The derived class can
        # call the set method to set the value for the key. It may
        # also set the values for more than one key.
        #
        # If $args is empty, all missing keys should be filled in,
        # where the term all is up to the derived class.
        return
    }

    unexport unknown
}

catch {util::DirtyMap destroy}
oo::class create util::DirtyMap {
    superclass util::Map
    constructor {args} {
        # Constructs a Map with the additional functionality that
        # state is maintained about whether the contents have been
        # modified.

        my variable _dirty
        set _dirty false
        next {*}$args
    }

    method set args {
        # Calls Map::set with all arguments and marks the object dirty.
        # args - passed on Map::set
        my variable _dirty
        next {*}$args
        set _dirty true
    }

    method init args {
        # Calls Map::init with all arguments and marks the object dirty.
        # args - passed on Map::init
        my variable _dirty
        next {*}$args
        set _dirty true
    }

    method unset args {
        # Calls Map::unset with all arguments and marks the object dirty.
        # args - passed on Map::set
        my variable _dirty
        next {*}$args
        set _dirty true
    }

    method clear args {
        # Calls Map::clear with all arguments and marks the object dirty.
        # args - passed on Map::clear
        my variable _dirty
        next {*}$args
        set _dirty true
    }

    method dirty? {} {
        # Returns true if the object has been modified since it was constructed
        # and false otherwise
        my variable _dirty
        return $_dirty
    }

    method clean {} {
        # Marks the object as being unmodified.
        my variable _dirty
        set _dirty false
    }
}
