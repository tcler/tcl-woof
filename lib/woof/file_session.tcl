# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Implements a simple file based session manager
# TBD - this is a placeholder. Need to ensure atomicity etc.
# TBD - add encryption

namespace eval file_session {
    variable _session_dir
}

proc file_session::fetch {id} {
    variable _session_dir
    if {![info exists _session_dir]} {
        set _session_dir [::woof::master::config get session_dir [file join [::woof::master::config get root_dir] temp]]
    }

    set fd [open [file join $_session_dir _woof_sess_$id] r]
    try {
        return [read $fd]
    } finally {
        close $fd
    }
}

proc file_session::store {id data} {
    variable _session_dir

    if {![info exists _session_dir]} {
        set _session_dir [::woof::master::config get session_dir [file join [::woof::master::config get root_dir] temp]]
    }

    set fd [open [file join $_session_dir _woof_sess_$id] w]
    try {
        puts $fd $data
    } finally {
        close $fd
    }
}

namespace eval file_session {
    namespace export fetch store
    namespace ensemble create
}
