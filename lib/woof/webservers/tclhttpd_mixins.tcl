namespace eval ::woof::webservers::tclhttpd {
    oo::class create RequestMixin {
        variable _context
        method resource_url {} {
            return [dict get $_context suffix]
        }
    }
}
