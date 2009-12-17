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
    variable _context _sections

    constructor {dispatchinfo args} {
        # The Page object contains HTML content for page sections.
        # dispatchinfo - Dict containing request dispatch context as returned
        #   by url_split.
        # -languages LANGID_LIST - list of language identifiers in order 
        #   of preference. See the fetch method for details.
        #
        # Objects of this class are intended to be used as containers
        # to hold the HTML content of various sections in a page.
        # Content for a section can be directly stored or retrieved
        # using the store and fetch methods. If a particular section
        # has not been defined when an attempt is made to retrieve
        # it, the list of directories given by the search_dirs key
        # in the passed dispatch context is searched for a subdirectory
        # 'views' containing a suitable template from which
        # the section can be generated.

        set _context(dispatchinfo) $dispatchinfo

        set opts(-languages) {}
        array set opts $args

        set _context(languages) $opts(-languages)

        # TBD - what should default Content-Type be? Should there be a charset attr ?
        set _context(content_type) "text/html"

        array set _sections {}
    }

    method fetch {section_name varname args} {
        # Check the existence of a page section and optionally return its
        # content.
        # section_name - name of page section
        # varname - name of a variable in the caller's context
        # The method checks if the specified page section exists.
        # It returns false if the section does not exist.
        # If the section exists, the method returns true and
        # stores the value in the variable of
        # that name in the caller's context.
        #

        # -alias NAME - if specified and NAME is not empty, it
        #  is used as the name
        #  of the template file to be located along the search path instead
        #  of the constructed names described below.
        array set opts {-alias ""}
        array set opts $args

        #ruff
        # If the section has already been defined for the page, the method
        # returns true and the section content is stored in $varname if
        # specified.
        if {[info exists _sections($section_name)]} {
            if {$varname ne ""} {
                upvar $varname content
                set content $_sections($section_name)
            }
            return true
        }

        # We need to try and locate a template.

        # Control caching based on whether we are reloading templates
        # on every request.
        # TBD - if we are caching compiled templates, why cache files
        # as well and waste memory ?
        set cachecontrol [expr {[::woof::config get reload_templates false] ? "ignore" : "readwrite"}]

        #ruff
        # If the section has not been defined,
        # the view search path, as passed through the search_dirs field
        # in the dispatchinfo parameter in the constructor,
        # is searched for a matching template
        # for the controller and action.
        #
        # If no languages were specified when the object was created,
        # the search proceeds as follows:
        # For the first directory in the view search
        # path, the following file names are checked:
        # CONTROLLER-ACTION-PAGESECTION.wtf,
        # CONTROLLER-PAGESECTION.wtf, PAGESECTION.wtf.
        # For the remaining directories in the search path, only
        # PAGESECTION.wtf is
        # checked. This is by design since it does not make sense for
        # a file named after the controller and/or action to show
        # further up (and hence outside) the controller content
        # directory.
        #
        # Note the filename is considered a more important matching
        # criterion than the directory level.
        #
        # If the -languages option was specified when the object was
        # created, the above search is modified slightly. For each
        # directory in the search path, subdirectories with the same
        # name as the language identifiers specified in the option
        # are first checked before the directory in the search path.
        #

        # TBD - can we do just a lookup instead of getting content
        # if varname is empty? Probably not worth since content
        # will eventually be required anyways.

        set action          [dict get $_context(dispatchinfo) action]
        set search_dirs     [dict get $_context(dispatchinfo) search_dirs]
        set controller_name [dict get $_context(dispatchinfo) controller]

        if {$opts(-alias) ne ""} {
            set name $opts(-alias)
        } else {
            set name $section_name
        }

        # First check if a precompiled template has been cached.
        # Note - we to use the view_path as a lookup key since otherwise
        # the same controller name may occur in multiple modules. The view
        # path distinguishes between the modules as it will be different
        # for each. We also need to use the language list as the result
        # might differ based on the languages specified and their order.

        if {$cachecontrol eq "readwrite"} {
            # Lookup the filename cache first.
            # As as aside, note that by keeping two separate caches,
            # we save on memory space
            # since multiple controller/actions will map to the same filename
            if {[dict exists $::woof::template_file_paths $controller_name $action $search_dirs $name $_context(languages)]} {
                # Get the compiled template for the file name
                set tpath [dict get $::woof::template_file_paths $controller_name $action $search_dirs $name $_context(languages)]
                if {[info exists ::woof::compiled_templates($tpath)]} {
                    set ct $::woof::compiled_templates($tpath)
                }
            }
        }

        if {![info exists ct]} {
            # Compiled template not in cache for whatever reason. Locate it.
            # We try each possible location.
            
            # Note that we set cachecontrol to ignore in the calls to
            # filecache_locate since we are caching the compiled template,
            # there is no point caching the original template.
            set view_root [file join [::woof::config get root_dir] [::woof::config get app_dir] controllers]
            set tpath ""
            set default_lang [::woof::config get app_default_language]
            if {$opts(-alias) eq ""} {
                # First check for controller / action specific in the first dir
                # but only if alias was not specified
                set dir [file join [lindex $search_dirs 0] views]
                # Add language-specific subdirs first
                foreach lang $_context(languages) {
                    lappend dirs [file join $dir $lang]
                    if {$lang eq $default_lang} {
                        # The language that the default files correspond to.
                        lappend dirs $dir
                    }
                }
                # Add lang-independent last. May already be in list, no matter
                lappend dirs $dir
                set tpath [::woof::filecache_locate \
                               ${controller_name}-${action}-${name}.wtf \
                               -dirs $dirs \
                               -relativeroot $view_root \
                               -cachecontrol ignore]
                if {$tpath eq ""} {
                    # Not there, try controller-specific, action-independent one
                    set tpath [::woof::filecache_locate \
                                   ${controller_name}-${name}.wtf \
                                   -dirs $dirs \
                                   -relativeroot $view_root \
                                   -cachecontrol ignore]
                }
            }
            if {$tpath eq ""} {
                # Still not located, try along entire path
                set dirs {}
                foreach search_dir $search_dirs {
                    foreach lang $_context(languages) {
                        lappend dirs [file join $search_dir views $lang]
                    }
                    lappend dirs [file join $search_dir views]
                }
                set tpath [::woof::filecache_locate \
                               ${name}.wtf \
                               -dirs $dirs \
                               -relativeroot $view_root \
                               -cachecontrol ignore]
            }
                
            if {$tpath eq ""} {
                # No joy, no matching template
                return false
            }

            # Cache the filename
            dict set ::woof::template_file_paths $controller_name $action $search_dirs $name $_context(languages) $tpath

            # Compile the template and store it in the cache. We supply
            # a dynamically generated name as the output variable where
            # the output content will stored when the compiled template
            # is run. Note again, that cachecontrol for filecache_read
            # is hardcoded to ignore for reasons stated above.
            set ct [::woof::wtf::compile_template \
                        [::woof::filecache_read $tpath -cachecontrol ignore] \
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
        if {[llength $args]} {
            set _context(content_type) [lindex $args 0]
            return
        } else {
            return $_context(content_type)
        }
    }
}
