# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Module dealing with Woof! configuration

oo::class create Configuration {
    superclass ::woof::util::Map
    constructor {woof_root} {
        # Contains Woof configuration information.
        # woof_root - path to the root of the Woof installation.
        #
        # The class stores the information contained in the
        # Woof configuration file as a Map object.
        # The information is read once when an object is
        # instantiated and thereafter only updated when
        # the load method is invoked.
        #
        # See the sample configuration file
        # in the Woof distribution for a description
        # of settings and default values.

        next

        my variable _woof_root
        set _woof_root [file normalize $woof_root]
        my load
    }

    method load {} {
        # Loads the current values from the configuration file.
        #
        my variable _woof_root

        # We will first generate values in a temporary variable
        array set final_values {}

        #ruff
        # The following values are not actually read from the configuration
        # file but are fixed for a Woof installation:
        # root_dir - the directory where Woof is installed.
        # public_dir - Woof's public directory
        # config_dir - the file system directory where Woof configuration is
        #  installed.
        array set final_values \
            [list \
                 root_dir   $_woof_root \
                 public_dir [file join $_woof_root public] \
                 config_dir [file join $_woof_root config] \
                ]

        #ruff
        # For a description of the other configuration settings, please refer
        # to the sample configuration file.
        array set booleans {
            debug               false
            reload_scripts      false
            reload_templates    false
            expose_error_detail false
        }

        array set integers {
            debug_level {0 {0 9}}
        }

        array set file_paths \
            [list \
                 temp_dir     [file join $_woof_root temp] \
                 session_dir  [file join $_woof_root temp] \
                 app_dir      [file join $_woof_root app] \
                 log_dir      [file join $_woof_root temp] \
                 route_file   [file join $_woof_root config routes.cfg] \
                ]

        array set enums {
            loglevel  {info {debug info notice warn err crit alert emerg}}
            run_mode  {development {development production}}
        }

        array set strings {
            url_root /
        }
        
        array set cvals [my _parse_config \
                             [file join $final_values(config_dir) application.cfg] \
                             [file join $final_values(config_dir) _woof.cfg]]

        # Validate booleans
        foreach {cvar defval} [array get booleans] {
            set final_values($cvar) $defval
            if {[info exists cvals($cvar)]} {
                if {[string is boolean $cvals($cvar)]} {
                    set final_values($cvar) $cvals($cvar)
                    unset cvals($cvar)
                } else {
                    # TBD - log config error
                }
            }
        }

        # Validate integers
        foreach {cvar default_and_range} [array get integers] { 
            set final_values($cvar) [lindex $default_and_range 0]
            if {[info exists cvals($cvar)]} {
                if {![string is wideinteger -strict $cvals($cvar)]} {
                    # TBD - log config error
                    unset cvals($cvar)
                    continue
                }
                if {[llength [lindex $default_and_range 1]]} {
                    lassign [lindex $default_and_range 1] low high
                    if {$high eq ""} {
                        # Single digit in range means 0-value
                        # Forget about single negative numbers
                        set high $low
                        set low 0
                    }
                    if {$cvals($cvar) < $low || $cvals($cvar) > $high} {
                        # TBD - log error
                    } else {
                        set final_values($cvar) $cvals($cvar)
                    }
                    unset cvals($cvar)
                }
            }
        }
            
        # Validate enums
        foreach {cvar default_and_range} [array get enums] { 
            set final_values($cvar) [lindex $default_and_range 0]
            if {[info exists cvals($cvar)]} {
                if {$cvals($cvar) ni [lindex $default_and_range 1]} {
                    # TBD - log config error
                    continue
                } else {
                    set final_values($cvar) $cvals($cvar)
                }
                unset cvals($cvar)
            }
        }

        # Validate file_paths
        foreach {cvar defval} [array get file_paths] {
            set final_values($cvar) $defval
            if {[info exists cvals($cvar)]} {
                set final_values($cvar) $cvals($cvar)
                unset cvals($cvar)
            }

            # If relative path, make it one and normalize.
            # volumerelative paths will be taken care of in the normalize below.
            if {[file pathtype $final_values($cvar)] eq "relative"} {
                set final_values($cvar) [file join $_woof_root $final_values($cvar)]
            }

            set final_values($cvar) [file normalize $final_values($cvar)]

            # Note we do not validate existence as caller may want
            # to create them as desired.
        }

        # Strings - no validation
        foreach {cvar defval} [array get strings] {
            set final_values($cvar) $defval
            if {[info exists cvals($cvar)]} {
                set final_values($cvar) $cvals($cvar)
                unset cvals($cvar)
            }
        }
           
        # All left-overs, that have no defaults
        array set final_values [array get cvals]

        #ruff
        # The following settings are required and must be defined in the 
        # configuration file as they have no defaults.
        # app_name - the name of the application to be used for display purposes.
        foreach cvar {app_name} {
            if {![info exists final_values($cvar)]} {
                ::woof::errors::exception WOOF ConfigurationError "Setting $cvar is required but is missing from in the configuration file."
            }
        }

        # Now store the values
        my clear;              # *Everything* goes away
        # Update config
        my set {*}[array get final_values]
        return
    }

    method _parse_config {args} {
        # Parses configuration files and returns settings from it.
        # args - list of paths to configuration files
        #
        # Each configuration file is a Tcl script that is executed
        # in a safe interpreter. All variables defined in the script
        # except those beginning with an underscore (_) are
        # treated as configuration settings. Variables set in
        # one file may be assigned new values in subsequent files.
        # If overriding of values set in a configuration file
        # occurring earlier in the list is not desired, the command
        # 'init' may be used in a configuration file
        # to set a variable only if it does not already exist.
        #
        # It is not an error if a file does not exist.
        # 
        # Returns a dictionary containing the configuration keys
        # and corresponding values.

        set cinterp [interp create -safe]
        $cinterp eval {
            namespace eval settings {
                proc init {var val} {
                    # Init a variable - only set if it does not already exist
                    variable $var
                    if {![info exists $var]} {
                        set $var $val
                    }
                }
            }
        }
        try {
            foreach path $args {
                if {[file exists $path]} {
                    $cinterp invokehidden -namespace settings source $path
                }
            }
            set result [$cinterp eval {
                set values [dict create]
                foreach varname [info vars ::settings::*] {
                    set name [namespace tail $varname]
                    if {! [string match _* $name]} {
                        dict set values [namespace tail $varname] [set $varname]
                    }
                }
                set values
            }]
        } finally {
            interp delete $cinterp
        }

        return $result
    }

}
