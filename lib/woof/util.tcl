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

    return $prefix[string tolower [string trimleft [regsub -all {[A-Z]} $name _\\0] _]]
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


proc util::charset_tcl2iana {tcl_cs {default_cs ""}} {
    variable charset_tcl2iana
    array set charset_tcl2iana {
        cp860 IBM860 cp861 IBM861 cp862 IBM862 cp863 IBM863 cp864 IBM864
        cp865 IBM865 cp866 IBM866 cp869 IBM869 ksc5601 KS_C_5601-1987
        jis0201 JIS_C6220-1969-jp gb2312 GB_2312-80 euc-cn GB2312
        euc-jp Extended_UNIX_Code_Packed_Format_for_Japanese
        jis0208 JIS_C6226-1983 iso2022-jp ISO-2022-JP jis0212 JIS_X0212-1990
        big5 Big5 euc-kr EUC-KR gb1988 GB_1988-80 iso2022-kr ISO-2022-KR
        ascii ANSI_X3 cp437 IBM437 iso8859-1 ISO_8859-1 iso8859-2 ISO_8859-2
        iso8859-3 ISO_8859-3 koi8-r KOI8-R iso8859-4 ISO_8859-4 iso8859-5 ISO_8859-5
        cp1250 windows-1250 iso8859-6 ISO_8859-6 cp1251 windows-1251
        iso8859-7 ISO_8859-7 cp1252 windows-1252 iso8859-8 ISO_8859-8 cp1253 windows-1253
        iso8859-9 ISO_8859-9 cp1254 windows-1254 cp1255 windows-1255 cp850 IBM850
        cp1256 windows-1256 cp1257 windows-1257 cp852 IBM852 cp1258 windows-1258
        shiftjis Shift_JIS utf-8 UTF-8 cp855 IBM855 symbol Adobe-Symbol-Encoding
        cp775 IBM775 unicode ISO-10646-UCS-2 cp857 IBM857
    }

    # Redefine the proc so we do not reinit every time
    proc charset_tcl2iana {tcl_cs {default_cs ""}} {
        variable charset_tcl2iana
        set tcl_cs [string tolower $tcl_cs]
        if {[info exists charset_tcl2iana($tcl_cs)]} {
            return $charset_tcl2iana($tcl_cs)
        } else {
            return $default_cs
        }
    }

    # Return the redefined proc
    charset_tcl2iana $tcl_cs $default_cs
}

proc util::charset_iana2tcl {iana_cs {default_cs ""}} {
    variable charset_iana2tcl
    array set charset_iana2tcl {
        ibm860 cp860 cp860 cp860 860 cp860 csibm860 cp860 ibm861 cp861
        cp861 cp861 861 cp861 cp-is cp861 csibm861 cp861 ibm862 cp862
        cp862 cp862 862 cp862 cspc862latinhebrew cp862 ibm863 cp863
        cp863 cp863 863 cp863 csibm863 cp863 ibm864 cp864 cp864 cp864
        csibm864 cp864 ibm865 cp865 cp865 cp865 865 cp865 csibm865 cp865
        ibm866 cp866 cp866 cp866 866 cp866 csibm866 cp866 ibm869 cp869
        cp869 cp869 869 cp869 cp-gr cp869 csibm869 cp869 ks_c_5601-1987 ksc5601
        iso-ir-149 ksc5601 ks_c_5601-1989 ksc5601 ksc_5601 ksc5601
        korean ksc5601 csksc56011987 ksc5601 jis_c6220-1969-jp jis0201
        jis_c6220-1969 jis0201 iso-ir-13 jis0201 katakana jis0201
        x0201-7 jis0201 csiso13jisc6220jp jis0201 gb_2312-80 gb2312
        iso-ir-58 gb2312 chinese gb2312 csiso58gb231280 gb2312 gb2312 euc-cn
        csgb2312 euc-cn extended_unix_code_packed_format_for_japanese euc-jp
        cseucpkdfmtjapanese euc-jp euc-jp euc-jp jis_c6226-1983 jis0208
        iso-ir-87 jis0208 x0208 jis0208 jis_x0208-1983 jis0208
        csiso87jisx0208 jis0208 iso-2022-jp iso2022-jp csiso2022jp iso2022-jp
        jis_x0212-1990 jis0212 x0212 jis0212 iso-ir-159 jis0212
        csiso159jisx02121990 jis0212 big5 big5 csbig5 big5 euc-kr euc-kr
        cseuckr euc-kr gb_1988-80 gb1988 iso-ir-57 gb1988 cn gb1988
        iso646-cn gb1988 csiso57gb1988 gb1988 iso-2022-kr iso2022-kr
        csiso2022kr iso2022-kr ansi_x3 ascii iso-ir-6 ascii iso_646 ascii
        ascii ascii iso646-us ascii us-ascii ascii us ascii ibm367 ascii
        cp367 ascii csascii ascii ibm437 cp437 cp437 cp437 437 cp437
        cspc8codepage437 cp437 iso_8859-1 iso8859-1 iso-ir-100 iso8859-1
        iso-8859-1 iso8859-1 latin1 iso8859-1 l1 iso8859-1 ibm819 iso8859-1
        cp819 iso8859-1 csisolatin1 iso8859-1 iso_8859-2 iso8859-2
        iso-ir-101 iso8859-2 iso-8859-2 iso8859-2 latin2 iso8859-2 l2 iso8859-2
        csisolatin2 iso8859-2 iso_8859-3 iso8859-3 iso-ir-109 iso8859-3
        iso-8859-3 iso8859-3 latin3 iso8859-3 l3 iso8859-3 csisolatin3 iso8859-3
        koi8-r koi8-r cskoi8r koi8-r iso_8859-4 iso8859-4 iso-ir-110 iso8859-4
        iso-8859-4 iso8859-4 latin4 iso8859-4 l4 iso8859-4 csisolatin4 iso8859-4
        iso_8859-5 iso8859-5 iso-ir-144 iso8859-5 iso-8859-5 iso8859-5
        cyrillic iso8859-5 csisolatincyrillic iso8859-5 windows-1250 cp1250
        iso_8859-6 iso8859-6 iso-ir-127 iso8859-6 iso-8859-6 iso8859-6
        ecma-114 iso8859-6 asmo-708 iso8859-6 arabic iso8859-6
        csisolatinarabic iso8859-6 windows-1251 cp1251 iso_8859-7 iso8859-7
        iso-ir-126 iso8859-7 iso-8859-7 iso8859-7 elot_928 iso8859-7
        ecma-118 iso8859-7 greek iso8859-7 greek8 iso8859-7
        csisolatingreek iso8859-7 windows-1252 cp1252 iso_8859-8 iso8859-8
        iso-ir-138 iso8859-8 iso-8859-8 iso8859-8 hebrew iso8859-8
        csisolatinhebrew iso8859-8 windows-1253 cp1253 iso_8859-9 iso8859-9
        iso-ir-148 iso8859-9 iso-8859-9 iso8859-9 latin5 iso8859-9 l5 iso8859-9
        csisolatin5 iso8859-9 windows-1254 cp1254 windows-1255 cp1255
        ibm850 cp850 cp850 cp850 850 cp850 cspc850multilingual cp850
        windows-1256 cp1256 windows-1257 cp1257 ibm852 cp852 cp852 cp852
        852 cp852 cspcp852 cp852 windows-1258 cp1258 shift_jis shiftjis
        ms_kanji shiftjis csshiftjis shiftjis utf-8 utf-8 ibm855 cp855
        cp855 cp855 855 cp855 csibm855 cp855 gbk cp936
        adobe-symbol-encoding symbol cshppsmath symbol ibm775 cp775 cp775 cp775
        cspc775baltic cp775 iso-10646-ucs-2 unicode csunicode unicode
        ibm857 cp857 cp857 cp857 857 cp857 csibm857 cp857
    }

    # Redefine the proc so we do not reinit every time
    proc charset_iana2tcl {iana_cs {default_cs ""}} {
        variable charset_iana2tcl
        set iana_cs [string tolower $iana_cs]
        if {[info exists charset_iana2tcl($iana_cs)]} {
            return $charset_iana2tcl($iana_cs)
        } else {
            return $default_cs
        }
    }

    # Return the redefined proc
    charset_iana2tcl $iana_cs $default_cs
}


proc util::http_sorted_header_values {header_value} {
    # Parses a multi-valued HTTP header string and returns the values
    # sorted by their quality attribute
    # header_val - the HTTP header value such as those for the Accept-* headers.
    #  Should not include the header itself.
    # The command sorts the values specified in the header and returns
    # them sorted by their associated quality attributes.
    # For example, the value "text/html;q=0.2, text/xml, application/pdf ;q=0.3"
    # will be result in "text/xml application/pdf text/html" being returned.

    # The header values are separated by commas
    set qvals {}
    foreach val [quoted_split $header_value , [list \"] \\ "string trim"] {
        # Within each value, the attributes are separated by ";"
        set val [split $val ";"]
        if {[llength $val] == 0} continue
        set q 1.0
        if {[llength $val] > 1} {
            set q [string trim [lindex [split [lindex $val 1] =] 1]]
            if {![string is double -strict $q]} {
                # Ignore - invalid
                continue
            }
        }
        lappend qvals [list [string trim [lindex $val 0]] $q]
    }
    
    # Sort by priority and search
    set vals {}
    foreach val [lsort -real -index 1 -decreasing $qvals] {
        lappend vals [lindex $val 0]
    }
    return $vals
}

proc util::http_select_header_value {header_value available default_value} {
    # Select a content attribute for a HTTP response
    # header_val - the HTTP Accept-* value (excluding the Accept-* header)
    # available - list of available attribute values
    # default_value - value to return if there is no match
    # The command matches the requested HTTP header value against what
    # is available and returns the matched value. The HTTP header value
    # is in the format used for the Accept, Accept-Charset or
    # Accept-Language headers.

    # The header values are separated by commas
    foreach val [http_sorted_header_values $header_value] {
        # Note val can be a pattern like text/*
        set val [lsearch -glob -inline $available $val]
        if {$val ne ""} {
            return $val
        }
    }

    # Nothing found
    return $default_value
}


proc util::quoted_split {s sep {quote_chars {\"}} {esc \\} {transform {}}} {
    # Splits a string into a list based on the specified criteria
    # s - string to be split
    # sep - character that separates the fields in the string. This must
    #   not be the same as the quoting characters.
    # quote_chars - a list of one or two characters that specify the
    #   start and end character for quoted substrings. If the list has only
    #   one element, the start and end quotes are the same.
    # esc - the character used to escape other characters within the
    #   quoted string.
    # transform - command prefix to invoke on each field before adding it to 
    #   the returned list. Used for trimming whitespace, for example.

    set qbegin [lindex $quote_chars 0]
    if {[string first $qbegin $s] < 0} {
        # No quotes, so do a simple split
        if {$transform eq ""} {
            return [split $s $sep]
        } else {
            set l {}
            foreach val [split $s $sep] {
                lappend l [eval [linsert $transform end $val]]
            }
            return $l
        }
    }

    # pos is position of first quote. Note that if a quote char has to be
    # included as a literal char, it must be placed inside quotes like "\""
    
    if {[llength $quote_chars] > 1} {
        set qend [lindex $quote_chars 1]
        set regex "\\$qbegin|\\$qend|\\$sep"
    } else {
        set qend $qbegin
        set regex "\\$qbegin|\\$sep"
    }
    if {$esc ne ""} {
        append regex "|\\$esc"
    }

    # Split the string into tokens based on the special chars and iterate
    set field  "";              # current field
    set field_begin 0
    set fields {};              # List of collected fields
    set state  unquoted
    set skip_pos -1
    foreach pos [regexp -indices -inline -all -- $regex $s] {
        # $pos is pair with both elements equal
        lassign $pos pos
        if {$pos == $skip_pos} continue; # Escaped special char
        set match_char [string index $s $pos]
        if {$state eq "unquoted"} {
            # Note order of checking quote begin/end important as both
            # chars may be the same
            if {$match_char eq $qbegin} {
                # Start of quoted string. Append what we have so far to the
                # current field
                append field [string range $s $field_begin $pos-1]
                set field_begin [incr pos]
                set state quoted
            } elseif {$match_char eq $sep} {
                # End of field
                append field [string range $s $field_begin $pos-1]
                if {$transform ne ""} {
                    set field [eval [linsert $transform end $field]]
                }
                lappend fields $field
                set field ""
                set field_begin [incr pos]
            } else {
                # Escapes or end quote - no meaning outside quotes, keep going
            }
        } else {
            # Currently inside quotes. Again order of checking is important.
            # endquote is checked in case end and begin quotes are the same
            if {$match_char eq $qend} {
                append field [string range $s $field_begin $pos-1]
                set field_begin [incr pos]
                set state unquoted
            } elseif {$match_char eq $esc} {
                # Escape character. Copy what we have so far and
                # ensure next character is skipped as special character
                append field "[string range $s $field_begin $pos-1][string index $s [incr pos]]"
                set skip_pos $pos; # Do not check next char as special
                set field_begin [incr pos]
            } else {
                # separator, - no meaning inside quotes - keep going
            }
        }
    }

    append field [string range $s $field_begin end]
    if {$transform ne ""} {
        set field [eval [linsert $transform end $field]]
    }
    lappend fields $field
    
    return $fields
}

proc util::memoize {args} {
    # TBD - set limit on size of cache
    # Redefine without the initialization
    proc memoize {args} {
        variable _memoize_cache
        if {[info exists _memoize_cache($args)]} {
            return $_memoize_cache($args)
        }
        return [set _memoize_cache($args) [uplevel 1 $args]]
    }
    
    return [memoize {*}$args]
}


proc util::remove_left_margin {text args} {
    # Removes the left margin from the lines in the specified text
    # text - text string
    # The command trims leading whitespace from all lines in $text.

    array set opts {
        -skipleadingempties false
        -combineempties false
        -returnlist false
    }
    array set opts $args

    set lines {}
    set state init;             # init -> collecting <-> empty
    foreach line [split $text \n] {
        if {[regexp {^\s*$} $line]} {
            if {$state eq "collecting"} {
                lappend lines ""
                set state empty
            } elseif {$state eq "empty"} {
                #ruff
                # -combineempties BOOLEAN - if true, multiple
                #  blank lines are combined into one. Default is false.
                if {! $opts(-combineempties)} {
                    lappend lines ""
                }
            } else {
                #ruff
                # -skipleadingempties BOOLEAN - if true, leading 
                #  blank lines are skipped. Default is false.
                if {! $opts(-skipleadingempties)} {
                    lappend lines ""
                    set state empty
                }
            }
            continue
        }

        #ruff
        # The very first non empty line determines the margin. This will
        # be removed from all subsequent lines. Note that this assumes that
        # if tabs are used for indentation, they are used on all lines
        # in consistent fashion.
        if {![info exists prefix]} {
            regexp {^(\s*)\S} $line dontcare prefix
            set prefix_len [string length $prefix]
        }
        set state collecting

        # Remove the prefix if it exists from the line
        if {[string match ${prefix}* $line]} {
            set line [string range $line $prefix_len end]
        }

        lappend lines $line
    }

    #ruff
    # -returnlist BOOLEAN - if true, the command returns a list of lines.
    #  If false (default), the command returns a string with the
    #  lines are joined with newlines.
    if {$opts(-returnlist)} {
        return $lines
    } else {
        return [join $lines \n]
    }
}

proc util::tag_attr_fragment {args} {
    if {[llength $args] == 1} {
        set args [lindex $args 0]
    }
    set attrs ""
    foreach {attr val} $args {
        # TBD - what needs to be hesc'ed ?
        lappend attrs "${attr}='$val'"
    }
    return [join $attrs " "]
}

proc util::dict_get {dict key default_value} {
    # Returns the value for a key from a dictionary and a default if 
    # the key is not present
    # dict - the dictionary
    # key - the key to retrieve. Nested keys are not supported
    # default_value - default value to return if key is not present

    if {[dict exists $dict $key]} {
        return [dict get $dict $key]
    } else {
        return $default_value
    }
}

proc util::dict_pop {vdict key default_value} {
    # Removes and returns the value for a key from a dictionary and a default if 
    # the key is not present.
    # vdict - the name of the variable containing the dictionary
    # key - the key to retrieve. Nested keys are not supported
    # default_value - default value to return if key is not present

    upvar 1 $vdict dict

    if {[dict exists $dict $key]} {
        set val [dict get $dict $key]
        dict unset dict $key
        return $val
    } else {
        return $default_value
    }
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
