# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

namespace eval ::woof {
    # Name of key storing session id. TBD - make this changeable?
    variable session_key_name "woofsid"
}

# Flash
catch {Flash destroy}; # To allow resourcing
oo::class create Flash {
    superclass ::woof::util::Map
    constructor {args} {
        # Container for storage of temporary data that needs to be
        # passed between actions, potentially across separate client requests.
        #
        # At times an application may need to pass data between actions
        # (methods), either within the same request or across consecutive
        # requests. This class is a Map with that added functionality.
        #
        # Data stored in the flash in a request
        # is made available in the next action
        # (or request) and cleared thereafter. It may however be persisted
        # further through the -keep method. Conversely, it's lifetime
        # may be restricted to only the current request through the
        # -transient method.

        next

        my variable _transients

        my set {*}$args
                    
        # Mark existing content as transient
        set _transients [my keys]
    }
                
    method keep args {
        # Marks data that would be cleared as persistent until the next request.
        # args - keys corresponding to the data to be persisted
        #
        # Normally, data in the flash is maintained until the request
        # following the request that stored the data into the flash.
        # When -keep is called, the data corresponding to the passed
        # keys are persisted for the next request even if they would
        # otherwise have been cleared in this request.
        my variable _transients
        foreach arg $args {
            # Remove all occurences of the key
            set _transients [lsearch -all -inline -not -exact $_transients]
        }
    }
                
    method transient args {
        # Stores data in the flash only for the current request.
        # args - list of key value pairs to store in the flash
        # Normally, data stored in the flash is maintained until
        # the next request. However, data stored using -transient
        # is cleared after the current request.

        my variable _transients
        my set {*}$args
        foreach {key val} $args {
            lappend _transients $key
        }
    }

    method persistents {} {
        # Get all persistent keys stored in the flash.
        #
        # Returns all keys and values in the flash that will
        # be maintained until the next request.
        my variable _transients
        set persistents {}
        foreach {key val} [my get] {
            if {$key ni $_transients} {
                lappend persistents $key $val
            }
        }
        return $persistents
    }

    export keep persistents transient
}


#
# The main Controller object, all the action happens here
catch {Controller destroy}; # To allow resourcing
oo::class create Controller {
    variable _output_done _dispatchinfo

    constructor {request response dispatchinfo} {
        # Base class for Woof controller classes.
        # request - the Request object encapsulating the client's request
        # response - the Response object that will be used to hold the
        #  response to be sent to the client
        # dispatchinfo - a dictionary containing the items returned by
        #  woof::url_crack for the request
        #
        # This is the base class from which all application specific 
        # controller objects derive the standard functionality implemented
        # by the process method. However, applications should derive
        # controllers from the ApplicationController class and not directly
        # from Controller. Any application-wide changes should be defined
        # in that class and not by modifying this class.

        namespace import ::woof::config \
            ::woof::show_page_not_found \
            ::woof::log \
            ::woof::util::hesc \
            ::woof::errors::exception

        # Used for saving/discarding flash
        my variable _clear_flash_on_return

        # TBD - check if we could use namespace path instead of the below
        namespace import $request $response; # Imports request and response as a command

        set ns [self namespace]
        interp alias {} ${ns}::env {} $request env
        interp alias {} ${ns}::icookies {} $request cookies
        interp alias {} ${ns}::params {} $request params
        interp alias {} ${ns}::headers {} $response headers
        interp alias {} ${ns}::ocookies {} $response cookies

        set _dispatchinfo $dispatchinfo

        set _output_done false

        #ruff
        # Before invoking the controller action, an object 'session'
        # of class Session is created. This
        # may correspond to an existing session or a new session if
        # the request has missing or invalid session information. Application
        # code can use this object to store persistent data.

        # TBD - should this be here or in the dispatch code?
        if {[icookies exists $::woof::session_key_name sid]} {
            try {
                ::woof::Session create session $sid \
                    -id_name $::woof::session_key_name \
                    -dir [config get session_dir]
            } on error msg {
                # Could not get session information
                ::woof::log err "Could not retrieve session information for session $sid (Error: $msg). Creating new session."
                unset sid;          # Force new session below
                # Delete input session cookie. But cannot since it's frozen.
                # Should we unfreeze and delete frozen cookies?
                # TBD - document that input cookies should not be
                # relied on for session info
                #icookies -unset $::woof::session_key_name
            }
        }

        if {![info exists sid]} {
            # Need a new session
            ::woof::Session create session "" \
                -id_name $::woof::session_key_name \
                -dir [config get session_dir]
        }

        #ruff
        # Also before invoking the controller action, a Flash object
        # is created containing context and data to be shared
        # between consecutive requests. This can be accessed through
        # the 'flash' object.
        ::woof::Flash create flash
        if {[session exists _flash content]} {
            set _clear_flash_on_return 1
            flash transient {*}$content
        } else {
            set _clear_flash_on_return 0
        }

        # TBD - should the ACCEPT_LANGUAGE outcome be stored somewhere
        # so controller methods can also access without recomputation?
        # In fact, compute the intersection of client requirements
        # and application supported and store that.

        #ruff
        # A Page object 'page' is created to track contents of the page
        # and the list of languages specified in the Accept-Language HTTP
        # header is passed to it.
        ::woof::Page create page $_dispatchinfo \
            -languages [::woof::util::memoize \
                            ::woof::util::http_sorted_header_values \
                            [env get HTTP_ACCEPT_LANGUAGE {}]]

        #ruff
        # The Map object 'pagevar' is created to pass values related
        # to page metadata such as stylesheets, scripts, page titles
        # etc. Concrete controller classes may add to this.
        ::woof::util::Map create pagevar {
            styles {}
        }

    }

    method process {{action ""}} {
        # Called to invoke a specific action in a controller.
        # action - the name of the action method to invoke. If specified as
        #          an empty string, the method name is picked from the
        #          URL of the request.
        #
        my variable _clear_flash_on_return

        if {$action eq ""} {
            # Note - error raised if _dispatchinfo also does not have this
            set action [dict get $_dispatchinfo action]
        }
        #ruff
        # By default, $action may refer to any exported method defined in the 
        # controller leaf class itself (i.e. not including inherited methods).
        # A controller may define the method _action_methods
        # to return a non-empty list of methods to restrict this. In this
        # case, only those methods which are in the returned list are allowed
        # to be invoked.
        if {[llength [set allowed_methods [my _action_methods]]] == 0} {
            # We want a list of all exported methods for the leaf class
            # Note we use [info object class [self]] as opposed to
            # [self class] as the latter will return this class as
            # opposed to the leaf class. Also, we leave off -all
            # and -private as we only want exported methods and
            # only those directly defined in the leaf.
            set allowed_methods [info class methods [info object class [self]]]
        }

        if {$action ni $allowed_methods} {
            #ruff
            # If the action method does not exist or is inaccessible,
            # the method _missing_action is invoked and passed the action
            # as an argument. The default implementation of this returns
            # an error message to the user. A controller may override
            # this to provide dynamic functionality.
            my _missing_action $action
        } else {
            #ruff
            # The specific action is then invoked. If it has arguments,
            # they are extracted from the query parameters in the array
            # and passed as parameters to the action method.

            set formal_params [lindex [info class definition [info object class [self]] $action] 0]
            if {[llength $formal_params] == 0} {
                my $action
            } else {
                array set request_vals [params get]; # What the request gave us
                set param_vals {}
                foreach param $formal_params {
                    set param_name [lindex $param 0]
                    if {[info exists request_vals($param_name)]} {
                        lappend param_vals $request_vals($param_name)
                        unset request_vals($param_name)
                    } else {
                        # Not in request. See if there is a default
                        if {[llength $param] > 1} {
                            lappend param_vals [lindex $param 1]
                        } else {
                            # See if "args"
                            # This logic is not quite right in that it does not
                            # catch application errors if args is not
                            # the last parameter but what the heck ...
                            if {$param_name eq "args"} {
                                set append_args true
                            } else {
                                # TBD - log error with url and missing parameter name
                                exception WOOF_USER InvalidRequestParams
                            }
                        }
                    }
                }
                if {[info exists append_args]} {
                    # If the method has optional args, append all remaining params
                    my $action {*}$param_vals {*}[array get request_vals]
                } else {
                    my $action {*}$param_vals
                }
            }
        }
        if {! $_output_done} {
            #ruff
            # After the action completes, if the page has not been rendered
            # the render method is called to do so.
            my render
        }
        
        #ruff
        # Finally, any changes to the session are committed before
        # the command returns.

        # Commit what flash contents that need to be persisted
        set flash_content [flash persistents]
        if {[llength $flash_content]} {
            session set _flash $flash_content
        } else {
            # We use _clear_flash_on_return as a flag so we do not
            # needlessly dirty the session data causing an unnecessary
            # session commit.
            if {$_clear_flash_on_return} {
                session unset _flash
            }
        }

        # TBD - provide a way for apps to not commit the session data
        if {[session dirty?]} {
            session commit
            if {[session new?]} {
                #ruff
                # The session identifier for a new session, if created, is
                # automatically stored in the cookies set in the
                # client. Note this is only done when a new session is
                # created. For existing sessions the cookie is already
                # present on the client anyway.
                ocookies setwithattr \
                    $::woof::session_key_name [session get $::woof::session_key_name] \
                    path [config get url_root]
            }
        }
    }

    method url_for args {
        # Constructs a URL based on the passed options and current
        # request.
        # -protocol PROTOCOL - specifies the protocol component
        # -host HOST - specifies the host component
        # -port PORT - specifies the port component
        # -controller CONTROLLER - specifies the controller for
        #  the URL
        # -action ACTION - specifies the action method for the URL. If
        #  this option is not specified, but the -controller is, then this
        #  defaults to the application default action.
        # -module MODULE - specifies the module in which the
        #  controller is defined
        # -anchor ANCHOR - specifies the anchor to be included in the URL
        # -query QUERYLIST - specifies the query component of the URL. This
        #  should be specified as a key value list.
        # -urlpath URLPATH - specifies the URL portion after the protocol and 
        #  host components. Specifying this will cause all other URL related
        #  options to be ignored except -protocol, -host and -port.
        #  If URLPATH begins with '/', it is taken to be the entire URL
        #  after the host and port. Otherwise, it is assumed to be relative
        #  to the application's root URL.

        if {[dict exists $args -urlpath]} {
            set url [dict get $args -urlpath]
            if {[string index $url 0] ne "/"} {
                set url [file join [::woof::config url_root] $url]
            }
        } else {
            set modifiers {}
            if {[dict exists $args -controller]} {
                lappend modifiers -controller [dict get $args -controller]
                if {![dict exists $args -action]} {
                    # If action is not defined, but the controller is,
                    # we stick in the default action.
                    lappend modifiers -action \
                        [config get app_default_action index]
                }
            }

            if {[dict exists $args -action]} {
                lappend modifiers -action [dict get $args -action]
            }

            if {[dict exists $args -module]} {
                set module [split [string map {:: " "} [dict get $args -module]] " "]
                lappend modifiers -module $module
            }

            set url [::woof::url_build $_dispatchinfo {*}$modifiers]
        }

        if {[dict exists $args -anchor]} {
            set anchor #[dict get $args -anchor]
        } else {
            set anchor ""
        }

        if {[dict exists $args -query]} {
            set query {}
            foreach {k val} [dict get $args -query] {
                lappend query $k=$val
            }
            # TBD - should we not encode k and val separately. Else "=" might
            # also get encoded
            set query ?[::woof::url_encode [join $query " "]]
        } else {
            set query ""
        }

        set url "$url$anchor$query"

        # If protocol, host and port are unspecified, return the relative URL
        if {![dict exists $args -protocol] &&
            ![dict exists $args -host] &&
            ![dict exists $args -port]} {
            return $url
        }

        if {[dict exists $args -protocol]} {
            set protocol [dict get $args -protocol]
        } else {
            set protocol http
        }

        if {[dict exists $args -host]} {
            set host_port [dict get $args -host]
            if {$host_port eq ""} {
                # Caller specified empty host. Use default from request
                set host_port [request host]
            }
            if {[dict exists $args -port]} {
                # Port is also specified. Note that when port is not specified
                # we do NOT use the port that came in with the request. This
                # is intentional.
                append host_port ":[dict get $args -port]"
            }
        } elseif {[dict exists $args -port]} {
            # Host is not specified but port is. Use the host from
            # the current request.
            set host_port "[request host]:[dict get $args -port]"
        } else {
            # Neither host nor port specified. Use defaults from current
            # request. (Note this case is when -protocol was specified
            # so we could not return a simple relative URL above.
            set host_port [request formatted_host_with_port]
        }

        # TBD - does entire url need to be encoded or only pieces? 
        # Right now we encode only query above
        # TBD - Moreover who does the HTML encoding in actual hrefs?
        # TBD - does anchor come before/after query?
        return set url "$protocol://$host_port$url"
    }

    method render {} {
        # Generates content for the web page.
        #
        # Generates html fragments for all page sections in a web page.
        # The Page class object 'page' holds the content for each page section.
        # Refer to its documentation for more details.
        #

        # NOTE:
        # We do not want to pollute the template namespace with variable
        # names so all local variables in this method should begin with an "_".
        # The page template code should not use variables with "_"
        # by convention.

        #ruff
        # It is an error to call this method more than once or after
        # calling the redirect method.
        if {$_output_done} {
            exception WOOF MultipleRenders
        }

        # The page get layout will result in execution of the template
        # processing code in this context. We want to make
        # all instance variables visible to rendering code without additional
        # declarations in the templates. TBD - do we really want to make
        # them visible? Inadvertent name clashes may occur. Also performance?
        my variable {*}[info object vars [self]]
        if {[page fetch layout content -alias [pagevar get section_layout_alias ""]]} {
            response content $content
            response content_type [page content_type]
        } else {
            exception WOOF MissingTemplate "No layout template found for controller [dict get $_dispatchinfo controller], action [dict get $_dispatchinfo action]."
        }

        set _output_done true
    }

    method make_resource_links {resources type} {
        # Constructs link tags corresponding to the given resource files.
        # resources - nested list of pairs containing the resource locations
        # type - one of "stylesheet", "script"
        # Returns the HTML containing the links tags for the resources.

        # Search path for resource
        set dirs [dict get $_dispatchinfo search_dirs]
        set links {}
        switch -exact -- $type {
            stylesheet {
                set subdir stylesheets
            }
            javascript {
                set subdir js
            }
            default {
                ::woof::errors::exception "Unknown resource type '$type'."
            }
        }
        foreach pair $resources {
            #ruff
            # A resource may be a URL or a file. Each pair in $resources
            # consists of a format field followed by the location.
            #
            # If the format field is 'url', the location field is
            # used directly as the target for the link tag.
            #
            # If the format field is 'relativeurl', it is taken to be a
            # relative url below the root URL.
            # 
            # If the format field is 'file', it is taken to be
            # the name of a file which is searched for in the search
            # directory path for the controller under the public
            # directory under the Woof root. The corresponding
            # URL is used as the target for the link tag.
            lassign $pair format loc
            switch -exact -- $format {
                file {
                    set path [::woof::filecache_locate $loc \
                                  -dirs $dirs \
                                  -relativeroot [file join \
                                                     [config get public_dir] \
                                                     $subdir] \
                                 ]
                    if {$path ne ""} {
                        set loc [my url_for -urlpath [::woof::url_for_file $path $loc]]
                    } else {
                        exception WOOF MissingFile "Stylesheet $loc not found."
                    }
                }
                relativeurl {
                    set loc [file join [config get url_root] $loc]
                }
                url {
                    # Take as is
                }
                default {
                    exception WOOF Bug "Unknown resource link format '$format'."
                }
            }
            if {$type eq "javascript"} {
                lappend links "<script type='text/javascript' href='[hesc $loc]' />"
            } else {
                lappend links "<link rel='stylesheet' type='text/css' href='[hesc $loc]' />"
            }
        }
        return [join $links \n]
    }

    method make_style_links {styles} {
        # Constructs link tags corresponding to the given styles
        # styles - nested list of pairs containing the style locations
        # Returns the HTML containing the links tags for the style.
        # This is a wrapper around make_resource_links for stylesheet
        # resources. Refer to that method for details.
        return [my make_resource_links $styles stylesheet]
    }

    method make_javascript_links {scripts} {
        # Constructs link tags corresponding to the given scripts
        # scripts - nested list of pairs containing the script locations
        # Returns the HTML containing the script tags linking to the scripts.
        # This is a wrapper around make_resource_links
        # resources. Refer to that method for details.
        return [my make_resource_links $scripts javascript]
    }

    method redirect {args} {
        # Redirects client to a different URL.
        #
        # The arguments are constructed into a URL as described for the 
        # url_for method and the client is sent a HTTP redirect response
        # directing it to the constructed URL.
        #
        # This method and render are mutually exclusive. Both cannot be
        # called during processing of a single request.

        #ruff
        # -text STRING - the text to send as the response content.
        # -httpstatus HTTPSTATUSCODE - the HTTP response code to be sent to
        #  the client.
        array set opts {
            -text ""
            -httpstatus 307
        }
        array set opts $args

        if {$_output_done} {
            exception WOOF MultipleRenders
        }

        set text $opts(-text)
        set httpstatus $opts(-httpstatus)
        # Unset because we will pass whole array to url_for below
        unset opts(-text)
        unset opts(-httpstatus)

        if {[info exists opts(-url)]} {
            #ruff
            # -url URL - specifies the redirection URL.
            #  Specifying this option will cause all other URL
            #  related options to be ignored.
            set url $opts(-url)
        } else {
            #ruff
            # -protocol PROTOCOL - specifies the protocol component
            # -host HOST - specifies the host component
            # -port PORT - specifies the port component
            # -controller CONTROLLER - specifies the controller for
            #  the URL
            # -action ACTION - specifies the action method for the URL
            # -module MODULE - specifies the module in which the
            #  controller is defined
            # -anchor ANCHOR - specifies the anchor to be included in the URL
            # -query QUERYLIST - specifies the query component of the URL. This
            #  should be specified as a key value list.
            # 
            set url [my url_for {*}[array get opts]]
        }

        # TBD - what about cookies, other headers ?
        response redirect $url $httpstatus $text
        
        set _output_done true

        # TBD - what should happen to the session, flash and headers etc when
        # redirecting ? Should we clear them?
    }


    method _action_methods {} {
        # Returns a list of allowed actions.
        #
        # The actual derived class can override this if it wants to
        # restrict allowed actions
        # Empty list signifies all exported methods are actionable.
        return {}
    }

    method _missing_action {action} {
        # Called if there is no method defined for $action.
        #
        # The actual derived class can override this. By default
        # an error page is returned to the user.
        ::woof::log err "Action '$action' not defined for controller [self]"
        exception WOOF_USER InvalidRequest
    }
}

################################################################
#
# Defines mixin classes to modify controller behaviours

catch {DevModeOnly destroy}; # To allow resourcing
oo::class create DevModeOnly {
    constructor {request response dispatchinfo args} {
        if {[::woof::config get run_mode] ne "development"} {
            ::woof::log err "Request is not allowed except in development mode"
            ::woof::errors::exception WOOF_USER InvalidRequest
        }
        next $request $response $dispatchinfo {*}$args
    }
}

catch {LocalClientOnly destroy}; # To allow resourcing
oo::class create LocalClientOnly {
    constructor {request response dispatchinfo args} {
        if {[$request remote_addr] ne "127.0.0.1"} {
            ::woof::errors::exception WOOF_USER InvalidRequest "Request received for local URL [$request resource_url] from non-local client [$request remote_addr]."
        }
        next $request $response $dispatchinfo {*}$args
    }
}



namespace eval [namespace current] {
    ::woof::util::export_all
    namespace export Flash Controller
}
