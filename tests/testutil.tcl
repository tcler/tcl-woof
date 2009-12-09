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
        port      80
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

