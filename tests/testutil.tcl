#
# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# This file contains test utility procs

package require uri
if {$::tcl_platform(platform) eq "windows"} {
    package require twapi
}

namespace eval ::woof::test {
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
    if {$::tcl_platform(platform) eq "windows"} {
        return [file attributes [file normalize $path] -shortname]
    } else {
        return [file normalize $path]
    }
}

if {$::tcl_platform(platform) eq "windows"} {
    interp alias {} ::woof::test::process_exists {} ::twapi::process_exists
    interp alias {} ::woof::test::end_process {} ::twapi::end_process
} else {
    proc ::woof::test::process_exists pid {
	return [file exists /proc/$pid]
    }
    proc ::woof::test::end_process {pid args} {
	exec kill $pid
    }
}

proc ::woof::test::start_scgi_process {} {
    variable scgi_pid
    variable popts

    if {[info exists scgi_pid] && [process_exists $scgi_pid]} {
        return
    }

    unset -nocomplain scgi_pid;             # In case exec fails
    set scgi_pid [exec [info nameofexecutable] [clean_path [file join $popts(-woofdir) lib woof webservers scgi_server.tcl]] &]
    # Wait for it to start before returning
    after 10
}

proc ::woof::test::stop_scgi_process {} {
    variable scgi_pid

    if {[info exists scgi_pid]} {
        end_process $scgi_pid -force true
        unset scgi_pid
    }
}


::tcltest::customMatch boolean ::woof::test::boolean_compare
proc ::woof::test::boolean_compare {aval bval} {
    # Compare booleans (e.g. true and 1 should compare equal)
    expr {(!!$aval) == (!!$bval)}
}

::tcltest::customMatch list ::woof::test::list_compare
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

