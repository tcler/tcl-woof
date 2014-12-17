#
# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# This file contains test utility procs

if {[info exists ::woof::test::script_dir]} {
    return
}

package require tcltest
package require http
package require uri
package require fileutil
package require json
package require tdom
package require Itcl
package require Testing
package require WebDriver

source [file join [file dirname [info script]] webserver_config.tcl]

if {[catch {
    package require distro
}]} {
    source [file join [file dirname [info script]] .. lib distro distro.tcl]
}

namespace eval ::woof::test {

    if {$::tcl_platform(platform) eq "windows"} {
        proc windows {} {return true}
    } else {
        proc windows {} {return false}
    }

    variable paths
    # We use the shortname to avoid quoting problems when exec'ing
    if {[windows]} {
	set paths(test_scripts) [file attributes [file normalize [file dirname [info script]]] -shortname]
    } else {
	set paths(test_scripts) [file normalize [file dirname [info script]]]
    }
    set paths(source_root) [file normalize [file join $paths(test_scripts) ..]]

    variable script_dir
    set script_dir $paths(test_scripts); # For backward compatibility
}

proc ::woof::test::read_file {path} {
    set fd [open $path]
    set data [read $fd]
    close $fd
    return $data
}

proc ::woof::test::write_file {path data} {
    ensure_parent_dir $path
    set fd [open $path w]
    puts -nonewline $fd $data
    close $fd
}

proc ::woof::test::woof_path {args} {
    variable config
    return [file normalize [file join $config(-woofdir) {*}$args]]
}

proc ::woof::test::source_path {args} {
    variable paths
    return [file normalize [file join $paths(source_root) {*}$args]]
}

proc ::woof::test::test_path {args} {
    variable paths
    return [file normalize [file join $paths(test_scripts) {*}$args]]
}

proc ::woof::test::save_config {} {
    variable config
    variable script_dir
    write_file [file join $script_dir testconfig.cfg] [array get config]
}

proc ::woof::test::read_config {} {
    variable config
    variable script_dir
    array set config [read_file [file join $script_dir testconfig.cfg]]
}

proc woof::test::ensure_parent_dir {path} {
    if {[file exists [file dirname $path]]} {
        return
    }
    file mkdir [file dirname $path]
}

# Copy a template after replacing placeholders
proc ::woof::test::copy_template {from to map} {
    set fd [open $from r]
    set data [read $fd]
    close $fd

    # Substitute the content
    if {[dict exists $map url_root]} {
        if {[dict get $map url_root] eq "/"} {
            # Special case URL_ROOT=/ else we will land up with paths
            # like //stylesheets so replace such cases first and then
            # remaining %URL_ROOT% in loop below
            regsub -all -- {%URL_ROOT%/} $data / data
        }
    }

    dict for {key val} $map {
        regsub -all -- "***=%[string toupper $key]%" $data $val data
    }

    # Assume if .sav exists, original already backed up
    if {![file exists ${to}.sav]} {
        file copy $to ${to}.sav
    }

    write_file $to $data
}

# Does NOT expand wildcards. Quite simplistic, does not handle links
# well etc.
# Will overwrite destination files. Will abort on error with
# copies only partially done.
proc woof::test::copy_dir {from to} {
    if {![file isdirectory $from]} {
        error "Directory $from not found."
    }

    set to_is_dir [file isdirectory $to]
    set to_exists [file exists $to]

    if {$to_exists && ! $to_is_dir} {
        error "Destination $to exists but is not a directory."
    }

    file mkdir $to

    foreach entry [glob -directory $from -tails *] {
        set from_entry [file join $from $entry]
        set to_entry [file join $to $entry]
        if {[file isdirectory $from_entry]} {
            copy_dir $from_entry $to_entry
        } else {
            # Ordinary file
            if {[file exists $to_entry] &&
                [file isdirectory $to_entry]} {
                error "Attempt to copy file $from_entry on top of a existing directory $to_entry."
            }
            file copy -force -- $from_entry $to_entry
        }
    }
}

proc ::woof::test::assert_server_running {} {
    variable config

    set url [uri::join scheme http host localhost port $config(-port) path /]
    puts "Testing server availability at $url"
    if {[catch {
        set tok [http::geturl $url]
        array set meta [http::meta $tok]
        if {![info exists meta(Server)]} {
            set msg "No identification returned by server. Please check configuration and command line options."
        } else {
            if {![string match -nocase "*${config(-server)}*" $meta(Server)]} {
                set msg "Reached server $meta(Server), expected $config(-server). Please check configuration and command line options."
            }
            # Ideally, want to check the server interface but not sure how
        }
        http::cleanup $tok
        if {[info exists msg]} {
            error $msg
        }
    } msg]} {
        progress "Stopping server $config(-server)"
        ::woof::test::webserver_stop
        error $msg
    }        
    return
}

proc ::woof::test::setup_woof_config {} {
    variable config
    # Set application.cfg to reflect URL root
    write_file [file join $config(-woofdir) config application.cfg] \
        "set url_root $config(-urlroot)\n"
}

proc ::woof::test::cleanup_woof_config {} {
    variable config
    file delete [file join $config(-woofdir) config application.cfg]
}

proc ::woof::test::make_test_url {rurl {query ""}} {
    variable config
    return [uri::join \
                scheme http \
                host $config(-host) \
                port $config(-port) \
                path [file join $config(-urlroot) $rurl] \
                query $query]
}

proc ::woof::test::url_part {url field} {
    return [dict get [uri::split $url] $field]
}

proc ::woof::test::clean_path {args} {
    if {[windows]} {
        return [file nativename [file attributes [file normalize [file join {*}$args]] -shortname]]
    } else {
        return [file normalize [file join {*}$args]]
    }
}


if {[woof::test::windows]} {
    proc woof::test::terminate {pid} {
        catch {
            exec {*}[auto_execok taskkill.exe] /PID $pid
        }
    }

    proc woof::test::kill {pid} {
        catch {
            exec {*}[auto_execok taskkill.exe] /F /PID $pid
        }
    }

    proc woof::test::process_exists {pid} {
        set tasklist [exec {*}[auto_execok tasklist.exe] /fi "pid eq $pid" /nh]
        return [regexp "^\\s*\\S+\\s+$pid\\s" $tasklist]
    }
} else {
    proc woof::test::terminate {pid} {
        catch {
            exec kill -15 $pid
        }
    }
    proc woof::test::kill {pid} {
        catch {
            exec kill -9 $pid
        }
    }

    proc woof::test::process_exists {pid} {
        if {[catch { set fp [open "/proc/$pid/stat"]}] != 0} {
            return 0
        }

        set stats [read $fp]
        close $fp

        if {[regexp {\d+ \([^)]+\) (\S+)} $stats match state]} {
            if {$state eq {Z}} {
                return 0
            }
        }

        return 1
    }
}


proc ::woof::test::start_scgi_process {} {
    variable config

    set pidfile [test_path temp scgi.pid]
    if {[file exists $pidfile]} {
        set pid [read_file $pidfile]
        if {[process_exists $pid]} {
            # Cannot use the same process since config may be different
            error "SCGI server seems to be already running with PID $pid. Please stop it first."
        }
    }

    set pid [exec [info nameofexecutable] [clean_path [file join $config(-woofdir) lib woof webservers scgi_server.tcl]] &]
    write_file $pidfile $pid

    # Wait for it to start before returning
    after 10
    return
}

proc ::woof::test::stop_scgi_process {} {
    variable config

    set pidfile [test_path temp scgi.pid]
    if {[file exists $pidfile]} {
        set pid [read_file $pidfile]
        if {[process_exists $pid]} {
            # Note "terminate" call does not work for the scgi script
            kill $pid
        }
        file delete -force $pidfile
    }
}

proc ::woof::test::boolean_compare {aval bval} {
    # Compare booleans (e.g. true and 1 should compare equal)
    expr {(!!$aval) == (!!$bval)}
}

proc ::woof::test::list_compare {avalues bvalues} {
    # Compare lists
    if {[llength $avalues] != [llength $bvalues]} {
        return 0
    }
    foreach a $avalues b $bvalues {
        if {$a ne $b} {return 0}
    }
    return 1
}

if {[llength [info commands ::tcltest::customMatch]]} {
    ::tcltest::customMatch boolean ::woof::test::boolean_compare
    ::tcltest::customMatch list ::woof::test::list_compare
}


proc woof::test::open_websession {} {
    assert_selenium_running
    WebDriver::Capabilities [namespace current]::webcaps -browser_name chrome
    WebDriver::Session [namespace current]::websession http://127.0.0.1:4444/wd/hub [namespace current]::webcaps
}

proc woof::test::close_websession {} {
    itcl::delete object [namespace current]::websession
    itcl::delete object [namespace current]::webcaps
}

proc woof::test::assert_selenium_running {} {
    set tok [http::geturl http://localhost:4444/wd/hub/status]
    if {[http::status $tok] ne "ok"} {
        error "HTTP check for Selenium server failed with status [http::status $tok][http::cleanup $tok]"
    }

    set status [dict get [json::json2dict [http::data $tok]] status]
    if {$status != 0} {
        error "Selenium server returned status $status"
    }
    return
}

# Return 1 on success, or 0 if selenium was running but could not be shut down
proc woof::test::shutdown_selenium {} {
    if {![catch{
        set tok [http::geturl http://localhost:4444/selenium-server/driver/ -query cmd=shutDownSeleniumServer]
    }]} {
        http::cleanup $tok
        after 100;              # Wait for it to exit
        return [catch {
            http::cleanup [http::geturl http://localhost:4444/wd/hub/status]
        }]
    }
    return 1
}
