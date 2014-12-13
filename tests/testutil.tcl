#
# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# This file contains test utility procs

if {[info exists ::woof::test::script_dir]} {
    puts "Already sourced"
    return
}
puts "Running testutil"

package require tcltest
package require Itcl
package require Testing
package require WebDriver
package require fileutil
package require json

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

proc ::woof::test::woof_path {args} {
    variable config
    return [file normalize [file join $config(-woofdir) {*}$args]]
}

proc ::woof::test::source_path {args} {
    variable paths
    return [file normalize [file join $paths(source_root) {*}$args]]
}

proc ::woof::test::save_config {} {
    variable config
    variable script_dir
    set fd [open [file join $script_dir testconfig.cfg] w]
    puts $fd [array get config]
    close $fd
}

proc ::woof::test::read_config {} {
    variable config
    variable script_dir

    set fd [open [file join $script_dir testconfig.cfg]]
    array set config [read $fd]
    close $fd
}

proc woof::test::ensure_parent_dir {path} {
    if {[file exists [file dirname $path]]} {
        return
    }
    file mkdir [file dirname $path]
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
    set fd [open [file join $config(woofdir) config application.cfg] w]
    puts $fd "set url_root $opts(-urlroot)"
    close $fd
}

proc ::woof::test::init_values {} {
    variable test_url
    array set test_url {
        scheme    http
        host      127.0.0.1
        port      8015
        urlroot   /
        url_module _woof/test
        query    a=b&=d
    }

    catch {set test_url(port) $::env(WOOF_TEST_PORT)}
    catch {set test_url(host) $::env(WOOF_TEST_HOST)}
    catch {set test_url(urlroot) $::env(WOOF_TEST_URLROOT)}
}

proc ::woof::test::make_test_url {rurl {query ""}} {
    variable test_url
    return [uri::join \
                scheme http \
                host $test_url(host) \
                port $test_url(port) \
                path [file join $test_url(urlroot) $rurl] \
                query $query]
}

proc ::woof::test::url_part {url field} {
    return [dict get [uri::split $url] $field]
}

proc ::woof::test::clean_path {path} {
    if {[windows]} {
        return [file attributes [file normalize $path] -shortname]
    } else {
        return [file normalize $path]
    }
}

namespace eval woof::test {
    if {[windows]} {
        proc terminate {pid} {
            catch {
                exec {*}[auto_execok taskkill.exe] /PID $pid
            }
        }

        proc kill {pid} {
            catch {
                exec {*}[auto_execok taskkill.exe] /F /PID $pid
            }
        }

        proc process_exists {pid} {
            set tasklist [exec {*}[auto_execok tasklist.exe] /fi "pid eq $pid" /nh]
            return [regexp "^\\s*\\S+\\s+$pid\\s" $tasklist]
        }
    } else {
        proc terminate {pid} {
            catch {
                exec kill -15 $pid
            }
        }

        proc kill {pid} {
            catch {
                exec kill -9 $pid
            }
        }

        proc process_exists {pid} {
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
}

proc ::woof::test::start_scgi_process {} {
    variable scgi_pid
    variable config

    if {[info exists scgi_pid] && [process_exists $scgi_pid]} {
        return
    }

    unset -nocomplain scgi_pid;             # In case exec fails
    set scgi_pid [exec [info nameofexecutable] [clean_path [file join $config(-woofdir) lib woof webservers scgi_server.tcl]] &]
    # Wait for it to start before returning
    after 10
}

proc ::woof::test::stop_scgi_process {} {
    variable scgi_pid

    if {[info exists scgi_pid]} {
        kill $scgi_pid
        unset scgi_pid
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

proc woof::test::assert_selenium_healthy {} {
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
