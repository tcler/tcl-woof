# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof! Utility Script
# Utility for management of Woof! components and installations

if {! [package vsatisfies [info tclversion] 8.6]} {
    puts stderr "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
    error "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
}


# When this file is run, it needs to do its thing inside the Woof
# safe interpreter so the right context and packages are loaded.
if {[llength [info commands ::woof::source_file]] == 0} {
    # We are not inside the Woof interpreter. Create it and resource ourselves.
    namespace eval ::woof::webservers::wag {}
    namespace eval wag {
        variable winterp;       # Where Woof! is actually loaded (slave)
    }

    proc ::woof::webservers::wag::init {args} {
        # Called back from the Woof! master interpreter

        # The Woof! interp always needs a dummy webserver so we create one.
        catch {WebServer destroy}
        oo::class create WebServer {
            superclass ::woof::webservers::BaseWebServer
            method log {level msg} {
                puts stderr $msg
            }
        }
    }        

    proc wag::usage {{msg ""} {code ""}} {
        # Prints a usage description and exits
        # msg - optional message to print
        # code - exit code
    
        global argv0

        if {$code eq ""} {
            set code 1
        }

        if {$msg ne ""} {
            puts stderr $msg
        }

        set exe [file tail [info nameofexecutable]]
        if {$::tcl_platform(platform) eq "windows"} {
            set exe [file rootname $exe]
        }
        puts stderr "Usage:"
        puts stderr "\t$exe $argv0 url ?-excludeviews? ?URL ...?"
        puts stderr "\t$exe $argv0 controller ?-excludeviews? CONTROLLER_NAME ?ACTION ...?"
        puts stderr "\t$exe $argv0 verify ?-excludeviews? ?URL ...?"

        exit $code
    }

    if {[llength $::argv] == 0} {
        wag::usage
    }

    # Set up the Woof! slave interpreter
    source [file join [file dirname [info script]] .. lib woof master.tcl]
    # Init it, allowing access to the script directory
    set ::wag::winterp [::woof::master::init wag "" \
                            -jails [list [file dirname [info script]]]]

    # We need to expose certain hidden commands that are should not be
    # available when Woof! is running as a real web server
    $::wag::winterp expose open
    $::wag::winterp expose pwd
    $::wag::winterp expose cd
    $::wag::winterp expose glob
    $::wag::winterp alias ::wag::usage ::wag::usage
    interp share {} stdout $::wag::winterp
    interp share {} stderr $::wag::winterp
    interp share {} stdin $::wag::winterp
    $::wag::winterp alias file ::file

    # Source ourselves again inside the Woof! interpreter
    $::wag::winterp eval [list ::woof::source_file [info script]]

    # Now run the actual command
    if {[catch {
        set code [$::wag::winterp eval [list ::wag::main {*}$argv]]
    } msg]} {
        puts stderr $msg
        set code 1
    }

    # All done
    exit $code
}

# All code from this point on only runs inside the Woof! interpreter.

namespace eval wag {

    # Woof! version
    variable woof_version

    # Exit code for script
    variable exit_code 0
    
    # Text used as header in view template stubs
    variable view_stub_text "% # View stub for Woof!"
}


proc wag::delta {controller_class controller file actions {view_dir ""}} {
    # Generates change information for a controller class and action
    # controller_class - name of the controller class
    # controller - name of the controller as appears in the url
    # file - name of the file where implementation is expected
    # actions - list of names of actions/methods for which stubs need to
    #  be added.
    # view_dir - directory where views are expected to be stored. If
    #  empty, no view stubs are generated.
    #
    # Returns a dictionary containing the keys 'change_type',
    # 'controller_class', 'file' and 'actions'.
    #
    # The returned dictionary contains the following keys:
    #  change_type - one of 'none', 'file', 'controller_class', 'actions'
    #    'views' or 'error' indicating level of change
    #  controller_class - the $controller_class argument  that was passed in
    #  file - the $file argument  that was passed in
    #  actions - a list of actions/methods from $actions that are missing
    #    and need to be added.
    #  view_stubs - a list of view file stubs to be added.

    set view_stubs {}
    if {$view_dir ne ""} {
        foreach action $actions {
            set view_stub [file join $view_dir ${controller}-${action}-main.wtf]
            if {![file exists $view_stub]} {
                lappend view_stubs $view_stub
            }
        }
    }

    set change [dict create change_type file \
                    controller_class $controller_class \
                    file $file \
                    view_stubs $view_stubs \
                    actions $actions]

    if {![file exists $file]} {
        # Even the file does not exist, need to create everything
        return $change
    }

    # To find out whether the class/methods exist, we will source the file
    # into a ::woof::app namespace, just like Woof!
    try {
        set controller_class ::woof::app::$controller_class
        namespace eval [namespace qualifiers $controller_class] {
            namespace path {::woof::app ::woof}
        }
        namespace eval ::woof::app [list ::woof::source_file [file join [::woof::config :app_dir] controllers application_controller.tcl]]
        namespace eval [namespace qualifiers $controller_class] [list ::woof::source_file $file]

        # Check if the class exists
        if {[catch {info class methods $controller_class} methods]} {
            # Class does not exist
            dict set change change_type class
        } else {
            # Class exists, check which actions/methods exist
            dict set change change_type actions
            set missing_actions {}
            foreach action $actions {
                if {$action ni $methods} {
                    lappend missing_actions $action
                }
            }
            dict set change actions $missing_actions
            if {[llength $missing_actions] == 0} {
                if {[llength $view_stubs] == 0} {
                    dict set change change_type none
                } else {
                    dict set change change_type views
                }
            }
        }
    } on error {msg eropts} {
        dict set change message $msg
        dict set change change_type error 
    }

    return $change
}

proc wag::write_stubs {change} {

    variable view_stub_text 

    set change_type [dict get $change change_type]
    if {$change_type in {none error}} {
        return
    }

    set cwd [pwd]
    set path [dict get $change file]
    file mkdir [file dirname $path]
    set fd [open $path a]
    try {
        set controller_class [dict get $change controller_class]
        if {$change_type in {file class}} {
            if {$change_type eq "class"} {
                puts $fd "";    # Just create a separating newline
            } else {
                puts "Created file [::fileutil::stripPath $cwd $path]"
            }
            puts $fd "oo::class create [namespace tail $controller_class] {"
            puts $fd "    superclass ApplicationController"
            puts $fd "    constructor args {"
            puts $fd "        # Very important to pass arguments to parent"
            puts $fd "        next {*}\$args"
            puts $fd "    }"
            puts $fd "}"
            puts "Created class $controller_class."
        }

        set actions [dict get $change actions]
        if {[llength $actions]} {
            puts $fd "\noo::define [namespace tail $controller_class] {"
            foreach action $actions {
                puts $fd "    method $action {} {"
                puts $fd "        # Raise an exception that allows woofer to detect unimplemented actions"
                puts $fd "        ::woof::errors::exception WOOF NotImplemented \"Action $action has no supporting implementation.\""
                puts $fd "    }"
                puts "Created action ${controller_class}.$action."
            }
            puts $fd "}"
        }

    } finally {
        close $fd
    }

    
    foreach view_stub [dict get $change view_stubs] {
        if {![file exists $view_stub]} {
            lassign [split [file rootname [file tail $view_stub]] -] controller action section
            set text $view_stub_text
            append text "\n% # Replace the contents of this file with the template for the\n"
            append text "% # $section page section of the $action action of the\n"
            append text "% # $controller controller."
            ::fileutil::writeFile $view_stub $text
            puts "Created view [::fileutil::stripPath $cwd $view_stub]."
        }
    }

    return
}

proc wag::generate {urls args} {
    # Generates the code corresponding to specified URLs
    # urls - list of URLs for which code is to be generated
    # -excludeviews BOOLEAN - if true, view stubs are also generated
    # For each item in $urls, the stubs for the controller, action and
    # view are generated after prompting the user for confirmation.
    set opts(-excludeviews) false
    array set opts $args

    set cracked_urls {}
    foreach url $urls {
        lappend cracked_urls [::woof::url_crack $url]
    }

    # Arrange URLs by controller
    set controllers [dict create]
    foreach curl $cracked_urls {
        set controller_class [dict get $curl controller_class]
        set controller [dict get $curl controller]
        set controller_file [file join [dict get $curl controller_dir] [dict get $curl controller_file]]
        dict set controllers $controller_class controller $controller
        dict set controllers $controller_class file $controller_file
        set action [dict get $curl action]
        if {[dict exists $controllers $controller_class actions]} {
            set actions [dict get $controllers $controller_class actions]
            if {[lsearch -exact $actions $action] < 0} {
                lappend actions $action
            }
        } else {
            set actions [list $action]
        }
        dict set controllers $controller_class actions $actions
        set view_dir ""
        if {! $opts(-excludeviews)} {
            # Views are generated in the first directory in view search path
            set view_root [file join [::woof::config get root_dir] [::woof::config get app_dir] controllers]
            set view_dir [file normalize \
                              [file join $view_root \
                                   [lindex [dict get $curl search_dirs] 0] \
                                   views]]

        }
        dict set controllers $controller_class view_dir $view_dir
    }

    set changes {}
    dict for {controller_class value} $controllers {
        lappend changes [delta $controller_class \
                             [dict get $value controller] \
                             [dict get $value file] \
                             [dict get $value actions] \
                             [dict get $value view_dir]]
    }

    set need_stubs false
    foreach change $changes {
        set controller_class [dict get $change controller_class]
        set header "Controller $controller_class"
        set spacer "\t"
        set change_type [dict get $change change_type]

        if {$change_type eq "error"} {
            puts "$header:"
            puts "$spacer Skipping due to following error: [dict get $change message]"
            continue
        }

        if {$change_type eq "none"} {
            puts "$header"
            puts "$spacer No change."
            continue
        }

        set need_stubs true;    # Need at least one stub

        puts "$header:"
        set filepath [::fileutil::relative [::woof::config :root_dir] [dict get $change file]]
        switch -exact -- $change_type {
            file {
                puts "$spacer File $filepath will be created."
                puts "$spacer Class $controller_class will be created."
                puts "$spacer Methods to be added: [join [dict get $change actions] {, }]."
            }
            class {
                puts "$spacer File $filepath will be modified."
                puts "$spacer Class $controller_class will be created."
                puts "$spacer Methods to be added: [join [dict get $change actions] {, }]."
            }
            actions {
                puts "$spacer File $filepath will be modified."
                puts "$spacer Class $controller_class will be modified."
                puts "$spacer Methods to be added: [join [dict get $change actions] {, }]."
            }
            views {
                # No file, class or action changes
            }
            default {
                error "Unexpected change type '$change_type'"
            }
        }
        set view_stubs [dict get $change view_stubs]
        if {[llength $view_stubs]} {
            set cwd [pwd]
            puts "$spacer View stubs to be added:"
            foreach view_stub $view_stubs {
                puts "${spacer}${spacer}[::fileutil::stripPath $cwd $view_stub]"
            }
        } else {
            puts "$spacer View stubs to be added: none."
        }
    }

    if {$need_stubs} {
        puts -nonewline "Do you want to continue? \[YN] "
        flush stdout
        set answer [gets stdin]
        if {[string toupper $answer] ne "Y"} {
            return
        }

        foreach change $changes {
            write_stubs $change
        }
    } else {
        puts "\nNo stubs need to be generated."
    }

    return
}

proc wag::stub_check {path controller_class controller} {
    # Checks for stub methods in a controller
    # path - path to the file containing the controller class
    # controller_class - name of the controller class
    # controller - name of the controller

    # To find out whether the class/methods exist, we will source the file
    # into a ::woof::app namespace, just like Woof!

    variable view_stub_text

    namespace eval ::woof::app [list ::woof::source_file [file join [::woof::config :app_dir] controllers application_controller.tcl]]
    set controller_class ::woof::app::$controller_class
    namespace eval [namespace qualifiers $controller_class] {
        namespace path {::woof::app ::woof}
    }
    namespace eval [namespace qualifiers $controller_class] [list ::woof::source_file $path]

    set view_dir [file join [file dirname $path] views]

    set stubs {}
    set views {}
    foreach name [info class methods $controller_class] {
        # Ideally we would create the class and call the method to
        # see if it generates the appropriate exception. But we do not
        # have enough context to create an instance of the class so
        # we just do a string match.
        set body [info class definition $controller_class $name]
        if {[string match "*exception WOOF NotImplemented*" $body]} {
            lappend stubs $name
        }
        set view_file [file join $view_dir ${controller}-${name}-main.wtf]
        if {[file exists $view_file]} {
            set fd [open $view_file]
            set text [read $fd [string length $view_stub_text]]
            if {$text eq $view_stub_text} {
                lappend views $view_file
            }
        } else {
            lappend views $view_file
        }
    }
    

    # TBD - views not yet checked
    return [list $stubs $views]

}

proc wag::verify {{urls {}} args} {
    # Verifies that actions corresponding to URL's are implemented.
    # urls - list of urls to be verified. Only the controller portion
    #   of the URL's are relevant.
    #
    # If the list is empty, all controllers are checked to see
    # if they are stubs. Note that the actions specified by the URL
    # are ignored.
    variable exit_code

    # TBD - implement -excludeviews support
    set opts(-excludeviews) false
    array set opts $args

    set targets {}
    if {[llength $urls] == 0} {
        set controller_dir [file join [::woof::config :app_dir] controllers]
        foreach file [::fileutil::findByPattern $controller_dir -regexp {^.*_controller\.tcl$}] {
            set rel_file [::fileutil::relative $controller_dir $file]
            set controller [string range [file tail $file] 0 end-[string length "_controller.tcl"]]
            set module [lrange [split $rel_file /] 0 end-1]
            set controller_class [join [concat $module [list [woof::util::mixcase $controller]Controller]] ::]
            lappend targets [list $file $controller_class $controller]
        }
    } else {
        foreach url $urls {
            set curl [::woof::url_crack $url]
            set file [file join [dict get $curl controller_dir] [dict get $curl controller_file]]
            lappend targets [list $file [dict get $curl controller_class] [dict get $curl controller]]
        }
    }

    foreach target $targets {
        lassign $target file controller_class controller
        puts -nonewline "$controller_class:"
        if {[catch {
            lassign [stub_check $file $controller_class $controller] action_stubs view_stubs
        } msg]} {
            puts " Error: $msg\n$::errorInfo"
            set exit_code 1
            continue
        }
        if {[llength $action_stubs] == 0 && [llength $view_stubs] == 0} {
            puts " no stubs found."
            continue
        }
        if {[llength $action_stubs]} {
            puts "\n\tAction method stubs: \n\t\t[join $action_stubs \n\t\t]"
        }
        if {[llength $view_stubs]} {
            set cwd [pwd]
            puts "\n\tView stubs:"
            foreach view_stub $view_stubs {
                puts "\t\t[::fileutil::stripPath $cwd $view_stub]"
            }
        } else {
            puts "\tView stubs: none."
        }
    }

    return
}

proc wag::main {command args} {
    # Generates and manages stubs for Woof components.
    # command - one of 'controller', 'url', 'verify'
    # args - additional arguments to the command depending on $command
    #
    # When $command is 'controller', the next argument is
    # taken to be the name of a controller and remaining arguments are names
    # of actions and methods for the controller. The script will then
    # generate stubs for the corresponding controller, actions and
    # views if they do not already exist.
    #
    # When $command is 'url', the behaviour is similar except that the
    # remaining arguments are taken to be the URL's corresponding to
    # the controller and actions. Each argument is treated as an independent
    # URL. The script will then generate stubs for the controllers and
    # actions corresponding to these URL's.
    #
    # When $command is 'verify', the script verifies that stubs have been
    # implemented. If there are no additional arguments, the script
    # will verify that there are no unimplemented stubs in source. If
    # there are any arguments specified, they are treated as URL's and only
    # the corresponding paths are verified.

    variable exit_code

    set optdefs {
        {excludeviews "Specify to exclude view stubs when generating or verifying controllers and actions"}
    }
    array set opts [::cmdline::getKnownOptions args $optdefs "Usage: [info nameofexecutable] stubs \[controller|url|verify] ?OPTIONS? ?ARG1 ARG2 ...?"]

    switch -exact -- $command {
        controller {
            set actions [lassign $args controller]
            if {$controller eq ""} {
                usage "No controller name specified."
            }
            # Convert controller to URL format
            set controller [string map {:: /} $controller]
            if {[llength $actions] == 0} {
                set actions [list index]
            }
            set urls {}
            foreach action $actions {
                lappend urls [file join $controller $action]
            }
            generate $urls -excludeviews $opts(excludeviews) 
        }
        url {
            if {[llength $args] == 0} {
                usage "No URL's specified."
            }
            generate $args -excludeviews $opts(excludeviews)
        }
        verify {
            verify $args -excludeviews $opts(excludeviews)
        }
        default {
            error "Unknown subcommand '$command'"
        }
    }

    return $exit_code
}


if {[catch {
    package require cmdline
    package require fileutil
}]} {
    # For development purposes
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. thirdparty lib]]]
    ::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. thirdparty lib]]
    package require cmdline
    package require fileutil
}




