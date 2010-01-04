# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

#
# NOTE NAMESPACES ARE RELATIVE.
# So the procs in this file will be defined relative
# to whatever namespace they are being sourced into.

namespace eval errors {
    variable messages
    # Formatted as a nested dictionary. 
    # Top level key is major facility (e.g. WOOF),
    # Second level key is error symbol
    # Third level is content keyed by "message", "help"
    # Top level facilities:
    #   WOOF - internal errors
    #   WOOF_USER - user generated
    set messages \
        [dict create WOOF_USER {
            InvalidRequest {
                message "The request is invalid."
                help "You have requested a page that is invalid or to which you do not have access. Please verify the URL."
            }
            InvalidRequestParams {
                message "The parameters in the request are invalid."
                help "You have requested a page without specifying parameters that are required, or with invalid values."
            }
        } WOOF {
            ConfigurationError {
                message "There is an error in the configuration of the system."
            }
            MultipleRenders {
                message "Multiple calls made to render or redirect the page. Only one is allowed."
                help "Within the processing of a single request, you may only make a single render or redirect call. Make sure every such call is followed by a return from the calling method before any further rendering or redirect calls."
            }
            CorruptOrMissingData {
                message "Data is missing or corrupted."
            }
            MissingFile {
                message "The specified file is missing or could not be read."
            }
            MissingTemplate {
                message "No suitable template was found."
            }
            NotImplemented {
                message "This feature has not been implemented."
            }
            Bug {
                message "An error caused by faulty programming has occured."
            }
        }]
}


proc errors::help {facility symbol} {
    # Returns the help message, if any, associated with the given
    # facility and symbol.
    # facility - the error facility, generally WOOF or WOOF_USER
    # symbol - the symbolic name of the error
    variable messages

    if {[dict exists $messages $facility $symbol help]} {
        return [dict get $messages $facility $symbol help]
    } else {
        return ""
    }
}


proc errors::exception {facility symbol {message ""}} {
    # Raises a Tcl exception in Woof canonical format.
    # facility - the error facility, generally WOOF or WOOF_USER
    # symbol - the symbolic name of the error
    # message - the error message. If none is supplied, the default
    #  message for the error symbol is used.
    # The exception is raised from the caller's context with an
    # error code consisting of the facility, error symbol and the message.

    # TBD - should the built in message always be prefixed to passed in message?
    if {$message eq ""} {
        variable messages
        if {[dict exists $messages $facility $symbol message]} {
            set message [dict get $messages $facility $symbol message]
        }
    }
    return -code error -level 1 -errorcode [list $facility $symbol $message] $message
}

namespace eval errors {
    namespace export exception
}