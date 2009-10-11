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
} ::woof} [file dirname [info script]]

namespace eval ::woof {
    variable _script_dir [file normalize [file dirname [info script]]]

    # Initialize the application namespace
    namespace eval app {
        namespace path [list ::woof ::woof::util]
    }
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
    namespace eval ::woof::app [list ::woof::source_file \
                                    [file join \
                                         [::woof::config get app_dir] \
                                         controllers \
                                         application_controller.tcl]]
}

proc ::woof::handle_request {{request_context ""}} {
    # Called by a webserver to handle a client request.
    # request_context - opaque request context handle passed through to
    #  the web server module to identify this request. See
    #  request_init.

    # Create the transient namespace. Deleting this will delete all
    # created objects within it when the request handling is complete.

    # TBD - do we really need to generate a different namespace name
    # every time for every request? Might be required if as in the
    # case of the wub server, multiple requests are active in an
    # interpreter at a time.

    #ruff 
    # Returns 'true' if output has been sent to the client 
    # and 'false' otherwise.
    # Note that the output may be an error message but the command still
    # returns 'true' in that case.
    set output_done false

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
            # The webserver module's init_request method is called to
            # perform any per-request initialization or setup.
            ::woof::webserver request_init $request_context

            #ruff A new Request object is created and exported as
            # 'request'. This contains information about the client request.
            ::woof::Request create request $request_context

            # TBD - we export these so Controller has access
            # but is there a faster way like using namespace paths?
            namespace export request response

            #ruff
            # The request is then mapped to a particular controller and action
            # by the url_crack command.
            set dispatchinfo [::woof::url_crack [request resource_url]]

            set controller_class ::woof::app::[dict get $dispatchinfo controller_class]
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

                namespace eval ::woof::app [list \
                                                ::woof::source_file \
                                                $controller_path \
                                                -sourceonce true \
                                                -ignoremissing true]
                if {[llength [info commands $controller_class]] == 0} {
                    # TBD - if no controller, only the template should be processed as documented above?
                    # TBD - where do we log url that was not found ?
                    ::woof::log err "$controller_class not found in path $controller_path"
                    exception WOOF_USER InvalidRequest
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
            response content "<html><body><pre>[::woof::util::hesc $usermsg]</pre></body></html>"
        } finally {
            try {
                # Display either the response or the error message. Even this
                # might error so we trap to clean up the namespaces
                ::woof::webserver output $request_context \
                    [dict create \
                         status [response status] \
                         status_line [response status_line] \
                         headers [response headers] \
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


proc ::woof::url_crack {url} {
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
                controller_dir  [file join [file join [config get root_dir] [config get app_dir] controllers] {*}$module] \
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
    #     if not the default from $crack_url
    #  -action ACTION - name of the action. This defaults to 'index',
    #     and is not based on $cracked_url
    #
    # Returns a URL that will corresponds to the controller and
    # action. Note this does not include server, port or query components.

    # TBD - this is quite simplistic, replace when more sophisticated
    # mapping is done.

    array set opts $args
    if {[info exists opts(-module)]} {
        set module $opts(-module)
    } else {
        set module [dict get $cracked_url module]
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
        exception WOOF_USER InvalidRequest
    }

    #ruff
    # Returns the constructed URL.
    return $url
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
