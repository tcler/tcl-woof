# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

namespace eval ::woof {
    # Templates are compiled and cached when first encountered.
    # Should really be a "common" variable in Page but don't know
    # how to do that, and not sure about performance impact.
    # template_file_paths maps the controller/action/section to a file path.
    # compiled_templates is indexed by file path and contains
    # the corresponding compiled file contents.
    variable compiled_templates
    array set compiled_templates {}
    variable template_files
    set template_file_paths [dict create]

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

    method fetch {name varname args} {
        # Check the existence of a page section and optionally return its
        # content.
        # name - name of page section
        # varname - name of a variable in the caller's context
        # The method checks if the specified page section exists.
        # It returns false if the section does not exist.
        # If the section exists, the method returns true and
        # stores the value in the variable of
        # that name in the caller's context.
        #
        my variable _dispatchinfo
        my variable _sections

        array set opts $args

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

        #ruff
        # -filename FILENAME - if specified, FILENAME is used as the name
        #   of the template file to be located along the search path instead
        #   of the constructed names described above.

        if {$cachecontrol eq "readwrite"} {
            # Lookup the filename cache first.
            # As as aside, note that by keeping two separate caches, we save on memory space
            # since multiple controller/actions will map to the same filename
            if {[dict exists $::woof::template_file_paths $controller_name $action $search_dirs $name]} {
                # Get the compiled template for the file name
                set tpath [dict get $::woof::template_file_paths $controller_name $action $search_dirs $name]
                if {[info exists ::woof::compiled_templates($tpath)]} {
                    set ct $::woof::compiled_templates($tpath)
                }
            }
        }

        if {![info exists ct]} {
            # Compiled template not in cache for whatever reason. Locate it.
            # We try each possible location. On
            # a specific exception of WOOF MissingFile, we look in further
            # locations.
            set view_root [file join [::woof::config get root_dir] [::woof::config get app_dir] controllers]
            # First check for controller / action specific in the first dir
            set tpath [::woof::filecache_locate \
                           ${controller_name}-${action}-${name}.wtf \
                           [list [file join [lindex $search_dirs 0] views]] \
                           -relativeroot $view_root \
                           -cachecontrol $cachecontrol]
            if {$tpath eq ""} {
                # Not there, try controller-specific, action-independent one
                set tpath [::woof::filecache_locate \
                             ${controller_name}-${name}.wtf \
                             [list [file join [lindex $search_dirs 0] views]] \
                             -relativeroot $view_root \
                             -cachecontrol $cachecontrol]
                if {$tpath eq ""} {
                    # Still not located, try along entire path
                    set tpath [::woof::filecache_locate \
                                 [file join views ${name}.wtf] \
                                 $search_dirs \
                                 -relativeroot $view_root \
                                 -cachecontrol $cachecontrol]
                }
            }
                
            if {$tpath eq ""} {
                # No joy, no matching template
                return false
            }

            # Cache the filename
            dict set ::woof::template_file_paths $controller_name $action $search_dirs $name $tpath

            # Compile the template and store it in the cache. We supply
            # a dynamically generated name as the output variable where
            # the output content will stored when the compiled template
            # is run.
            set ct [::woof::wtf::compile_template \
                        [::woof::filecache_read $tpath -cachecontrol $cachecontrol] \
                        ::woof::template_output[incr ::woof::template_output_counter]]
            set ::woof::compiled_templates($tpath) $ct
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
