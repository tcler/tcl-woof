# Commands for setting up configurations

namespace eval ::woof::test {}
namespace eval ::woof::test::iis {}

################################################################
# Apache stuff
namespace eval ::woof::test::apache {
    variable apache_service_name
    set apache_service_name apache

    namespace path ::woof::test

    proc setup_config {} {
        # Set up the Apache configuration
        namespace upvar ::woof::test popts opts

        progress "Setting up Apache config: [array get opts]"

        set apache_root [clean_path $opts(-serverdir)]
        set woof_root [clean_path $opts(-woofdir)]

        set template_map [list \
                              server_root $apache_root \
                              server_port $opts(-port) \
                              woof_root $woof_root \
                              url_root $opts(-urlroot)]

        set test_conf_dir [file join $::woof::test::script_dir apache]

        # Copy Apache test configuration
        copy_template \
            [file join $test_conf_dir httpd-${opts(-interface)}-${opts(-config)}.conf] \
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
            exec -ignorestderr -- sudo /etc/init.d/apache2 start
        }
    }

    proc stop {} {
        variable apache_service_name
        if {$::tcl_platform(platform) eq "windows"} {
            if {![twapi::stop_service $apache_service_name -wait 10000]} {
                error "Could not stop service $apache_service_name"
            }
        } else {
            exec -ignorestderr -- sudo /etc/init.d/apache2 stop
        }
    }
}

################################################################
# IIS stuff

namespace eval ::woof::test::iis {
    variable iis_service_name
    set iis_service_name W3SVC

    namespace path ::woof::test

    proc setup_config {} {
        error "The test framework is not currently capable of setting up IIS. You must do it manually and then run the test scripts with the testonly command."

        # Set up the IIS configuration
        namespace upvar ::woof::test popts opts

        progress "Setting up IIS config: [array get opts]"

        set iis_root [clean_path $opts(-serverdir)]
        set woof_root [clean_path $opts(-woofdir)]

        if {$opts(-urlroot) eq "/"} {
            error "IIS testing does not currently support a configuration rooted at /"
        }

        reset_iis_config

        switch -exact -- $opts(-config) {
            rewrite {
                
            }
            transparent {
                set opts(-urlroot) $opts(-urlroot)/cgi_server.tcl
                TBD
            }
        }


        # Write the IIRF ini file

        set template_map [list \
                              server_root $iis_root \
                              server_port $opts(-port) \
                              woof_root $woof_root \
                              url_root $opts(-urlroot)]

        set test_conf_dir [file join $::woof::test::script_dir iis]

        # Copy Iis test configuration
        copy_template \
            [file join $test_conf_dir httpd-${opts(-interface)}-${opts(-config)}.conf] \
            [file join $iis_root conf httpd.conf] \
            $template_map
        copy_template \
            [file join $test_conf_dir common.conf] \
            [file join $iis_root conf common.conf] \
            $template_map

        # Set application.cfg to reflect URL root
        set fd [open [file join $woof_root config application.cfg] w]
        puts $fd "set url_root $opts(-urlroot)"
        close $fd

        return [array get opts]
    }

    proc start {} {
        variable iis_service_name
        if {![twapi::start_service $iis_service_name -wait 10000]} {
            error "Could not start service $iis_service_name"
        }
    }

    proc stop {} {
        variable iis_service_name
        if {![twapi::stop_service $iis_service_name -wait 10000]} {
            error "Could not stop service $iis_service_name"
        }
    }
}


################################################################
# Wibble stuff
namespace eval ::woof::test::wibble {

    namespace path ::woof::test

    proc setup_config {} {
        # Set up the wibble configuration
        namespace upvar ::woof::test popts opts

        progress "Setting up wibble config: [array get opts]"

        # Nothing to really do for wibble itself. 
        # All config is done at start time through the command line

        # Set application.cfg to reflect URL root
        set woof_root [clean_path $opts(-woofdir)]
        set fd [open [file join $woof_root config application.cfg] w]
        puts $fd "set url_root $opts(-urlroot)"
        close $fd

        return [array get opts]
    }

    proc start {} {
        variable wibble_pid
        namespace upvar ::woof::test popts opts
        
        if {[info exists wibble_pid] && [process_exists $wibble_pid]} {
            return
        }

        unset -nocomplain wibble_pid;             # In case exec fails
        set wibble_pid [exec [info nameofexecutable] [clean_path [file join $opts(-woofdir) lib woof webservers wibble_server.tcl]] -urlroot $opts(-urlroot) -port $opts(-port) &]
        # Wait for it to start before returning
        after 10
    }

    proc stop {} {
        variable wibble_pid

        if {[info exists wibble_pid]} {
            ::twapi::end_process $wibble_pid -force true
            unset wibble_pid
        }
    }
}

################################################################
# General routines

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

proc ::woof::test::webserver_setup {} {
    variable script_dir
    variable popts

    # Sets up the specified server configuration
    if {$popts(-server) ni {apache iis wibble}} {
        error "Server $options(-server) not supported."
    }

    # Installs Woof! "in-place" within $woof_dir
    if {$popts(-server) ni {bowwow wibble}} {
        exec [info nameofexecutable] [file join $popts(-woofdir) scripts installer.tcl] install $popts(-server) $popts(-interface)
    }

    return [::woof::test::${popts(-server)}::setup_config]
}

proc ::woof::test::webserver_start {} {
    variable script_dir
    variable popts

    if {$popts(-interface) eq "scgi"} {
        start_scgi_process
    }
    ::woof::test::${popts(-server)}::start
}

proc ::woof::test::webserver_stop {args} {
    variable script_dir
    variable popts

    ::woof::test::${popts(-server)}::stop
    if {$popts(-interface) eq "scgi"} {
        stop_scgi_process
    }
}