# Commands for setting up configurations

namespace eval ::woof::test {}
namespace eval ::woof::test::iis {}

namespace eval ::woof::test::apache {
    variable apache_service_name
    set apache_service_name apache

    namespace path ::woof::test

    proc setup_config {args} {
        # Set up the Apache configuration

        array set opts {
            -config cgi-dedicated
            -port 8080
            -urlroot /
        }
        if {[windows]} {
            set opts(-serverdir) [file join $::env(ProgramFiles) "Apache Software Foundation" Apache2.2]
        } else {
            set opts(-serverdir) TBD
        }
        set opts(-woofdir) [file join $::woof::test::script_dir ..]

        array set opts $args

        progress "Setting up Apache config: [array get opts]"

        set apache_root [file normalize $opts(-serverdir)]
        set woof_root [file normalize $opts(-woofdir)]

        set test_conf_dir [file join $::woof::test::script_dir apache]

        # Read in test configuration
        set test_conf [file join $test_conf_dir httpd-${opts(-config)}.conf]
        set fd [open $test_conf r]
        set conf_data [read $fd]
        close $fd

        # Substitute the config
        regsub -all -- {%SERVER_ROOT%} $conf_data $apache_root conf_data
        regsub -all -- {%SERVER_PORT%} $conf_data $opts(-port) conf_data
        regsub -all -- {%WOOF_ROOT%} $conf_data $woof_root conf_data
        regsub -all -- {%URL_ROOT%} $conf_data $opts(-urlroot) conf_data

        # Assume if .sav exists, original httpd.conf already backed up
        set httpd_conf [file join $apache_root conf httpd.conf]
        if {![file exists ${httpd_conf}.sav]} {
            file copy $httpd_conf ${httpd_conf}.sav
        }

        set fd [open $httpd_conf w]
        puts $fd $conf_data
        close $fd

        file copy -force [file join $test_conf_dir common.conf] [file join $apache_root conf common.conf]

        # Set application.cfg to reflect URL root
        set fd [open [file join $woof_root config application.cfg] w]
        puts $fd "set url_root $opts(-urlroot)"
        close $fd

        return [array get opts]
    }

    proc start {} {
        variable apache_service_name
        if {$::tcl_platform(platform) eq "windows"} {
            if {![twapi::start_service $apache_service_name -wait 10000]} {
                error "Could not start service $apache_service_name"
            }
        } else {
            error "apache_start not implemented on this platform"
        }
    }

    proc stop {} {
        variable apache_service_name
        if {$::tcl_platform(platform) eq "windows"} {
            if {![twapi::stop_service $apache_service_name -wait 10000]} {
                error "Could not stop service $apache_service_name"
            }
        } else {
            error "apache_stop not implemented on this platform"
        }
    }
}


proc ::woof::test::webserver_setup {args} {
    variable script_dir

    set opts(-server) apache
    set opts(-woofdir) [clean_path [file join $script_dir ..]]
    set opts(-interface) cgi

    array set opts $args

    # Sets up the specified server configuration
    if {$opts(-server) ni {apache iis}} {
        error "Server $opts(-server) not supported."
    }

    # Installs Woof! "in-place" within $woof_dir
    exec [info nameofexecutable] [file join $opts(-woofdir) scripts installer.tcl] install $opts(-server) $opts(-interface)

    return [::woof::test::${opts(-server)}::setup_config {*}[array get opts]]
}