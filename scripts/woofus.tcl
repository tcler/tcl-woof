# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof! Utility Script
# Utility for management of Woof! components and installations

if {! [package vsatisfies [info tclversion] 8.6]} {
    puts stderr "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
    error "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
}

namespace eval woofus {
    # Dir where woof is installed or when running as an installer
    # where the distribution resides
    variable root_dir
    if {[info exists ::env(WOOF_ROOT)]} {
        set root_dir $::env(WOOF_ROOT)
    } else {
        set root_dir [file normalize [file dirname [file dirname [info script]]]]
    }

    # Woof! version
    variable woof_version

    # Exit code for script
    variable exit_code 0
    
    # Text used as header in view template stubs
    variable view_stub_text "% # View stub for Woof!"
}

# Load the woof package - always expected to be relative to our parent dir
# so do not do a package require.
source [file join [file dirname [info script]] .. lib woof woof.tcl]
# The package require now gives us the woof version
set woofus::woof_version [package require woof]
namespace eval ::woof {
    source [file join [file dirname [info script]] .. lib woof configuration.tcl]
}


proc woofus::usage {{msg ""} {code ""}} {
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

    puts stderr "Usage:"
    # puts stderr "\t[info nameofexecutable] $argv0 stubs controller CONTROLLER_NAME..."
    puts stderr "\t[info nameofexecutable] $argv0 stubs url ?-excludeviews? URL ..."
    puts stderr "\t[info nameofexecutable] $argv0 stubs ?-excludeviews? verify ?URL ...?"

    exit $code
}

::woof::Configuration create ::config $woofus::root_dir

proc woofus::delta {controller_class controller file actions {view_dir ""}} {
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
        namespace eval ::woof::app [list source [file join [config :app_dir] controllers application_controller.tcl]]
        namespace eval ::woof::app [list source $file]

        # Check if the class exists
        if {[catch {info class methods ::woof::app::$controller_class} methods]} {
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

proc woofus::write_stubs {change} {

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
            puts $fd "oo::class create $controller_class {"
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
            puts $fd "\noo::define $controller_class {"
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

proc woofus::generate {urls args} {
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
            set view_root [file join [config get root_dir] [config get app_dir] controllers]
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
        set filepath [::fileutil::relative [config :root_dir] [dict get $change file]]
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

proc woofus::stub_check {path controller_class controller} {
    # Checks for stub methods in a controller
    # path - path to the file containing the controller class
    # controller_class - name of the controller class
    # controller - name of the controller

    # To find out whether the class/methods exist, we will source the file
    # into a ::woof::app namespace, just like Woof!

    variable view_stub_text

    namespace eval ::woof::app [list source [file join [config :app_dir] controllers application_controller.tcl]]
    namespace eval ::woof::app [list source $path]

    set view_dir [file join [file dirname $path] views]

    set stubs {}
    set views {}
    foreach name [info class methods ::woof::app::$controller_class] {
        # Ideally we would create the class and call the method to
        # see if it generates the appropriate exception. But we do not
        # have enough context to create an instance of the class so
        # we just do a string match.
        set body [info class definition ::woof::app::$controller_class $name]
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

proc woofus::verify {{urls {}} args} {
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
        set controller_dir [file join [config :app_dir] controllers]
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
            puts " Error: $msg"
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

proc woofus::stubs {command args} {
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

    # Woof commands require config and filecache
    #::woof::Configuration create ::woofus::config [file dirname [file normalize [file dirname [info script]]]]
    # ::woof::FileCache create ::filecache

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
            generate $args -excludeviews $opts(excludeviews)
        }
        verify {
            verify $args -excludeviews $opts(excludeviews)
        }
        default {
            error "Unknown subcommand '$command'"
        }
    }
}


################################################################
# Main routine

proc woofus::main {command args} {
    variable exit_code

    # Utility for managing Woof deployments and installations
    # command - the command to carry out, must be one of 'stubs',
    #  'distribute', or 'install'.
    # args - arguments specific to the command to be executed.
    #
    # The program invokes one of several different functions as
    # indicated by the $command parameter. Refer to the documentation
    # of the specific command for more information.

    if {[catch {
        switch -exact -- $command {
            stubs {
                woofus::$command {*}$args
            }
            install {
                puts stderr "Error: no such command. Please use the installer.tcl file for building distributions and installing."
            }
            default {
                usage "Unknown command '$command'"
            }
        }
    } msg]} {
        puts stderr "Error: $msg"
        set exit_code 1
    }

    return $exit_code
}


set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. lib]]]
::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. lib]]

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

# If we are not being included in another script, off and running we go
if {[file normalize $::argv0] eq [file normalize [info script]]} {
    woofus::main [lindex $argv 0] {*}[lrange $argv 1 end]
    exit $woofus::exit_code
}


