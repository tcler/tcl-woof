# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# TBD - allow a facility to store log messages until the real logger is enabled

# To allow resourcing
catch {Log destroy}
oo::class create Log {
    constructor {facility {writer ""}} {
        # Provides a multi-level logging 
        # facility - the facility or component logging
        # writer - the underlying log writer to use
        # The Log class provides a mechanism to set logging
        # levels and enable/disable logging.
        #
        # The actual logging is done by the attached
        # log message writer, generally the logging
        # component provided by the web server.
        #
        # If the $writer is empty, then log messages are
        # collected internally and then written when the attach
        # method is invoked to specify a writer.

        my variable _facility
        my variable _writer
        my variable _levels
        my variable _pending

        set _writer ""
        set _pending {}
        set _facility $facility

        #ruff
        # Log messages may be logged at the following levels:
        # debug, info, notice, warn, err, crit, alert and emerg.
        # These level definitions are the same as those used
        # by syslog. The initial logging level is set to info.
        array set _levels {
            debug  0
            info   1
            notice 2
            warn   3
            err  4
            crit   5
            alert  6
            emerg 7
        }

        my setlevel info

        my attach $writer
    }

    method attach {writer} {
        # Attaches a log writer to be called to log messages.
        # writer - a class or command prefix to be called.
        #
        # The method returns the old writer object for caller to dispose 
        # of if necessary unless the new one is the same as the old 
        # or there was no previous
        # writer in which case an empty string is returned.
        #
        # The writer must support the following methods or subcommands:
        #  init_log - called to initialize the logging. An additional
        #    parameter is passed which is the facility name.
        #  log - called to actually log a message. Two additional
        #    parameters are passed. The first is the log level, and
        #    the second is the message itself.
        my variable _writer
        my variable _facility

        if {$writer eq $_writer} {
            # No change
            return ""
        }

        set prev $_writer
        set _writer $writer
        if {$_writer ne ""} {
            my variable _pending

            $_writer init_log $_facility
            #ruff
            # If there are any pending messages, they are passed
            # to writer as soon as it is attached.
            foreach msgrec $_pending {
                lassign $msgrec pend_level pend_msg
                # Note level filtering will depend on current setting, not
                # when the pended message was queued...shrug
                $_writer log $pend_level $pend_msg
            }
            set _pending {}
        }

        return $prev
    }

    method setlevel level {
        # Sets the logging level.
        # level - the new logging level to set
        # All messages at a priority higher than or equal to the
        # specified level are logged. Messages logged at a lower
        # level are discarded.
        #
        my variable _levels
        foreach l [array names _levels] {
            if {$_levels($l) < $_levels($level)} {
                # Disable logging
                oo::objdefine [self] method $l args {}
            } else {
                # Enable logging
                oo::objdefine [self] method $l msg "my write $l \$msg"
            }
        }
    }

    method write {level msg} {
        # Writes a message to the log.
        # level - the logging level at which the message is to be written
        # msg - the message to log
        # If no log writer has been attached, the message is kept in a pending
        # queue and written when the log writer is attached.
        #
        # Note this method writes to the log irrespective of the log level
        # set through the setlevel method.
        my variable _writer

        if {(![info exists _writer]) || ($_writer eq "")} {
            my variable _pending
            lappend _pending [list $level $msg]
            return
        }

        $_writer log $level $msg
        return
    }

    method debug msg {
        # Writes a message to the log file at level debug
        # msg - message to write
        # If the log level is set to debug, the message is logged to the log
        # file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method info msg {
        # Writes a message to the log file at level info
        # msg - message to write
        # If the log level is set to info or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method notice msg {
        # Writes a message to the log file at level notice
        # msg - message to write
        # If the log level is set to notice or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method warn msg {
        # Writes a message to the log file at level warn
        # msg - message to write
        # If the log level is set to warn or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method err msg {
        # Writes a message to the log file at level err
        # msg - message to write
        # If the log level is set to err or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method crit msg {
        # Writes a message to the log file at level crit
        # msg - message to write
        # If the log level is set to crit or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method alert msg {
        # Writes a message to the log file at level alert
        # msg - message to write
        # If the log level is set to alert or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

    method emerg msg {
        # Writes a message to the log file at level emerg
        # msg - message to write
        # If the log level is set to emerg or below, the message is logged
        # to the log file. Otherwise it is silently discarded.

        # Empty placeholder - method is actually created in object at run time
    }

}
