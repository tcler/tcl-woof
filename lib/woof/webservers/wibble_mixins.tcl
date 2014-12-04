namespace eval ::woof::webservers::wibble {
    oo::class create RequestMixin {
        variable _context

        method protocol {} {
            set proto  [lindex [split [dict get $_context request protocol] /] 0]
            if {$proto eq ""} {
                return http
            } else {
                return [string tolower $proto]
            }
        }

        method request_method {} {
            return [string tolower [dict get $_context request method]]
        }


        method application_url {} {
            return [dict get $_context options prefix]
        }

        method resource_url {} {
            # Should always return url beginning with "/" The suffix may or
            # or may not have a / depending on url root. Easiest to
            # just strip off if any and add one.
            return "/[string trimleft [dict get $_context options suffix] /]"
        }

        method query_string {} {
            # rawquery includes "?" prefix - remove it
            if {[dict exists $_context request rawquery]} {
                return [string range [dict get $_context request rawquery] 1 end]
            }
        }

        method remote_addr {} {
            return [dict get $_context request peerhost]
        }
    }
}
