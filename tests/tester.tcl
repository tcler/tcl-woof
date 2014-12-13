# Main script for driving tests

package require tcltest
package require http
package require uri
source testutil.tcl
source webserver_config.tcl

namespace eval ::woof::test {

    variable outchan stdout

    # Program/test run options
    variable config
    array set config {
        -interface direct
        -server wibble
        -port   8015
        -webconfig default
        -urlroot /
    }
    set config(-woofdir) [file join $script_dir ..]
}

proc ::woof::test::run {args} {
    variable config

    # Restart the web server
    progress "Restarting server $config(-server)"
    ::woof::test::webserver_stop
    ::woof::test::webserver_start

    # Verify server is set up
    assert_server_running
    set ::env(WOOF_TEST_URLROOT) $config(-urlroot)
    set ::env(WOOF_TEST_PORT)    $config(-port)
    # Collect those options understood by the tcltest package.
    set test_opts {}
    foreach opt [::tcltest::configure] {
        if {[dict exists $args $opt]} {
            lappend test_opts $opt [dict get $args $opt]
        }
    }
    tcltest::configure {*}$test_opts
    try {
        tcltest::runAllTests
        progress "Stopping server $config(-server)"
    } finally {
        ::woof::test::webserver_stop
    }
}

proc ::woof::test::progress {msg} {
    variable outchan
    puts $outchan $msg
}

proc ::woof::test::main {command args} {
    variable config
    variable script_dir

    switch -exact -- $command {
        config -
        resetconfig {
            if {$command eq "config"} {
                unset -nocomplain config
            } else {
                ::woof::test::read_config
            }
            array set config $args
            set config(-woofdir) [clean_path $config(-woofdir)]
            if {[info exists config(-serverdir)]} {
                set config(-serverdir) [clean_path $config(-serverdir)]
            }

            save_config
        }
        test {
            ::woof::test::read_config
            ::woof::test::run {*}$args
        }
        default {
            error "Command must be on of 'config', 'resetconfig' or 'test'.
        }
    }
}

::woof::test::main {*}$::argv
