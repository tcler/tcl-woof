# Commands for setting up configurations

package require registry

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
        namespace upvar ::woof::test config opts

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
    namespace path ::woof::test
    namespace upvar ::woof::test config config

    proc iisx_dir {} {
        foreach ver {8.1 8.0 7.5 7.0} {
            if {![catch {
                registry get HKEY_LOCAL_MACHINE\\software\\Microsoft\\iisexpress\\$ver InstallPath
            } dir]} {
                proc iisx_dir {} "[list return $dir]"
                tailcall iisx_dir
            }
        }

        error "Could not locate IIS Express directory"
    }

    proc config_path {} {
        set path [test_path temp iis config woofiisx.config]
        ensure_parent_dir $path
        proc config_path {} "[list return $path]"
        tailcall config_path
    }

    proc site_path {} {
        set path [test_path temp iis site]
        file mkdir $path
        proc site_path {} "[list return $path]"
        tailcall site_path
    }

    proc appcmd {args} {
        exec [file join [iisx_dir] appcmd.exe] {*}$args /apphostconfig:[clean_path [config_path]]
    }

    proc prepare {} {
        variable config

        if {$config(-urlroot) eq "/"} {
            error "IIS testing does not currently support a configuration rooted at /"
        }

        set public_dir [clean_path $config(-woofdir) public]

        file copy -force [file join $::env(USERPROFILE) Documents IISExpress config applicationhost.config] [config_path]

        # NOTE: When using IIS Express, bindings must specify localhost (not
        # even 127.0.0.1) and a port number > 1024 if not running with
        # elevated privs
        appcmd add site /name:WoofTestSite /bindings:http/*:$config(-port):localhost /physicalPath:[clean_path [site_path]]
        appcmd add vdir /app.name:WoofTestSite/ /path:$config(-urlroot) /physicalPath:$public_dir
        appcmd set config /section:system.webServer/handlers "-accessPolicy:Read, Execute, Script"

        if {$config(-interface) eq "scgi"} {
            if {$::env(PROCESSOR_ARCHITECTURE) eq "AMD64"} {
                set scgi_dll isapi_scgi64.dll
            } else {
                set scgi_dll isapi_scgi.dll
            }
            file copy -force [source_path thirdparty isapi_scgi $scgi_dll] $public_dir
            file copy -force [source_path thirdparty isapi_scgi isapi_scgi.ini] $public_dir
            copy_template [test_path iis web.config-scgi] [file join $public_dir web.config] [list isapi_dll $scgi_dll]
        }

        return
    }

    proc cleanup {} {
        variable config
        stop
        set public_dir [clean_path $config(-woofdir) public]
        if {$config(-interface) eq "scgi"} {
            file delete [file join $public_dir isapi_scgi.dll]
            file delete [file join $public_dir isapi_scgi64.dll]
            file delete [file join $public_dir isapi_scgi.ini]
        }
        file delete [file join $public_dir web.config]
        file delete -force [test_path temp iis]
    }

    proc start {} {
        variable config
        stop
        exec cmd /c start [clean_path [file join [iisx_dir] iisexpress.exe]] /site:WoofTestSite /config:[config_path] &
    }

    proc stop {} {
        catch {exec {*}[auto_execok taskkill] /IM iisexpress.exe}
    }
}


################################################################
# Wibble stuff
namespace eval ::woof::test::wibble {

    namespace path ::woof::test
    namespace upvar ::woof::test config config

    proc pidpath {} {
        return [test_path temp wibble wibble.pid]
    }

    proc prepare {} {
        variable config

        # Set up the wibble configuration

        progress "Setting up wibble config: [array get config]"

        # Nothing to really do for wibble itself. 
        # All config is done at start time through the command line
        # when starting wibble
    }

    proc cleanup {} {
        stop
        # Nothing else to do
    }

    proc start {} {
        variable config
        
        set pidfile [pidpath]

        if {[file exists $pidfile]} {
            set pid [read_file $pidfile]
            if {[process_exists $pid]} {
                # Cannot use the same process since config may be different
                error "Wibble seems to be already running with PID $pid. Please stop it first."
            }
        }

        set wibble_pid [exec [info nameofexecutable] [clean_path [file join $config(-woofdir) lib woof webservers wibble_server.tcl]] -urlroot $config(-urlroot) -port $config(-port) &]
        write_file $pidfile $wibble_pid

        # Wait for it to start before returning
        after 10
        return
    }

    proc stop {} {
        variable config
        
        catch {
            http::cleanup [http::geturl [make_test_url _woof/test/test/stop]]
        }
        after 50;               # Wait to see if it exits cleanly
        set pidfile [pidpath]
        if {[file exists $pidfile]} {
            set pid [read_file $pidfile]
            if {[process_exists $pid]} {
                terminate $pid
            }
            file delete -force $pidfile
        }
    }
}

################################################################

proc ::woof::test::webserver_prepare {} {
    variable script_dir
    variable config

    # Sets up the specified server configuration
    if {$config(-server) ni {apache iis wibble}} {
        error "Server $options(-server) not supported."
    }

    # Installs Woof! "in-place" within $woof_dir
    if {$config(-server) ni {bowwow wibble}} {
        exec [info nameofexecutable] [file join $config(-woofdir) scripts installer.tcl] install $config(-server) $config(-interface)
    }

    return [::woof::test::${config(-server)}::prepare]
}

proc ::woof::test::webserver_cleanup {} {
    variable config
    return [::woof::test::${config(-server)}::cleanup]
}

proc ::woof::test::webserver_start {} {
    variable script_dir
    variable config

    if {$config(-interface) eq "scgi"} {
        start_scgi_process
    }
    ::woof::test::${config(-server)}::start
}

proc ::woof::test::webserver_stop {args} {
    variable script_dir
    variable config

    ::woof::test::${config(-server)}::stop
    if {$config(-interface) eq "scgi"} {
        stop_scgi_process
    }
}
