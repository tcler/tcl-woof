# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# TBD - this whole class is a placeholder. Need to ensure atomicity etc.
# TBD - add encryption
# TBD - create the session class in lazy fashion - do not create anything
#   internally until asked for. Caller can pass it a command to get the
#   session id (e.g. from cookie) if and when needed
catch {Session destroy};        # To allow resourcing
oo::class create Session {
    superclass ::woof::util::DirtyMap

    constructor {{id ""} args} {
        # Container for persistent session data.
        #
        # id - the session id for the session.
        #
        # A session is a container for data that is to be persisted across
        # web requests. It is identified by a session id that is generally
        # stored on the client side (e.g. as a cookie) and passed in
        # every request to associate the request with a particular session.
        # When a request comes in, Woof! creates a 'session' object which
        # may correspond to a new session or contain content of an existing
        # session to which the request has been mapped. Application code
        # may access and store items in this session using the standard
        # Map interfaces.
        #
        # If the parameter $id is an empty string, a new session is created.
        # If parameter $id is not an empty string,
        # the session content for the corresponding session
        # is restored from persistent storage. An error is generated if
        # no corresponding session data is found.
        #

        next;                   # Initialize superclass

        my variable _session_dir; # Where session files are stored
        my variable _id_name;     # name used for session ids
        my variable _new;         # New or existing session?

        #ruff
        # -id_name SESSION_ID_NAME - specifies SESSION_ID_NAME to be
        #  used as the name of the field containing the session id.
        #  By default the name 'session_id' is used.
        if {[dict exists $args -id_name]} {
            set _id_name [dict get $args -id_name]
        } else {
            set _id_name session_id
        }
        #ruff
        # -dir PATH - the path to the directory where session files are
        #  stored. By default, session files are stored in the current 
        #  directory.
        if {[dict exists $args -dir]} {
            set _session_dir [dict get $args -dir]
        } else {
            set _session_dir .
        }

        # Check if a persistent session exists and load it.
        # If id specified, try and open the file, else create new one
        if {$id eq ""} {
            set _new true
        } else {
            my set $_id_name $id
            my load
            set _new false
        }
    }

    method id {} {
        # Returns the session id for this session.
        my variable _id_name
        my variable _session_dir

        if {![my exists $_id_name id]} {
            # New session so generate a new id and the path
            # where to store the session data
            set id [::woof::util::generate_session_id]
            my set $_id_name $id
        }
        return $id
    }

    method load {} {
        # Loads session data from session storage
        my variable _session_dir
        my variable _id_name

        set id [my id]
        set fd [open [file join $_session_dir ${_id_name}_$id] r]
        try {
            set data [read $fd]
            # Make sure our id is in there. Else corrupt
            if {[dict exists $data $_id_name] &&
                [dict get $data $_id_name] eq $id} {
                # OK, fine
                my set {*}$data
                my clean;       # Mark as unmodified
            } else {
                # This error will be caught and re-raised by on error clause
                error "Session $id file is missing session id or has a different id value."
            }
        } on error msg {
            ::woof::log error "Session data for session $id is unreadable or corrupt. $msg"
            ::woof::errors::exception WOOF CorruptOrMissingData "Session $id has corrupt or missing data. $msg"
        } finally {
            close $fd
        }
    }

    method new? {} {
        # Indicates if this session was created in this request
        #
        # Returns true if the session is a new one created in this request.
        # If the session was an existing one created in a previous request,
        # returns false.
        my variable _new
        return $_new
    }

    method commit {{force false}} {
        # Commits the session content to persistent storage.
        #
        # Returns the session id for the session.
        #
        # The session may be restored by creating a new Session object using
        # the returned session id.

        set id [my id]

        if {$force || [my dirty?]} {
            my variable _session_dir
            my variable _id_name
            set fd [open [file join $_session_dir ${_id_name}_$id] w]
            try {
                puts $fd [my get]
                my clean;       # Mark as unmodified
            } finally {
                close $fd
            }
        }
        return $id
    }

}

namespace eval [namespace current] {
    ::woof::util::export_all
    namespace export Session
}
