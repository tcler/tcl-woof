# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

# Contains the master interpreter for Woof which creates the slave safe
# interpreters that actually handle client requests

package require Tcl 8.6
package require fileutil

# The following two packages are loaded into the master, not the web
# interpreter because they load binaries without Tcl_SafeInit entry
# points and hence cannot be loaded into safe interpreters.
# TBD - are these packages even really required once we do proper
# session id generation ?
package require md5
package require uuid

namespace eval ::woof::master {
    # Where the woof package script is
    variable _script_dir [file normalize [file dirname [info script]]]


    # The root directory of Woof
    variable _woof_root
    # Normal case (not in a starkit) - woof root is two levels up from
    # us. Note this is only the default. The woof_init will reset
    # if so specified.
    set _woof_root [file normalize [file join [file dirname [info script]] .. ..]]

    # The interpreter used for executing web commands
    variable _winterp
    proc app_interp {} {
        # Returns the Tcl interpreter running the Woof! application. 
        #
        # Will raise an error if the application interp has not been created
        # yet.
        variable _winterp
        return $_winterp
    }
}

# Source map and errors under the woof namespace as that's where much
# code expects them to be loaded
namespace eval ::woof {
    source [file join $::woof::master::_script_dir errors.tcl]
    source [file join $::woof::master::_script_dir map.tcl]
}

# Source filecache and configuration under woof::master as they
# will only accessed under master
namespace eval ::woof::master {
    source [file join $::woof::master::_script_dir filecache.tcl]
    source [file join $::woof::master::_script_dir configuration.tcl]
    source [file join $::woof::master::_script_dir file_session.tcl]
}

# The ::woof::safe namespace is used for commands that are aliased
# into the safe interpreter
namespace eval ::woof::safe { }

proc ::woof::safe::package_loader {ip name args} {
    # Loads the specified package into the specified interpreter
    # ip - interpreter into which package is to be loaded
    # name - name of the package
    # args - any additional package requirements
    #
    # This is intended to be aliased into safe interpreters to
    # locate packages. Any package that is allowed in the
    # master interpreter will be allowed in the slave so USE WITH
    # CARE, for example, only during initialization.
    
    try {
        $ip eval [::woof::master::get_package_load_command $name {*}$args]
    } on error {msg eropts} {
        # TBD - log
        # We catch errors as to not pass any specific stack info to safe
        # intepreters
        error "Could not load package $name"
    }
}

proc ::woof::safe::encoding_alias {command args} {
    if {$command eq "system" && [llength $args]} {
        error "Setting of system encoding not allowed in safe interpreter"
    }

    if {$command eq "dirs"} {
        error "encoding subcommand dirs not allowed in safe interpreter"
    }

    return [encoding $command {*}$args]
}

proc ::woof::safe::source_alias {ip args} {
    # Safe alias for the Tcl source command
    # ip - safe interpreter invoking the source command
    # args - arguments passed on to the Tcl source command
    #
    # The command invokes the Tcl source command in the interpreter $ip
    # after verifying that the file is being from a permitted area.
    
    # Following code modified from the AliasSource command in the Tcl Safe
    # package

    set argc [llength $args]
    # Extended for handling of Tcl Modules to allow not only "source
    # filename", but "source -encoding E filename" as well.
    if {[lindex $args 0] eq "-encoding"} {
        incr argc -2
        set encoding [lrange $args 0 1]
        set at 2
    } else {
	    set at 0
        set encoding {}
    }
    if {$argc != 1} {
        set msg "wrong # args: should be \"source ?-encoding E? fileName\""
        ::woof::master::log err "$msg ($args)"
        return -code error $msg
    }

    # TBD - should we specify any -cachecontrol options ?
    set file [::woof::master::filecache locate [lindex $args $at]]
    if {$file eq ""} {    
        ::woof::master::log err "Attempt to source file '[lindex $args $at]' failed, either not found or not permitted."
        return -code error "not found"
    }
	
    # Allowed, source it in slave
    if {[catch {
        # We use catch here because we want to catch non-error/ok too
        ::interp invokehidden $ip source {*}$encoding $file
    } msg]} then {
        ::woof::master::log err $msg
        return -code error "script error"
    }

    return $msg
}

proc ::woof::safe::file_alias {subcommand args} {
    # Safe alias for the Tcl file command
    # subcommand - subcommand of the file command
    # args - any additional arguments to be passed to the file command
    # Only the syntactic file name manipulation commands are allowed
    if {$subcommand in {dirname extension join pathtype rootname split tail}} {
        return [file $subcommand {*}$args]
    }
    error "Subcommand $subcommand unknown or not allowed."
}


proc ::woof::safe::filecache_locate_alias {trailer args} {
    # Safe wrapper around FileCache.locate method.

    # TBD - verify that dirs are all allowed directories
    # Note trailer is trailing file portion but could be absolute path
    # as well
    
    set opts {}
    foreach opt {-relativeroot -cachecontrol -dirs} {
        if {[dict exists $args $opt]} {
            lappend opts $opt [dict get $args $opt]
        }
    }
    return [::woof::master::filecache locate $trailer {*}$opts]
}

proc ::woof::safe::filecache_read_alias {trailer args} {
    # Safe wrapper around FileCache.read method
    #
    # We do not support -contentvar option of filecache because
    # of the way upvar/uplevel work with aliases across interpreters
    # Thus the interface is a bit different

    # The filecache jails are intended to verify access is to allowed
    # areas so we don't check here.

    set opts {}
    foreach opt {-relativeroot -dirs -cachecontrol -defaultcontent -translation} {
        if {[dict exists $args $opt]} {
            lappend opts $opt [dict get $args $opt]
        }
    }

    return [::woof::master::filecache read $trailer {*}$opts]
}

proc ::woof::safe::map_file_to_url_alias {path url_map} {
    # Map a file path to a URL
    # path - file path to be mapped. Must not contain . or .. path
    #   components.
    # url_map - a list containing alternating elements of directories and the
    #   corresponding URL
    # Maps the specified file path to the corresponding URL. The first
    # matching URL is returned where a match means the URL's corresponding
    # file system directory is an ancestor of $path.
    # If there is no match, an empty string is returned.

    # Note - we do not use 'file normalize' here because that resolves
    # links which we do not want.

    set parts [file split $path]
    if {[lsearch -exact $parts "."] >= 0 ||
        [lsearch -exact $parts ".."] >= 0} {
        error "Path $path contains relative path components (. or ..)."
    }

    #ruff
    # If path is relative, it is relative to the Woof public directory.
    switch -exact -- [file pathtype $path] {
        relative {
            set path [file join [::woof::master::config get public_dir] $path]
        }
        volumerelative -
        absolute {
            if {$::tcl_platform(platform) eq "windows"} {
                set path [file join $path]; # Convert \ to / 
            }
        }
        default {
            error "Unknown file path type [file pathtype $path]."
        }
    }

    # fileutil::stripPath has a bug where 
    #   stripPath c:/temp c:/tempx/foo/bar
    # returns foo/bar else we could have used that

    # Search for a matching directory.
    if {$::tcl_platform(platform) eq "windows"} {
        set equal [list string equal -nocase]
    } else {
        set equal [list string equal]
    }
    foreach {dir url} $url_map {
        if {$::tcl_platform(platform) eq "windows"} {
            set dir [file join $dir]; # \ -> /
        }
        set dir_len [string length $dir]
        if {[{*}$equal -length $dir_len $dir $path]} {
            # Check that it is not a partial path component - next
            # char must be / or 
            if {[string index $path $dir_len] in [list "" /]} {
                # yep, a match
                return "[string trimright ${url} /][string range $path $dir_len end]"
            }
        }
    }

    return ""
}

proc ::woof::safe::read_route_file_alias {} {
    set fn [::woof::master::config get route_file]
    if {[file readable $fn]} {
        set fd [open $fn]
        try {
            return [read $fd]
        } finally {
            close $fd
        }
    }
    return ""
}

proc ::woof::unsafe_file_command_proxy {ip args} {
    # Proxy the 'file' command into a safe interp WITHOUT safeguards
    #   ip - interp into which the command is being proxied
    #   args - arguments to pass to the file command
    # The command simply aliases the standard Tcl file command
    # into a safe interp. It should be only accessed during initialization
    # and removed before accepting external requests. It is needed
    # because some 8.6 betas are broken in their handling of file
    # inside interps.
    return [file {*}$args]
}

proc ::woof::master::create_web_interp {} {
    # Create the web interpreter and load packages into it
    
    set ip [interp create -safe]
    
    # During initialization, we let the safe interpreter source
    # anything it wants
    interp expose $ip source
    interp expose $ip load
    # Some 8.6 betas have broken file commands inside safe interps
    # so we have to use an alias - TBD
    interp alias $ip ::file {} ::woof::unsafe_file_command_proxy $ip

    # Since it is safe interpreter, we need to set up a package loading
    # mechanism for it.
    $ip eval {package unknown woof_package_loader}
    interp alias $ip ::woof_package_loader {} ::woof::safe::package_loader $ip

    # For some obscure reason, tclhttpd insists on loading md5 1.x.
    # We copy their code for hiding the differences.
    # See the note above for md5 package 
    if {[package vcompare [package present md5] 2.0] > -1} {
        # we have md5 v2 - it needs to be told to return hex
        interp alias $ip ::woof::util::md5hex {} ::md5::md5 -hex --
    } else {
        # we have md5 v1 - it returns hex anyway
        interp alias $ip ::woof::util::md5hex {} ::md5::md5
    }

    # Load Woof! into safe interpreter.
    $ip eval {package require woof}

    # Make a copy of the config in safe interp, and freeze it
    $ip eval [list ::woof::util::Map create ::woof::config [config get]]
    $ip eval {::woof::config freeze}

    # Now hide the exposed unsafe commands
    interp hide $ip source
    interp hide $ip load
    interp alias $ip ::file {}

    # Now enable the safe version of file command and source commands
    $ip alias ::file ::woof::safe::file_alias
    $ip alias ::source ::woof::safe::source_alias $ip
    $ip alias ::encoding ::woof::safe::encoding_alias 

    # Map our chosen session manager (currently we only have file :-)
    $ip alias ::woof::session_manager ::woof::master::file_session

    # Misc aliases
    $ip alias ::woof::read_route_file ::woof::safe::read_route_file_alias
    $ip alias ::woof::map_file_to_url ::woof::safe::map_file_to_url_alias

    return $ip
}

proc ::woof::master::get_package_load_command {name args} {
    # Get the command to load a package without actually loading the package
    # name - name of package
    # args - any additional package requirements
    # package ifneeded can return us the command to load a package but
    # it needs a version number. package versions will give us that
    set versions [package versions $name]
    if {[llength $versions] == 0} {
        # We do not know about this package yet. Invoke package unknown
        # to search
        {*}[package unknown] $name {*}$args
        # Check again if we found anything
        set versions [package versions $name]
        if {[llength $versions] == 0} {
            error "Could not find package $name"
        }
    }

    # [llength $versions] is non-0 at this point

    if {[llength $args]} {
        # Find first that satisfies requirement
        set req [lindex $args 0]
        foreach ver $versions {
            if {[package vsatisfies $ver $req]} {
                return [package ifneeded $name $ver]
            }
        }
        error "Could not find suitable version $req of package $name"
    }

    # No requirements, return first available. 
    return [package ifneeded $name [lindex $versions 0]]
}


proc ::woof::master::init {server_module {woof_root ""} args} {
    # Called by the web server to initialize the Woof subsystem.
    # server_module - the name of the web server interface module
    #   corresponding to the web server in use.
    # woof_root - directory where Woof is installed.
    # 
    # The main web server must call this command to initialize the Woof
    # subsystem. 
    variable _woof_root
    variable _winterp

    if {$woof_root ne ""} {
        set _woof_root $woof_root
    } else {
        #ruff
        # If $woof_root is not specified by caller, then the value
        # of the environment variable WOOF_ROOT is used, if set. Otherwise,
        # a system and server specific default is used that is set up
        # when the package is loaded.
        if {[info exists ::env(WOOF_ROOT)]} {
            set _woof_root $::env(WOOF_ROOT)
        }
    }

    if {![file isdirectory $_woof_root]} {
        ::woof::errors::exception WOOF ConfigurationError "The Woof! root directory '$_woof_root' does not exist."
    }

    #ruff
    # A Configuration object is instantiated to contain
    # static Woof configuration information. This is exported and
    # available to all components, including applications as the
    # config object.
    Configuration create config $_woof_root
    config set server_module $server_module
    
    #ruff
    # -jails DIRLIST - list of directory paths. If specified and not empty,
    #  files under one of these paths can also be accessed through the cache.
    #  This is in addition to the files in the public and app directories.
    if {[info exists ::starkit::topdir]} {
        # We are running inside a starkit.
        set libdir [file join $::starkit::topdir lib]
    } else {
        set libdir [file join $_woof_root lib]
    }
    set jails [list [config get public_dir] \
                   [config get app_dir] \
                   $libdir \
                   {*}[config get lib_dirs]]

    if {[dict exists $args -jails]} {
        lappend jails {*}[dict get $args -jails]
    }

    # Add the application library directory to auto_path
    set ::auto_path [linsert $::auto_path 0 [file join [config get app_dir] lib]]

    # Init the file cache.
    FileCache create filecache \
        -relativeroot [config get public_dir] \
        -jails $jails
    # Note the filecache log method will be redefined below once the webserver
    # is initialized to log to the webserver log

    # Create the safe web interpreter that will be used to
    # to service client requests.
    set _winterp [create_web_interp]

    $_winterp alias ::woof::filecache_locate ::woof::safe::filecache_locate_alias
    $_winterp alias ::woof::filecache_read ::woof::safe::filecache_read_alias

    #ruff
    # Any directories specified in the config are
    # created if necessary.
    foreach dir {temp_dir session_dir log_dir} {
        file mkdir [config get $dir]
    }

    #ruff
    # The Woof system expects certain services to be provided by the
    # web server through a web server interface module. This module
    # is loaded from the webservers
    # subdirectory under the Woof library. Then the interface
    # class WebServer, which should be defined in the
    # ::woof::webservers::SERVER_MODULE namespace,  is instantiated 
    # as the exported object ::woof::webserver. It should implement as
    # methods various services expected by Woof

    # TBD - do we need to restrict access to ::woof::webserver methods
    # for security reasons ?
    [::woof::webservers::${server_module}::init] create ::woof::webserver
    $_winterp alias ::woof::webserver ::woof::webserver

    #ruff
    # The command also initializes the logging subsystem by instantiating
    # the Log class. This object, named 'log', is also exported and
    # available from all other components.
    Log create log [config get app_name] ::woof::webserver
    log setlevel [config get log_level info]

    # Have the file cache log errors to the master log. We have it log
    # at info level because at err level there might be too many errors
    # logged when it searches for files.
    oo::objdefine filecache {
        method log {msg} { ::woof::master::log err $msg }
    }

    # TBD - do we need to restrict access to ::woof::log methods
    # for security reasons ?
    $_winterp alias ::woof::log ::woof::master::log

    $_winterp eval {
        namespace eval ::woof {
            namespace export webserver config log
        }
    }

    # Finally create an alias in the master to call process_request in
    # the slave. This is significantly faster than $_winterp eval if
    # the request context is large amount of data
    interp alias {} handle_request_in_slave $_winterp ::woof::handle_request

    # Now tell the slave interpreter to init itself
    $_winterp eval ::woof::init

    # If any application-specific code needs to be loaded, load it
    set app_master_file [file join [::woof::master::config get app_dir] app_master.tcl]
    if {[file exists $app_master_file]} {
        uplevel #0 [list source $app_master_file]
    }

    #ruff
    # Returns the path to the safe interpreter.
    return $_winterp
}

proc ::woof::master::process_request {{request_context ""}} {
    # Called by a webserver to handle a client request.
    # request_context - opaque request context handle passed through to
    #  the web server module to identify this request. See
    #  request_init.
    # Passes the request on to the web interpreter. See ::woof::handle_request
    # for more information.

    #variable _winterp
    return [handle_request_in_slave $request_context]
    # return [$_winterp eval [list ::woof::handle_request $request_context]]
}


#
# Code execution starts here

# Set up auto path to include Woof! library
set ::auto_path [linsert $::auto_path 0 [file join $::woof::master::_woof_root lib]]

namespace eval ::woof {
    source [file join $::woof::master::_script_dir util.tcl]
}
namespace eval ::woof::master {
    source [file join $::woof::master::_script_dir log.tcl]
    source [file join $::woof::master::_script_dir webservers base_server.tcl]
}
