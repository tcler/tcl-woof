# Main script for driving tests

source testutil.tcl

namespace eval ::woof::test {

    variable outchan stdout

    # Program/test run options
    variable config
    array set config {
        -scheme http
        -host 127.0.0.1
        -port   8015
        -interface direct
        -server wibble
        -webconfig default
        -urlroot /
    }
    set config(-woofdir) [clean_path [file join $script_dir ..]]
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

proc ::woof::test::usage {{msg {}}} {
    if {[string length $msg]} {
        puts stderr $msg
    }
    puts -nonewline stderr "Usage: [file tail [info nameofexecutable]] [info script] COMMAND ?OPTIONS?"
    puts -nonewline {
where COMMAND is one of the following (listed in order they are normally run)
        resetconfig - reset test configuration to defaults
        config      - write test configuration based on passed options
        prepare     - prepare environment for a test run, including 
                      configuring and starting web server
        run         - run tests
        cleanup     - shut down web server and clean up test environment
    }
    exit [string length $msg]
}

proc ::woof::test::main {args} {
    variable config
    variable script_dir

    set args [lassign $args command]
    if {$command ne "resetconfig"} {
        read_config
    }
    switch -exact -- $command {
        config -
        resetconfig {
            if {$command eq "config"} {
                array set config $args
            }
            set config(-woofdir) [clean_path $config(-woofdir)]
            if {[info exists config(-serverdir)]} {
                set config(-serverdir) [clean_path $config(-serverdir)]
            }

            save_config
        }
        prepare {
            setup_woof_config
            webserver_prepare
            webserver_start
        }
        cleanup {
            webserver_stop
        }
        test {
            ::woof::test::read_config
            ::woof::test::run {*}$args
        }
        "" -
        help {
            usage
        }
        default {
            usage "Invalid command '$command'"
        }
    }
}

::woof::test::main {*}$::argv
