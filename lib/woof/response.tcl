# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.


#
# The main response object, populated by the controllers
# depending on what should be sent back to the client
# Mostly translation of Rails AbstractResponse - thanks to those guys
catch {Response destroy}; # To allow re-sourcing
oo::class create Response {
    constructor {} {
        # Constructs an object for returning data to the client.
        #
        # An object of this class, named 'response', is created in the
        # context of every Controller object that handles a request from
        # the client. The application code should use this object to
        # construct the response to be sent back to the client including
        # HTTP headers, content, cookies etc.. The object is then used
        # by the installed web server interface to
        # communicate with the web server to send the appropriate
        # response to the client.

        my variable _status

        # NOTE - experimentation shows the objects created below
        # get automatically destroyed when containing object is destroyed
        # without needing explicit destruction in a destructor.

        # Input cookies
        ::woof::CookiesOut create _cookies
        
        # Any HTTP _headers we might want to send
        ::woof::util::Map create _headers
        # Default content
        my status 200
        _headers set Cache-Control "no-cache"
        # TBD - what should default Content-Type be? Should there be a charset attr ?
        my content_type "text/html"
    }

    # Define methods for accessing contained maps
    # TBD - check if there are more efficient ways to do this, using
    # forward perhaps
    method cookies args {
        # Invokes the CookiesOut object containing the cookies to be sent
        # to the client.
        # args - all arguments are passed on to the wrapped CookiesOut object.
        #
        # This method wraps the CookiesOut object that contains the cookies
        # to be sent to the client. When called without any arguments,
        # invokes the get method of the CookiesOut object. When called
        # with arguments, invokes the object using those arguments.
        #
        # The same CookiesOut object is also made available to application
        # code as the 'ocookies' object. Generally, applications should
        # directly invoke that object instead of calling this method.

        if {[llength $args]} {
            return [_cookies {*}$args]
        } else {
            return [_cookies get]
        }
    }

    method headers args {
        # Retrieves or sets the HTTP headers defined in the object.
        # args - arguments to be passed to the wrapped Map object
        #  containing HTTP headers to be sent to the client.
        # 
        # The response object contains a Map object with the HTTP headers
        # to be sent to the client. This method wraps that object and
        # passes on $args to that object. If invoked without any arguments,
        # returns a list of the HTTP headers that will be sent from
        # this Response object as a flat list of header name and header
        # value pairs. This list will include the response cookies. Note
        # that the list can contain multiple pairs that have the same
        # header name.
        #
        # Generally, application code should not call this method to
        # set header values directly.
        # Instead it should call the other methods of the Response object,
        # such as location, content_type, charset and last_modified that will
        # then set the headers appropriately.
        #
        # On the other hand, web server interface code can call this method
        # to retrieve the set of headers to send back to the client.
        if {[llength $args]} {
            return [_headers {*}$args]
        } else {
            # When called to get all headers, cookie values
            # are merged in. TBD - is this a good idea?
            # Note cookies are multivalued
            set cookie_headers {}
            foreach cookie [_cookies cookies] {
                lappend cookie_headers Set-Cookie $cookie
            }
            return [concat [_headers get] $cookie_headers]
        }
    }

    method status_line {} {
        # Returns the HTTP response status line to be sent to 
        # the client.
        #
        # Returns the full HTTP response line.
        my variable _status
        return [::woof::util::http_response_code $_status]
    }

    method status {{status {}}} {
        # Sets or returns the HTTP response status code to be sent to 
        # the client.
        # status - HTTP integer response code
        # If $status is specified and is not the empty string,
        # sets the HTTP response status code for
        # this object and returns an empty string. Otherwise,
        # returns the currently set HTTP response status code.

        my variable _status

        if {$status ne ""} {
            set _status $status
            return
        } else {
            return $_status
        }
    }

    method location {{loc ""}} {
        # Sets or returns the Location header to be sent in the HTTP response.
        # loc - The value of the location header to be sent.
        # If $loc is specified and not empty, the value of the HTTP Location
        # header is set to $loc and the empty string is returned.
        # Otherwise, returns the location header set in the response or an empty
        # string if no Location header has been set.
        if {$loc ne ""} {
            _headers set Location $loc
            return
        } else {
            return [_headers get Location ""]
        }
    }

    method charset {args} {
        # Set or retrieves the charset attribute sent with the Content-Type
        # header in the HTTP response.
        # args - optional arguments.
        # If no arguments are specified, returns the current setting
        # of the charset attribute. Otherwise, sets the charset attribute
        # of the Content-Type header to the first argument and return
        # an empty string. If the first
        # argument is the empty string, the charset attribute is removed
        # from the header. Remaining
        # arguments, if any, are currently ignored.
        if {[llength $args]} {
            set cs [lindex $args 0]
            set ct [my content_type]
            if {$ct eq ""} {
                # TBD - hardcode text/html?
                set ct "text/html"
            } 
            if {$cs ne ""} {
                append ct "; charset=$cs"
            }
            _headers set Content-Type $ct
            return
        } else {
            # Retrieve value
            # e.g. "text/html; charset=WHATWEWANT  " -> "WHATWEWANT"
            return [string trim [lindex [split [lindex [split [_headers get Content-Type ""] ";"] 1] =] 1]]
        }
    }

    method content_type {args} {
        # Sets or returns the Content-Type header of the HTTP response.
        # args - optional arguments
        # If no arguments are specified, returns the current value
        # of the Content-Type header. Otherwise, sets its value
        # to the first argument and returns an empty string. Remaining
        # arguments, if any, are currently ignored. If the first argument
        # is the empty string, the Content-Type header is removed
        # from the response.
        #
        # The supplied value may contain a charset attribute as well.
        # If it does not, the current charset attribute of the header
        # is preserved.
        #
        # Returns the value of the Content-Type header without
        # the charset attribute.
        
        if {[llength $args]} {
            set ct [lindex $args 0]
            if {$ct eq ""} {
                _headers unset Content-Type
            } else {
                if {[string first "charset" $ct] < 0} {
                    # No charset defined. Preserve what we have
                    set cs [my charset]
                    if {$cs ne ""} {
                        append ct "; charset=$cs"
                    }
                }
                _headers set Content-Type $ct
            }
            return
        } else {
            return [lindex [split [_headers get Content-Type ""] ";"] 0]
        }
    }

    method last_modified {{utc {}}} {
        # Sets or returns the Last-Modified header of the HTTP response.
        # utc - timestamp
        # If no arguments are specified, returns the current value
        # of the Last-Modified header if one has been defined, and an
        # empty string otherwise. 
        #
        # If $utc is specified and not empty,
        # the Last-Modified header is set to its value and an empty
        # string is returned.
        # $utc must be
        # either in the standard HTTP date and time format, or an integer
        # which is then treated as the number of seconds since 
        # 00:00:00 Jan 1 1970 UTC. An error is thrown if the format is
        # neither of these two.
        #

        if {$utc ne ""} {
            if {[string is integer $utc]} {
                set utc [::woof::util::format_http_date $utc]
            } else {
                # Verify format of HTTP date. Just scan and throw away
                # On bad formats, the scan throws an error.
                ::woof::util::scan_http_date $utc
            }
            _headers set Last-Modified $utc
            return
        } else {
            return [_headers get Last-Modified ""]
        }
    }

    method content {args} {
        # Sets or returns the content for the HTTP response
        # args - optional arguments that specify the content.
        # If no arguments are specified, returns the current content
        # stored in the response. If one or more arguments are specified,
        # they are concatenated together and stored
        # as the response content and an empty string returned.
        my variable _content
        if {[llength $args]} {
            set _content [join $args ""]
            return
        } else {
            return [expr {[info exists _content] ? $_content : ""}]
        }
    }

    method reset {} {
        # Currently not implemented.

        # TBD - what should we reset? Content, content type?
    }

    method redirect {url {status 307} {text ""}} {
        # Sets the response to be a HTTP redirect
        # url - the URL to which client is to be redirected
        # status - the HTTP response code to be sent to the client
        # text - The HTML content to sent as part of the HTTP response. Note
        #  this is HTML content and is not HTML-escaped further.
        # 
        if {$text eq ""} {
            set text "<html><body>You are being redirected to <a href='[::woof::util::hesc $url]'>[::woof::util::hesc $url]</a>.</body></html>"
        }
        my reset
        my status $status
        my content $text
        my location $url
    }
}


namespace eval [namespace current] {
    namespace export Response
}
