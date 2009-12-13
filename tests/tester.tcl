# Main script for driving tests

package require tcltest


namespace eval ::woof::test {
    variable script_dir
    # We use the shortname to avoid quoting problems when exec'ing
    set script_dir [file attributes [file normalize [file dirname [info script]]] -shortname]

    variable outchan stdout

    # Program/test run options
    variable popts
    array set popts {
        -interface cgi
        -server apache
        -port   80
        -config rewrite
        -urlroot /
    }
    set popts(-woofdir) [file join $script_dir ..]
    if {$::tcl_platform(platform) eq "windows"} {
        set popts(-serverdir) [file join $::env(ProgramFiles) "Apache Software Foundation" Apache2.2]
    } else {
        set opts(-serverdir) TBD
    }
}

if {$::tcl_platform(platform) eq "windows"} {
    package require twapi
    proc ::woof::test::windows {} {return true}
} else {
    proc ::woof::test::windows {} {return false}
}

source testutil.tcl
source webserver_config.tcl

proc ::woof::test::run {} {
    variable popts

    # Restart the web server
    progress "Restarting server $popts(-server)"
    ::woof::test::webserver_stop
    ::woof::test::webserver_start

    set ::env(WOOF_TEST_URLROOT) $popts(-urlroot)
    set ::env(WOOF_TEST_PORT)    $popts(-port)

    # Collect those options understood by the test package.
    set test_opts {}
    foreach opt [::tcltest::configure] {
        if {[info exists popts($opt)]} {
            lappend test_opts $opt $popts($opt)
        }
    }

    tcltest::configure {*}$test_opts

    tcltest::runAllTests

    progress "Stopping server $popts(-server)"
    ::woof::test::webserver_stop
}


proc ::woof::test::progress {msg} {
    variable outchan
    puts $outchan $msg
}

proc ::woof::test::main {command args} {
    variable popts

    array set popts $args
    set popts(-woofdir) [clean_path $popts(-woofdir)]
    set popts(-serverdir) [clean_path $popts(-serverdir)]
    switch -exact -- $command {
        test {
            # After setting up the config,
            # the webserver_setup returns the actual option values used,
            # and we just pass them on to run_tests

            ::woof::test::webserver_setup
            ::woof::test::run
        }
        config {
            ::woof::test::webserver_setup
        }
        testonly {
            ::woof::test::run
        }
    }
}

::woof::test::main {*}$::argv