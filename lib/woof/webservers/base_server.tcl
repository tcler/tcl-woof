# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

namespace eval ::woof::webservers {    
    catch {BaseWebServer destroy}
    oo::class create BaseWebServer {
        constructor {} {
            # Base webserver interface class from which concrete
            # webserver interfaces can be derived.
            #
            # The web server interface class is instantiated when
            # the interpreter is loaded, not once per request.
        }

        method init_log {fac} {
            # Called to initialize the logging facility.
            # fac - the facility name to use for logging.
            #
            # The Woof logging facility calls this method to initialize
            # the logging component of the web server interface.
            #
            # The concrete web server interface class can override this
            # method.
            my variable _facility
            set _facility $fac

            return
        }

        method log {level msg} {
            # Called to log a message
            # level - logging level for the message. Possible values
            #  are defined in Log.
            # msg - text of the message
            #
            # The default implementation is very simplistic. It opens the
            # log file on every write, does not buffer, does not rollover
            # log files. Concrete implementations should override the method.
            # 

            my variable _facility
            set logfile [file join [::woof::master::configuration get log_dir] [::woof::master::configuration get log_file]]
            set fd [open $logfile {CREAT WRONLY APPEND}]
            try {
                puts $fd "[clock format [clock seconds] -format {%a %Y/%m/%d %T} -gmt false] $_facility.$level $msg"
                flush $fd
            } finally {
                close $fd
            }
            return
        }

        method request_environment {request_context} {
            # Retrieves the environment passed by the web server.
            #
            # request_context - opaque request context handle. See
            #  request_init
            # 
            # The environment returned by this method is structured
            # so as to resemble the environment passed in a CGI environment.
            # Woof uses the values to retrieve elements such as the request
            # URL.
            # 
            # Returns the environment as a key value list.

            return [array get ::env]
        }

        method request_init {request_context} {
            # Called to initialize handling of each request.
            #
            # request_context - opaque request context handle passed
            #  to ::woof::handle_request
            #
            # This method is called by Woof to allow the web server
            # interface to do any required initialization of individual
            # requests.
            #
            # The concrete web server interface class can override this
            # method. The default implementation is a no-op.
            #
            # The parameter $request_context should be a handle to the web 
            # server context for this request. It should be passed through 
            # by Woof as received by woof::handle_request and may
            # be required by some web server modules to distinguish
            # between multiple requests being serviced concurrently by
            # the same interpreter.
            #

            return
        }

        method request_parameters {request_context} {
            # Retrieves the parameters for the current request.
            # 
            # request_context - opaque request context handle. See
            #  request_init
            #
            # The method parses and returns the parameters encoded in a 
            # request. Both query and form data are returned.
            # This method must be implemented by the concrete class.
            #
            # Returns the parameters received in the current request.
            woof::error::exception WOOF ConfigurationError "Method request_parameters not overridden by concrete class."
        }

        method server_interface {} {
            # Get the webserver interface module name.
            #
            # This method must be overridden by the concrete class.
            woof::error::exception WOOF ConfigurationError "Method server_interface not overridden by concrete class."
        }

        method output {request_context response} {
            # Sends a response back to the client.
            # request_context - opaque request context handle. See
            #  request_init
            # response - dict structure containing data to be sent back.
            #
            # The method sends the response back to the client. The response
            # structure passed in contains the fields headers, status_line,
            # and content.
            #
            # This method must be overridden by the concrete class.
            woof::error::exception WOOF ConfigurationError "Method 'output' not overridden by concrete class."
        }
    }
}
