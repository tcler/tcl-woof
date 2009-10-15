# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.
namespace eval util {}

proc util::http_response_code {code} {
    # Maps HTTP response codes to a HTTP response strings
    # code - the response code to map
    # Returns the corresponding HTTP response string.

    variable http_response_map
    set http_response_map \
        [dict create \
             100 "100 Continue" \
             101 "101 Switching Protocols" \
             200 "200 OK" \
             ok "200 OK" \
             success "200 OK" \
             201 "201 Created" \
             202 "202 Accepted" \
             301 "301 Moved Permanently" \
             302 "302 Found" \
             303 "303 See Other" \
             304 "304 Not Modified" \
             not_modified "304 Not Modified" \
             307 "307 Temporary Redirect" \
             400 "400 Bad Request" \
             client_error "400 Bad Request" \
             404 "404 Not Found" \
             server_error "500 Internal Server Error" \
             500 "500 Internal Server Error" \
            ]
    
    # Above initializes the map. Now
    # redefine ourselves to return the response code
    # without reinitializing every time
    proc [namespace current]::http_response_code code {
        variable http_response_map
        if {[dict exists $http_response_map $code]} {
            return [dict get $http_response_map $code]
        } else {
            return $code
        }
    }

    # Now return the reinitialized proc
    return [http_response_code $code]
}


proc util::generate_name {{prefix ::woof::id_}} {
    # Returns a new generated name
    # prefix - a prefix to be used for the name
    variable _name_counter
    return ${prefix}[incr _name_counter]
}


proc util::format_http_date {secs} {
    # Format a date and time as required by HTTP
    # secs - seconds since 00:00:00 Jan 1 1970 as returned by the 
    #  [clock seconds] command
    # Returns the corresponding HTTP formatted date.
    return [clock format $secs \
                -format "%A, %d-%b-%Y %H:%M:%S GMT" \
                -gmt 1]
}


proc util::scan_http_date {datestr} {
    # Converts a HTTP formatted date to seconds since the epoch
    # datestr - a date time string formatted as per the HTTP specification
    # Returns the date and time as the number of seconds since
    # 0:0:0 Jan 1, 1970.

    # TBD - test this. Also is time always in GMT ?
    return [clock scan $datestr \
                -format "%A, %d-%b-%Y %H:%M:%S GMT" \
                -gmt 1]
    
}

proc util::mixcase {name} {
    # Converts an identifier containing underscores into mixed case
    # name - identifier to be converted
    #
    # The return value is constructed by removing all non-leading and
    # non-trailing underscore characters and changing the following
    # letter to upper case. This is the reciprocal of the unmixcase proc.
    #
    # Returns the converted identifier.

    regexp {^(_*)(.*)$} $name dontcare prefix base
    set mixcase ""
    foreach part [split $base _] {
        if {$part eq ""} {
            # Trailing underscores
            append mixcase _
        } else {
            append mixcase "[string toupper [string index $part 0]][string range $part 1 end]"
        }
    }
    return $prefix$mixcase
}

proc util::unmixcase {name} {
    # Converts an mixed case identifier to a lower case one with underscores
    # name - identifier to be converted
    #
    # The return value is constructed by replacing upper case characters
    # by lower case ones, preceded by an underscore character. This is
    # the reciprocal of the mixcase proc.
    #
    # Returns the converted identifier.

    # We have to separate the prefix because _Abc become _abc, not __abc.
    regexp {^(_*)(.*)$} $name dontcare prefix base

    return $prefix[string tolower [regsub -all {[A-Z]} $name _\\0]]
}

# TBD - fix these aliases for multiple server environments
if {[llength [info commands ::web::htmlify]]} {
    interp alias {} ::woof::util::hesc {} ::web::htmlify
} else {
    interp alias {} ::woof::util::hesc {} ::html::html_entities
}

# Use binary implementations when possible - TBD fix for other servers
if {[llength [info commands ::web::uriencode]]} {
    interp alias {} ::woof::util::url_encode {} ::web::uriencode
    interp alias {} ::woof::util::url_decode {} ::web::uridecode
    interp alias {} ::woof::util::cookie_encode {} ::web::uriencode
    interp alias {} ::woof::util::cookie_decode {} ::web::uridecode
} else {
    # Copied from tcllib ncgi
    namespace eval util {
        # Define a proc for init to hide loop variables global/namespaces
        proc _init_url_encode_map {} {
            variable _url_encode_map
            for {set i 1} {$i <= 256} {incr i} {
                set c [format %c $i]
                if {![string match \[a-zA-Z0-9\] $c]} {
                    set _url_encode_map($c) %[format %.2X $i]
                }
            }
     
            # These are handled specially
            array set _url_encode_map {
                " " +   \n %0D%0A
            }
        }
        _init_url_encode_map
    }    

    proc util::url_decode {str} {
        # Decode a www-url-encoded string
        # str - the string to be converted
        # Returns the decoded string.

        # rewrite "+" back to space
        # protect \ from quoting another '\'
        set str [string map [list + { } "\\" "\\\\"] $str]

        # prepare to process all %-escapes
        regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str

        # process \u unicode mapped chars
        return [subst -novar -nocommand $str]
    }

    proc util::url_encode {str} {
        # Encode a string in www-url-encoded format
        # str - string to be encoded
        # Returns the encoded string.

        variable _url_encode_map

        # 1 leave alphanumerics characters alone
        # 2 Convert every other character to an array lookup
        # 3 Escape constructs that are "special" to the tcl parser
        # 4 "subst" the result, doing all the array substitutions

        regsub -all -- \[^a-zA-Z0-9\] $str {$_url_encode_map(&)} str
        # This quotes cases like $_url_encode_map([) or $_url_encode_map($) => $_url_encode_map(\[) ...
        regsub -all -- {[][{})\\]\)} $str {\\&} str
        return [subst -nocommand $str]
    }
    interp alias {} ::woof::util::cookie_encode {} ::woof::util::url_encode
    interp alias {} ::woof::util::cookie_decode {} ::woof::util::url_decode
}

# Generate a session id
proc util::generate_session_id {} {
    # Generate a session identifier.
    #
    # Returns a string that is suitable to be used as a session identifier.
    #
    # WARNING: this command currently does not return a session identifier
    # that is cryptographically secure.

    # TBD - REVISIT!!! Completely insecure
    return [md5hex [clock clicks]]
}


proc util::contained_path {path dirpath} {
    # Checks if the specified path is a descendent of the specified directory
    # path - path to check
    # dirpath - directory path under which $path is expected to lie
    # 

    if {[file pathtype $path] ne "absolute"} {
        set path [file normalize $path]
    }
    if {[file pathtype $dirpath] ne "absolute"} {
        set dirpath [file normalize $dirpath]
    }

    set path [file join $path]; # \ -> /, remove double //, trailing / etc.
    set dirpath [file join $dirpath]

    set base_len [string length $dirpath]

    set nocase [expr {$::tcl_platform(platform) eq "windows" ? "-nocase" : ""}]

    # The file must lie inside the dir path, not even be the same. Thus
    # the next char of file path must be /
    return [string equal {*}$nocase -length [incr base_len] ${dirpath}/ $path]
}

proc util::export_all {} {
    # Exports all procs in *caller's* namespace that do not begin with an underscore

    uplevel namespace export {{*}[lsearch -glob -all -inline -not [info procs] _*]}
    # Classes and objects not exported - cannot get nested exports to work right
    # Ditto for aliases
    # uplevel namespace export {{*}[lsearch -glob -all -inline -not [string map [list [namespace current]:: ""] [info class instances ::oo::class [namespace current]::*]] _*]}
}



namespace eval util {
    export_all
    namespace export hesc
}
