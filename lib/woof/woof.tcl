# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

package require Tcl 8.6
package require uri
package require html

if {[llength [info commands ::woof::version]] == 0} {
    source [file join [file dirname [info script]] woofversion.tcl]
}

# Source util namespace under the woof namespace
# The apply allows dir variable without polluting globals or namespaces
apply {dir {
    source [file join $dir errors.tcl]
    source [file join $dir util.tcl]
    source [file join $dir map.tcl]
    source [file join $dir session.tcl]
    source [file join $dir cookies.tcl]
    source [file join $dir request.tcl]
    source [file join $dir response.tcl]
    source [file join $dir controller.tcl]
    source [file join $dir page.tcl]
    source [file join $dir wtf.tcl]
    source [file join $dir hutil.tcl]
} ::woof} [file dirname [info script]]

namespace eval ::woof {
    variable _script_dir [file normalize [file dirname [info script]]]

    # Initialize the application namespace
    namespace eval app {
        namespace path [list ::woof ::woof::util]
    }

    # Route definitions
    variable _routes
}


proc ::woof::init {} {
    # Called by the master interpreter to initialize the safe web interpreter
    # in which requests are processed.
    variable _script_dir

    set server_module [config get server_module]

    # Loading of the following files is here because it is dependent on
    # the server_module and application directories which are not set up
    # when the package is actually loaded.
    uplevel #0 [list ::woof::source_file \
                    [file join $_script_dir webservers ${server_module}_mixins.tcl] \
                    -sourceonce true \
                    -ignoremissing true]

    if {[llength [info class instances ::oo::class ::woof::webservers::${server_module}::RequestMixin]]} {
        oo::define ::woof::Request "mixin ::woof::webservers::${server_module}::RequestMixin"
    }

    # Load the application controller from where controllers are derived.
    namespace eval ::woof::app {
        namespace path ::woof
        source_file \
            [file join [::woof::config get app_dir] controllers application_controller.tcl]
    }
}

proc ::woof::handle_request {{request_context ""}} {
    # Called by a webserver to handle a client request.
    # request_context - opaque request context handle passed through to
    #  the web server module to identify this request. See
    #  request_init.

    #ruff 
    # Returns 'true' if output has been sent to the client 
    # and 'false' otherwise.
    # Note that the output may be an error message but the command still
    # returns 'true' in that case.
    set output_done false

    variable _routes
    if {![info exists _routes] || [config get reload_scripts]} {
        set _routes [read_routes]
    }

    # Create the transient namespace. Deleting this will delete all
    # created objects within it when the request handling is complete.
    # TBD - do we really need to generate a different namespace name
    # every time for every request? Might be required if as in the
    # case of the wub server, multiple requests are active in an
    # interpreter at a time.

    set trans_ns  [util::generate_name ::woof::request_ns]
    namespace eval $trans_ns {}
    set ${trans_ns}::request_context $request_context
    namespace eval $trans_ns {
        try {
            #ruff A new Response object is created and exported as
            # 'response'. This holds the response to be sent back to the
            # client.
            ::woof::Response create response

            #ruff
            # The command obtains information about the request through
            # callbacks implemented by the webserver interface module.
            # The webserver module's request_init method is called to
            # perform any per-request initialization or setup.
            set request_context [::woof::webserver request_init $request_context]

            #ruff A new Request object is created and exported as
            # 'request'. This contains information about the client request.
            ::woof::Request create request $request_context

            # TBD - we export these so Controller has access
            # but is there a faster way like using namespace paths?
            namespace export request response

            #ruff
            # The request is then mapped to a particular controller and action
            # by the url_crack command.
            set dispatchinfo [::woof::url_crack [request resource_url] $::woof::_routes]

            set controller_class ::woof::app::[dict get $dispatchinfo controller_class]
            if {[::woof::config get reload_scripts] &&
                [llength [info commands $controller_class]] != 0} {
                # We want to reload scripts every time. Delete the class
                # and reload.
                $controller_class destroy
            }

            if {[llength [info commands $controller_class]] == 0} {
                #ruff The corresponding file is sourced into the ::woof::app
                # namespace. Note that file is sourced only the first time it
                # is required by a request and not for every request. Missing
                # files are ignored under the premise that in that case
                # only the template is to be rendered and no controller action 
                # is required.
                set controller_path [file join \
                                         [dict get $dispatchinfo controller_dir] \
                                         [dict get $dispatchinfo controller_file]]
                namespace eval [namespace qualifiers $controller_class] {namespace path {::woof::app ::woof}}
                # TBD - should -sourceonce be true or false? How about when
                # reloading scripts ?
                namespace eval [namespace qualifiers $controller_class] \
                    [list \
                         ::woof::source_file \
                         $controller_path \
                         -sourceonce true \
                         -ignoremissing true]
                if {[llength [info commands $controller_class]] == 0} {
                    # TBD - if no controller, only the template should be processed as documented above?
                    # TBD - where do we log url that was not found ?
                    ::woof::log err "$controller_class not found in path $controller_path"
                    woof::errors::exception WOOF_USER InvalidRequest
                }
            }

            #ruff
            # The controller must be a descendent of the ApplicationController class.
            # After loading and creating the controller object, it's process method
            # is called which in turn invokes the action method in the controller.
            $controller_class create \
                controller \
                [namespace current]::request \
                [namespace current]::response \
                $dispatchinfo
            controller process
        } on error {msg eropts} {
            # TBD - document error handling
            # If the error should be user visible display it. Normally,
            # applications should do this via redirection so that appropriately
            # branded pages can be shown. This is a last resort only to
            # directly build a raw page.
            if {[dict exists $eropts -errorcode]} {
                set ercode [dict get $eropts -errorcode]
                set type [lindex $ercode 0]
            }
            if {[::woof::config get expose_error_detail false]} {
                # We want to show the same detail that we logged
                # Just alias usermsg to msg so both are same
                upvar 0 msg usermsg
            } else {
                if {[info exists ercode] &&
                    ([lindex $ercode 0] eq "WOOF_USER")} {
                    set usermsg $msg
                    append usermsg " [::woof::errors::help WOOF_USER [lindex $ercode 1]]"
                } else {
                    set usermsg "An internal error has occurred. Please contact the web server administrator."
                }
            }

            # Add error code if available
            if {[info exists ercode]} {
                append msg "\nError code: $ercode"
            }

            # Add stack trace if available
            if {[dict exists $eropts -errorinfo]} {
                append msg "\nError: [dict get $eropts -errorinfo]"
            }
            
            # Log the error
            ::woof::log err $msg

            # Display error
            response reset
            response status 500
            response content_type text/html
            response content "<html><body><p>[::woof::util::hesc $usermsg]</p></body></html>"
        } finally {
            try {
                # Display either the response or the error message. Even this
                # might error so we trap to clean up the namespaces
                ::woof::webserver output $request_context \
                    [dict create \
                         status [response status] \
                         status_line [response status_line] \
                         headers [response headers] \
                         content_type [response content_type] \
                         content [response content]]
		set output_done true
            } finally {
                # Namespace will be deleted as soon as execution exits its context
                namespace delete [namespace current]
            }
        }
    }

    return $output_done
}


proc ::woof::url_crack {url routes} {
    # Construct application request context from a URL.
    # url - the URL of interest relative to the application URL root
    #
    # Returns a dictionary mapping the given relative URL path to
    # a controller, action and related context.

    set rel_path [string trimleft $url /]

    if {[string length $rel_path] == 0} {
        set rel_path [config get app_default_uri ""]
    }
    set tokens [split $rel_path /]
    set ntokens [llength $tokens]
    if {$ntokens == 0} {
        # No module, default controller and action (even app_default_uri)
        set module {}
        set controller [config get app_default_controller [config get app_name]]
        set action     [config get app_default_action index]
    } elseif {$ntokens == 1} {
        # No module, specific controller, default action
        set module {}
        set controller [lindex $tokens 0]
        set action [config get app_default_action index]
    } else {
        # Last two tokens are controller and action
        # Rest (if any) specify module and namespace
        set module [lrange $tokens 0 end-2]
        set controller [lindex $tokens end-1]
        set action [lindex $tokens end]
    }

    # Here is where the various paths and defaults get set. search_dirs
    # and view_paths will get built top-down and then reversed
    set module_dir ""
    set search_dirs [list .]
    foreach mod $module {
        set module_dir [file join $module_dir $mod]
        lappend search_dirs $module_dir
    }
    set search_dirs [lreverse $search_dirs]

    #ruff
    # The returned dictionary has the following keys:
    # action - the name of the action to be invoked
    # app_dir - fully qualified name of the directory where the
    #  application code resides
    # controller - the name of the controller referenced by the request
    # controller_class - the name of the class (including module namespace
    #  qualifiers) corresponding to the controller
    # controller_dir - the subdirectory within the application directory
    #  where the controller code resides
    # controller_file - the name of the source file for the controller
    # module - the name of the module referenced by the request as a
    #  list of module components (not in namespace format)
    # search_dirs - list of directories to search for module-specific
    #  components such as stylesheets.
    #  Note the last element is always "." indicating the
    #  context-dependent root of the search tree.
    # url_root - the root URL where the application resides

    return [dict create \
                url_root      [config get url_root] \
                module        $module \
                controller    $controller \
                action        $action \
                controller_class [join [concat $module [list [::woof::util::mixcase $controller]Controller]] ::] \
                app_dir       [config get app_dir] \
                controller_dir  [file join [config get root_dir] [config get app_dir] controllers {*}$module] \
                controller_file ${controller}_controller.tcl \
                search_dirs     $search_dirs \
               ]
}

proc ::woof::url_build {cracked_url args} {
    # Construct a URL for a controller and action
    #  cracked_url - the dictionary as returned by url_crack
    #  -controller CONTROLLER - name of controller to use instead of
    #     the default from $crack_url
    #  -module MODULE - name of the module in which controller resides,
    #     if not the default from $crack_url. This must be in the
    #     same format returned by url_crack.
    #  -action ACTION - name of the action. This defaults to 'index',
    #     and is not based on $cracked_url
    #
    # Returns a URL that will corresponds to the controller and
    # action. Note this does not include server, port or query components.

    # TBD - this is quite simplistic, replace when more sophisticated
    # mapping is done.

    array set opts $args
    if {[info exists opts(-module)]} {
        set module [join $opts(-module) /]
    } else {
        set module [join [dict get $cracked_url module] /]
    }
    if {[info exists opts(-controller)]} {
        set controller $opts(-controller)
    } else {
        set controller [dict get $cracked_url controller]
    }
    if {[info exists opts(-action)]} {
        set action $opts(-action)
    } else {
        set action "index"
    }

    # We use file join and not join here to take care of trailing or dup /
    return [file join [dict get $cracked_url url_root] $module $controller $action]
}

proc ::woof::url_for_file {path {default_url ""}} {
    # Constructs a URL for a static file in the Woof tree
    # path - path to the file for which the URL is
    #  to be returned.
    # default_url - URL to be returned if the file
    #  is outside the public Woof area
    #
    # If $path is relative, it is assumed to be relative
    # to the Woof public directory.
    #
    # If $default_url is unspecified or is an empty string,
    # an error is raised if the path is not public area.
    #
    # Note the returned URL does not include the protocol, host
    # or port.

    # TBD - how to handle sym links ? Should we check path
    # after resolving symlinks ?

    set url [::woof::map_file_to_url $path [list [config get public_dir] [config get url_root]]]
    if {$url eq ""} {
        set url $default_url
    }

    if {$url eq ""} {
        ::woof::errors::exception WOOF_USER InvalidRequest
    }

    #ruff
    # Returns the constructed URL.
    return $url
}

proc ::woof::source_file {path args} {
    # Sources a file into the interpreter
    # path - path to the file to be sourced
    # This is used only for sourcing application files, not
    # for the core Woof! libraries.

    variable _sourced_files

    #ruff
    # -ignoremissing BOOLEAN - if true, then missing files are treated
    #  as though they exist but are empty. If false (default), an error
    #  is generated
    set opts(-ignoremissing) false

    #ruff
    # -sourceonce BOOLEAN - if true, then the file is not sourced if
    #  it has already been sourced. Default is false. This option
    #  is ignored if the configuration option reload_scripts is true.
    set opts(-sourceonce) false

    array set opts $args

    set reload_scripts [config get reload_scripts]

    # The cache is based on the passed path, not the normalized path.
    # Normalizing is almost as expensive as reading the file so it would
    # be useless doing the latter. In most cases it should not matter
    # since the scripts are accessed using the same syntactic path.
    # However, see the note below about volumerelative paths.
    if {[info exists _sourced_files($path)] && $opts(-sourceonce) && ! $reload_scripts} {
        return
    }

    if {[file pathtype $path] eq "relative"} {
        #ruff
        # $path may be a relative path in which case it is assumed
        # to be relative to the Woof root directory.
        set abspath [file join [config get root_dir] $path]
        # TBD - what other paths to try ?
    } elseif {[file pathtype $path] eq "volumerelative"} {
        #ruff
        # $path must not be a volume-relative path as it does not interact
        # properly with caching when the process' current directory on
        # a drive is changed.
        # There is never a need to use volume relative paths
        # anyway.
        woof::errors::exception WOOF Bug "Volume relative path '$path' passed in to command source_file."
    } else {
        #ruff
        # $path may also be an absolute path that includes a drive letter
        # and the full path to the file to be sourced.
        set abspath $path
    }

    #ruff
    # The path is verified to lie within the Woof directory structure.
    # Note this is done even for relative paths
    # since they make contain .. components.

    # Note for implementing above security, we rely on the master
    # interpreter to ensure we do not go outside the allowed areas
    # so we do not care about normalization here.

    #ruff
    # Depending on the value of the reload_scripts configuration
    # setting, the command will read the file from the Woof file cache.

    set readopts [list -cachecontrol [expr {$reload_scripts ? "ignore" : "readwrite"}]]
    if {$opts(-ignoremissing)} {
        lappend readopts -defaultcontent ""
    }
    set src [filecache_read $abspath {*}$readopts]

    #ruff
    # The command remembers which files are passed in based on the path
    # passed in as input, not on its normalized equivalent. Thus, 
    # a file may be sourced multiple times if each time it is accessed
    # through a different syntactic path (e.g. relative) or through
    # links. Note relative paths are always relative to the Woof
    # root 

    set _sourced_files($path) ""; # Remember we've sourced it

    # Load the code. Since we are simulating a script, set info script
    # to return the script file path for the duration of the script.
    set saved_script_path [info script]
    info script $abspath
    set ret [uplevel 1 $src]
    info script $saved_script_path
    return $ret
}


proc ::woof::app::uses {name} {
    # Finds and loads a controller class
    # name - name of the controller class, optionally namespace qualified
    # The command locates and loads the specified controller class if
    # it has not already been loaded in ::woof::app namespace.
    #

    #ruff
    # The command must be called from the top level when a source is
    # being sourced as the file from which the class is being loaded is
    # dependent on the script from where it is called.
    #
    set caller [uplevel 1 [list info script]]
    if {$caller eq ""} {
        ::woof::errors::exception WOOF Bug "The command 'uses' must only be called from the top level of a script."
    }

    set reload_scripts [config get reload_scripts false]

    if {[namespace tail $name] eq $name} {
        #ruff
        # The class name $name may be unqualified in which case, it is located
        # in the same directory as the caller and loaded into the caller's
        # namespace.
        if {[llength [uplevel 1 [list info commands $name]]] == 1} {
            # Command already exists. Check if it should be reloaded
            if {$reload_scripts} {
                uplevel 1 [list $name destroy]
            } else {
                return;         # Already there, and no need to reload
            }
        }

        set path [file join [file dirname $caller] [::woof::util::unmixcase $name].tcl]
        uplevel 1 [list ::woof::source_file \
                       $path -sourceonce \
                       [expr {! $reload_scripts}]]
    } else {
        #ruff
        # If $name is a qualified
        # name it must be relative to the ::woof::app namespace (not fully
        # qualified) and include the entire path under it.
        #
        if {[string range $name 0 1] eq "::"} {
            ::woof::errors::exception WOOF Bug "Fully qualified name '$name' passed to 'use' command."
        }
        set fqn "::woof::app::$name"
        # Check if command exists. It is fully qualified so we do not have
        # to do a uplevel to verify it in the caller's context
        if {[llength [info commands $fqn]] == 1} {
            # Command already exists. Check if it should be reloaded
            if {$reload_scripts} {
                $fqn destroy
            } else {
                return;         # Already there, and no need to reload
            }
        }

        #ruff The corresponding file is then loaded into that namespace,
        # and not the namespace of the caller since by convention 
        # controller files are defined without namespaces and are
        # expected to be loaded into the appropriate namespace by the caller.
        set path [file join \
                      [config get root_dir] \
                      [config get app_dir] \
                      controllers \
                      [string map {:: /} [namespace qualifiers $name]] \
                      [::woof::util::unmixcase [namespace tail $name]].tcl]
        
        namespace eval [namespace qualifiers $fqn] \
            [list ::woof::source_file \
                 $path \
                 -sourceonce [expr {! $reload_scripts}]]
    }
    return
}


namespace eval ::woof {
    # Export our procs - note we do this before the imports
    util::export_all
    # Export the classes
    namespace export Log

    namespace import util::*
    namespace import ::woof::errors::*
}


package provide woof [::woof::version]
