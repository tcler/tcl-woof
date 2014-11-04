# Create the controller class. Note the class name is not
# namespace-qualified as the file is automatically sourced
# in the correct namespace.
oo::class create FibonacciController {
    superclass ApplicationController
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args
        pagevar set title "Fibonacci Generator"
        pagevar set stylesheets { fibonacci.css pure-skin-fibonacci.css}
        pagevar set main {cssclasses {+ pure-skin-fibonacci}}
        pagevar set sidebar {cssclasses {+ pure-skin-fibonacci}}
    }
}

oo::define FibonacciController {
    method generate {} {
        # Generate the next number in the sequence. The sequence generated
        # so far is stored in the session.

        # Declare a member variable sequence to hold the Fibonacci sequence.
        # All member variables are automatically available for use in
        # the view templates.
        my variable seq

        # If the user has specified the length of the desired sequence,
        # use it, else use what we have in the session storage, else
        # initialize to the first two elements in sequence.
        if {![params exists numfibos num_fibos]} {
            # User has not specified length to generate
            if {[session exists num_fibos num_fibos]} {
                incr num_fibos; # One more than last time
                if {$num_fibos > 50} {
                    set num_fibos 50
                }
            } else {
                # Not in session storage either (first call)
                set num_fibos 2
            }
        }

        if {(![string is integer -strict $num_fibos]) ||
            $num_fibos > 50 ||
            $num_fibos < 1} {
            flash set error_message "The length of the requested sequence must be an integer between 1 and 50."
            my redirect -action showerror
            return
        }

        if {$num_fibos == 1} {
            set seq {0}
        } else {
            set seq {0 1}
            for {set i 2} {$i < $num_fibos} {incr i} {
                lappend seq [expr {[lindex $seq end-1]+[lindex $seq end]}]
            }
        }

        # Store last number back in the session for the next request
        session set num_fibos $num_fibos
    }
    method help {} {
    }
    method showerror {} {
        page store main "<p style='color: red; font-weight: bold;'>[flash get error_message {An error has occurred!}]</p>"
    }
}
