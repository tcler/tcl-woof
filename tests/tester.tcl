# Main script for driving tests

package require tcltest


namespace eval ::woof::test {
    variable script_dir
    # We use the shortname to avoid quoting problems when exec'ing
    set script_dir [file attributes [file normalize [file dirname [info script]]] -shortname]

    variable outchan stdout
}

if {$::tcl_platform(platform) eq "windows"} {
    package require twapi
    proc ::woof::test::windows {} {return true}
} else {
    proc ::woof::test::windows {} {return false}
}

source testutil.tcl
source webserver_config.tcl

proc ::woof::test::run {args} {
    array set opts {
        -port 80
        -urlroot /
    }

    array set opts $args

    # Restart the web server
    progress "Restarting server $opts(-server)"
    ::woof::test::${opts(-server)}::stop
    ::woof::test::${opts(-server)}::start

    set ::env(WOOF_TEST_URLROOT) $opts(-urlroot)
    set ::env(WOOF_TEST_PORT)    $opts(-port)

    # Collect those options understood by the test package.
    set test_opts {}
    foreach opt [::tcltest::configure] {
        if {[info exists opts($opt)]} {
            lappend test_opts $opt $opts($opt)
        }
    }

    tcltest::configure {*}$test_opts

    tcltest::runAllTests

    progress "Stopping server $opts(-server)"
    ::woof::test::${opts(-server)}::stop
}


proc ::woof::test::progress {msg} {
    variable outchan
    puts $outchan $msg
}

proc ::woof::test::main {command args} {
    switch -exact -- $command {
        test {
            # After setting up the config,
            # the webserver_setup returns the actual option values used,
            # and we just pass them on to run_tests
            ::woof::test::run {*}[::woof::test::webserver_setup {*}$args]
        }
        config {
            ::woof::test::webserver_setup {*}$args
        }
        testonly {
            ::woof::test::run {*}$args
        }
    }
}

::woof::test::main {*}$::argv