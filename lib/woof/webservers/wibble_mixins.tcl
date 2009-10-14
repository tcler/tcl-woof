namespace eval ::woof::webservers::wibble {
    oo::class create RequestMixin {
        variable _context

        method protocol {} {
            set proto  [lindex [split [dict get $_context protocol] /] 0]
            if {$proto eq ""} {
                return http
            } else {
                return [string tolower $proto]
            }
        }

        method request_method {} {
            return [string tolower [dict get $_context method]]
        }


        method application_url {} {
            return [dict get $_context prefix]
        }

        method resource_url {} {
            return [dict get $_context suffix]
        }

        method query_string {} {
            return [dict get $_context rawquery]
        }

        method remote_addr {} {
            return [dict get $_context peerhost]
        }
    }
}
