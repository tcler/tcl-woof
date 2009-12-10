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

        set template_map [list \
                              server_root $apache_root \
                              server_port $opts(-port) \
                              woof_root $woof_root \
                              url_root $opts(-urlroot)]

        set test_conf_dir [file join $::woof::test::script_dir apache]

        # Copy Apache test configuration
        copy_template \
            [file join $test_conf_dir httpd-${opts(-config)}.conf] \
            [file join $apache_root conf httpd.conf] \
            $template_map
        copy_template \
            [file join $test_conf_dir common.conf] \
            [file join $apache_root conf common.conf] \
            $template_map

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


proc ::woof::test::copy_template {from to map} {
    # Copy a template after replacing placeholders

    set fd [open $from r]
    set data [read $fd]
    close $fd

    # Substitute the content
    regsub -all -- {%SERVER_ROOT%} $data [dict get $map server_root] data
    regsub -all -- {%SERVER_PORT%} $data [dict get $map server_port] data
    regsub -all -- {%WOOF_ROOT%} $data [dict get $map woof_root] data
    if {[dict get $map url_root] eq "/"} {
        # Special case URL_ROOT=/ else we will land up with paths
        # like //stylesheets so replace such cases first and then
        # remaining %URL_ROOT%
        regsub -all -- {%URL_ROOT%/} $data / data
    }
    regsub -all -- {%URL_ROOT%} $data [dict get $map url_root] data

    # Assume if .sav exists, original already backed up
    if {![file exists ${to}.sav]} {
        file copy $to ${to}.sav
    }

    set fd [open $to w]
    puts $fd $data
    close $fd
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