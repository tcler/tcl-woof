# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

namespace eval ::woof {
    # Templates are compiled and cached when first encountered.
    # Should really be a "common" variable in Page but don't know
    # how to do that, and not sure about performance impact
    variable compiled_template_cache
    set compiled_template_cache [dict create]

    # Used to generate variable names for holding template processed output
    variable template_output_counter 0
}

oo::class create Page {
    constructor {dispatchinfo} {
        # The Page object contains HTML content for page sections.
        # dispatchinfo - Dict containing request dispatch context as returned
        #   by url_split.
        # Objects of this class are intended to be used as containers
        # to hold the HTML content of various sections in a page.
        # Content for a section can be directly stored or retrieved
        # using the store and fetch methods. If a particular section
        # has not been defined when an attempt is made to retrieve
        # it, the list of directories given by the search_dirs key
        # in the passed dispatch context is searched for a subdirectory
        # 'views' containing a suitable template from which
        # the section can be generated.

        my variable _dispatchinfo _sections _content_type

        set _dispatchinfo $dispatchinfo

        # TBD - what should default Content-Type be? Should there be a charset attr ?
        set _content_type "text/html"

        array set _sections {}
    }

    method fetch {name {varname {}}} {
        # Check the existence of a page section and optionally return its
        # content.
        # name - name of page section
        # varname - name of a variable in the caller's context
        # The method checks if the specified page section exists.
        # It returns false if the section does not exist.
        # If the section exists, the method returns true and if
        # $varname is specified, stores the value in the variable of
        # that name in the caller's context.
        #

        my variable _dispatchinfo
        my variable _sections

        #ruff
        # If the section has already been defined for the page, the method
        # returns true and the section content is stored in $varname if
        # specified.
        if {[info exists _sections($name)]} {
            if {$varname ne ""} {
                upvar $varname content
                set content $_sections($name)
            }
            return true
        }

        # We need to try and locate a template.

        # Control caching based on whether we are reloading templates
        # on every request.
        set cachecontrol [expr {[::woof::config get reload_templates false] ? "ignore" : "readwrite"}]

        #ruff
        # If the section has not been defined,
        # the view search path is searched for a matching template
        # for the controller and action.
        #
        # For the first directory in the view search
        # path, the following file names are checked:
        # CONTROLLER-ACTION-PAGESECTION.wtf,
        # CONTROLLER-PAGESECTION.wtf, PAGESECTION.wtf.
        # For the remaining directories in the search path, only
        # PAGESECTION.wtf is
        # checked. This is by design since it does not make sense for
        # a file named after the controller and/or action to show up
        # further up (and hence outside) the controller content
        # directory.
        #
        # Note the filename is considered a more important matching
        # criterion than the directory level.

        # TBD - can we do just a lookup instead of getting content
        # if varname is empty? Probably not worth since content
        # will eventually be required anyways.

        # First check if a precompiled template has been cached.
        # Note - we to use the view_path as a lookup key since otherwise
        # the same controller name may occur in multiple modules. The view
        # path distinguishes between the modules as it will be different
        # for each.
        set action          [dict get $_dispatchinfo action]
        set search_dirs     [dict get $_dispatchinfo search_dirs]
        set controller_name [dict get $_dispatchinfo controller]
        if {$cachecontrol eq "readwrite" &&
            [dict exists $::woof::compiled_template_cache $controller_name $action $search_dirs $name]} {
            set ct [dict get $::woof::compiled_template_cache $controller_name $action $search_dirs $name]
        } else {
            # Not in cache, look for it. We try each possible location. On
            # a specific exception of WOOF MissingFile, we look in further
            # locations.
            set view_root [file join [::woof::config get root_dir] [::woof::config get app_dir] controllers]
            try {
                # First check for controller / action specific in the first dir
                set template [::woof::filecache_read \
                                  [file join $view_root [lindex $search_dirs 0] views \
                                       ${controller_name}-${action}-${name}.wtf] \
                                  -cachecontrol $cachecontrol]
            } trap {WOOF MissingFile} {} {
                try {
                    # No such file, try controller specific one
                    set template [::woof::filecache_read \
                                      [file join $view_root [lindex $search_dirs 0] views \
                                           ${controller_name}-${name}.wtf] \
                                      -cachecontrol $cachecontrol]
                } trap {WOOF MissingFile} {} {
                    # Still not located, try along entire path
                    try {
                        set template [::woof::filecache_read \
                                          [file join views ${name}.wtf] \
                                          -cachecontrol $cachecontrol \
                                          -dirs $search_dirs \
                                          -relativeroot $view_root]
                    } trap {WOOF MissingFile} {} {
                        # Will fall through below to return false
                    }
                }
            }

            if {! [info exists template]} {
                #ruff
                # If no suitable template is found, the method returns false.
                return false
            }

            # Compile the template and store it in the cache. We supply
            # a dynamically generated name as the output variable where
            # the output content will stored when the compiled template
            # is run.
            set ct [::woof::wtf::compile_template $template ::woof::template_output[incr ::woof::template_output_counter]]
            dict set ::woof::compiled_template_cache $controller_name $action $search_dirs $name $ct
        }

        #ruff
        # If a suitable template is found, the method returns true.
        # If $varname is specified, the template is rendered in the caller's
        # context and the result is stored in $varname and also
        # as the content of the page section internally.
        if {$varname ne ""} {
            # First element of compiled template is the output variable
            # name. Make sure we empty it
            set output_var_name [lindex $ct 0]
            set $output_var_name ""
            uplevel 1 [list ::woof::wtf::run_compiled_template $ct]
            set _sections($name) [set $output_var_name]
            set $output_var_name ""; # So as to release memory
            upvar $varname content
            set content $_sections($name)
        }
        return true
    }

    method store {name args} {
        # Sets the content of the specified section.
        # name - name of the section
        # args - list of arguments to be concatenated. The resulting value
        #  is stored as the content of the page section.
        # The content being stored is expected to be a properly formatted
        # HTML fragment.

        my variable _sections
        set _sections($name) [join $args ""]
        return
    }

    method content_type {args} {
        # Sets the content type of the page
        # args - optional arguments
        # If no arguments are specified, returns the current value
        # of the page content-type. Otherwise, sets its value
        # to the first argument and returns an empty string. Remaining
        # arguments, if any, are currently ignored. If the first argument
        # is the empty string, the Content-Type header is removed
        # from the response.
        #
        # The supplied value may contain a charset attribute as well.
        my variable _content_type
        if {[llength $args]} {
            set _content_type [lindex $args 0]
            return
        } else {
            return $_content_type
        }
    }
}
