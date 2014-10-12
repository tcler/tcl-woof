# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Woof! Installation Script
# Utility for Woof! distribution and installation

if {! [package vsatisfies [info tclversion] 8.6]} {
    puts stderr "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
    error "Woof! requires Tcl version 8.6 or later. You are running [info tclversion]"
}

namespace eval installer {
    # TBD - what if script is implicitly invoked on Unix? Does it still get path to executable ?
    # Tcl executable
    variable tclexe [info nameofexecutable]

    # Dir where woof is installed or when running as an installer
    # where the distribution resides
    variable root_dir
    set root_dir [file normalize [file dirname [file dirname [info script]]]]

    # Source tree root
    variable source_root_dir
    set source_root_dir $root_dir

    # Exes for resource editing and compression
    variable upx_exe  [file join $source_root_dir tools win32 upx.exe]
    variable ctcl_exe [file join $source_root_dir tools win32 ctcl.exe]
    
    # Woof! version
    variable woof_version

    # Exit code for script
    variable exit_code 0
    
    # Name of the file manifest used in install
    variable manifest_name "MANIFEST"
}

source [file join [file dirname [info script]] .. lib woof woofversion.tcl]
set installer::woof_version [::woof::version]

proc installer::usage {{msg ""} {code ""}} {
    # Prints a usage description and exits
    # msg - optional message to print
    # code - exit code
    
    global argv0

    if {$code eq ""} {
        set code 1
    }

    if {$msg ne ""} {
        puts stderr $msg
    }

    puts stderr "Usage:"
    puts stderr "\t[info nameofexecutable] $argv0 distribute TARGET_DIR ?options?"
    puts stderr "\t[info nameofexecutable] $argv0 install SERVER INTERFACE ?-installdir DIRECTORY?"

    exit $code
}


proc installer::install_log {msg} {
    # Logs a message to the install log
    # msg - log message
    # The message is logged only if the application has set the
    # opened the log file channel.

    variable log_fd
    variable 
    if {[info exists log_fd]} {
        puts $log_fd "[clock format [clock seconds] -format %T] $msg"
    }
}

proc installer::distribute {target_dir args} {
    # Generates distribution kits for Woof
    # target_dir - path to the directory where the distribution kits are
    #   to be placed. The directory must not exist.
    # -zipper ZIPEXE - ZIP file executable ('zip' by default)
    # -sdx SDXKIT - path to 'sdx.kit' file for generating Tcl kits
    # -tarrer TAREXE - path to the tar exe
    # -gzipper GZIPEXE - path to gzip
    # -fromscm BOOLEAN - if false (default), the working directory is used
    #   as the source directory. If true, the source directory is generated
    #   from the repository.
    # The command generates a woof.zip distribution kit in addition
    # to the single file self-contained executable versions.
    #
    # This command is intended to be executed out of the source
    # tree, not from within a distribution kit.

    variable source_root_dir
    variable woof_version
    variable upx_exe
    variable ctcl_exe
    variable manifest_name

    if {$::tcl_platform(platform) ne "windows"} {
        # ctcs gorc etc. not available on Unix. TBD - need to clean up this mess
        error "Sorry, currently the distribution can only be created on Windows."
    }

    # Note - tarrer defaults to bsdtar since Gnu tar does not properly
    # set directory permissions when tarring on Windows
    array set opts {
        -gzipper gzip
        -zipper zip
        -tarrer bsdtar
        -sdx sdx.kit
        -force false
        -kit all
        -fromscm false
    }
    array set opts $args
    
    if {[file exists $target_dir] && ! $opts(-force)} {
        error "Target directory '$target_dir' already exists."
    }

    set cwd [pwd]
    file mkdir $target_dir
    if {$opts(-fromscm)} {
        set src_dir [file join $target_dir [clock milliseconds]]
        puts "Exporting to $src_dir"
        exec hg archive $src_dir
    } else {
        set src_dir $source_root_dir
    }

    if {$opts(-kit) ne "bowwow"} {
        puts "Copying files"
        set zip_dir [file join $target_dir "woof-$woof_version"]
        file delete -force $zip_dir; # Empty it if it exists
        file mkdir $zip_dir
        file copy -- [file join $src_dir ANNOUNCE.txt] [file join $zip_dir README.txt]
        foreach dir {app config lib public scripts} {
            file copy -- [file join $src_dir $dir] $zip_dir
        }
        file copy -- {*}[glob [file join $src_dir thirdparty lib *]] [file join $zip_dir lib]
        file copy -- [file join $src_dir thirdparty wibble] [file join $zip_dir lib]
        # Generate man pages
        exec -ignorestderr -- [info nameofexecutable] [file join $src_dir scripts ruffian.tcl] [file join $zip_dir public woof_manual.html]

        set textfile_patterns {*.txt *.tcl *.htm *.html *.wtf *.bat *.cmd *.cfg}
        
        if {$opts(-kit) in {zip all}} {
            puts "Building zip distribution"
            puts "Converting line endings to Windows format"
            crlf_tree $zip_dir crlf $textfile_patterns

            # Create a file manifest
            puts "Creating file manifest..."
            distro::build $zip_dir $woof_version -manifest $manifest_name -crlf crlf

            # Note - when zipping, we need to cd to that directory else,
            # zip stores the entire path specified on command line

            # First create a zip archive of the directory.
            set zip_file woof-${woof_version}.zip
            puts "Creating Zip distribution $zip_file"
            cd $target_dir
            exec $opts(-zipper) -r $zip_file [file tail $zip_dir]
            cd $cwd
        }

        if {$opts(-kit) in {targz all}} {
            # For unix folks create a tar.gz
            puts "Building .tar.gz distribution"
            puts "Converting line endings to Unix format"
            crlf_tree $zip_dir lf $textfile_patterns

            # Create a file manifest
            puts "Creating file manifest..."
            distro::build $zip_dir $woof_version -manifest $manifest_name -crlf lf

            set tar_file woof-${woof_version}.tar
            puts "Creating tar.gz distribution ${tar_file}.gz"
            cd $target_dir 
            exec $opts(-tarrer) cf $tar_file [file tail $zip_dir]
            exec $opts(-gzipper) --force $tar_file
            cd $cwd
        }
    }

    # Now a tm file - TBD - do we really need this? For CGI ? For single
    # file distributable?
    if {0} {
        set tm_file [file join $target_dir woof-${woof_version}.tm]
        puts "Creating Zip file for Tcl module"
        # We need to write a "main.tcl" that will be sourced by the tm startup
        # TBD - is the auto_path modification really required? Or should
        # the sourcing Tcl environment already have those libraries?
        set fd [open [file join $target_dir woof main.tcl] w]
        puts $fd {lappend ::auto_path [file join [file dirname [info script]] thirdparty lib]}
        puts $fd {source [file join [file dirname [info script]] lib woof woof.tcl]}
        close $fd
        set cwd [pwd]
        cd [file join $target_dir woof]
        exec $opts(-zipper) -r ../woof-tm.zip .
        cd $cwd
        puts "Creating Tcl module $tm_file"
        exec cmd /c [file join $src_dir tools makeziptm.cmd] [file join $target_dir woof-tm.zip] $tm_file
    }

    if {$opts(-kit) in {all bowwow}} {
        # Now also create a standalone kit 
        puts "Creating bowwow"
        set bowwow_dir [file join $target_dir bowwow-${woof_version}.vfs]
        file delete -force $bowwow_dir
        file mkdir [file join $bowwow_dir lib]
        set bowwow_base wibble;     # Or tclhttpd
        if {$bowwow_base eq "tclhttpd"} {
            file copy [file join $src_dir thirdparty tclhttpd3.5.2 bin] [file join $bowwow_dir]
            file copy [file join $src_dir thirdparty tclhttpd3.5.2 lib] [file join $bowwow_dir lib tclhttpd3.5.2]
            file copy [file join $src_dir thirdparty tclhttpd3.5.2 main.tcl] [file join $bowwow_dir main.tcl]
            file mkdir [file join $bowwow_dir custom]
            file copy -force [file join $src_dir lib woof webservers tclhttpd_server.tcl] [file join $bowwow_dir custom tclhttpd_server.tcl]
        } else {
            file copy [file join $src_dir thirdparty wibble] [file join $bowwow_dir lib wibble]
            file copy [file join $src_dir thirdparty bowwow main.tcl] [file join $bowwow_dir main.tcl]
        }
        # For next two --force is hardcoded - intentional
        file copy {*}[glob [file join $src_dir thirdparty lib *]] [file join $bowwow_dir lib]
        file copy [file join $src_dir lib woof] [file join $bowwow_dir lib]
        file copy [file join $src_dir lib distro] [file join $bowwow_dir lib]
        file copy [file join $src_dir lib ruff] [file join $bowwow_dir lib]
        file copy [file join $src_dir config] $bowwow_dir
        file copy [file join $src_dir app] $bowwow_dir
        file copy [file join $src_dir public] $bowwow_dir
        file copy [file join $src_dir scripts] $bowwow_dir
        # Generate man pages
        exec -ignorestderr -- [info nameofexecutable] [file join $src_dir scripts ruffian.tcl] [file join $bowwow_dir public woof_manual.html]

        distro::build $bowwow_dir $woof_version -manifest $manifest_name -crlf lf
        # TBD - make tclkit path configurable
        set tclkit [file join $src_dir thirdparty tclkits tclkit-cli.exe]
        set bowwow [file join $target_dir bowwow-${woof_version}]
        exec $tclkit [file join $src_dir tools sdx.kit] wrap ${bowwow}.kit -vfs $bowwow_dir
        set bowwow_exe [file join $target_dir bowwow-${woof_version}.exe]
        # Need to copy the executable because we cannot use it as the runtime file
        # directly
        set runtime [file join $target_dir runtime.exe]
        file copy -force $tclkit $runtime
        # Decompress the exe
        exec $upx_exe -d $runtime

	exec $ctcl_exe write_version_resource $runtime -copyright "2014 Ashok P. Nadkarni" -timestamp now -version $woof_version -productversion $woof_version ProductName "BowWow Web Server" FileDescription "BowWow Web Server" CompanyName "Ashok P. Nadkarni" FileVersion "$woof_version.0.0" ProductVersion "$woof_version.0.0"
	exec $ctcl_exe write_icon_resource $runtime "public/images/_woof/woof_icon.ico" -name 1
        exec $tclkit [file join $src_dir tools sdx.kit] wrap ${bowwow}.exe -runtime $runtime -vfs $bowwow_dir
    }
    return
}

proc installer::install_wub {woof_root wub_root args} {
    error "This version of Woof! does not support the Wub web server."
    set wub_local_file {
        lappend ::auto_path \
            "C:/Documents and Settings/ashok/My Documents/src/woof/lib" \
            [file normalize [file join [file dirname [info script]] .. Domains]] \
            [file normalize [file join [file dirname [info script]] .. Utilities]]

        source "C:/Documents and Settings/ashok/My Documents/src/woof/lib/woof/webservers/wub_server.tcl"

        # construct a nub for Woof
        Nub domain /woof/ Woof root "C:/Documents and Settings/ashok/My Documents/src/woof/public"
    }
        
}

proc installer::install_webserver_interface {server module woof_dir args} {
    variable tclexe

    install_log "Installing web server interface $module for server $server."

    switch -exact -- $module {
        cgi {
            # Install the interface module. We need to set the first
            # line to the path to the Tcl interpreter
            # TBD - upgrades are not dealt with here
            set to [file join $woof_dir public ${module}_server.tcl]
            set from [file join $woof_dir lib woof webservers ${module}_server.tcl]
            if {[file exists $to]} {
                # TBD - upgrades are now implemented. But existing files
                # are backed up only if in manifest. Fix that.
                #error "File $to already exists. Upgrades not implemented."
            }
            install_log "Copying $from to $to"
            # Set the shebang line, we do this even on Windows for this file
            # since Apache uses it.
            replace_shebang $from $to
        }
        scgi {
            # Not much to do since the SCGI Woof process is run separately
            # from it original location. Just add the path to the Tcl
            # interp
            # TBD - update manifest
            replace_shebang [file join $woof_dir lib woof webservers scgi_server.tcl]
        }
        websh {
            if {$server ne "apache"} {
                error "Interface websh not supported for server $server."
            }
            # Write out the websh handler. Note there is #! needed at
            # the top since it is read by the websh module, not apache
            set websh_handler [file join $woof_dir public websh_server.tcl]
            if {[file exists $websh_handler]} {
                error "File $websh_handler already exists. Upgrades not implemented."
            }
            install_log "Writing $websh_handler ..."
            file copy [file join $woof_dir lib woof webservers websh_server.tcl] $websh_handler
            
            # Write out the websh conf file
            # Install the interface module. We need to set the first
            # line to the path to the Tcl interpreter
            # TBD - upgrades are not dealt with here
            set websh_dir [file join $woof_dir config websh]
            file mkdir $websh_dir
            set websh_conf [file join $websh_dir websh.conf]
            if {![file exists $websh_conf]} {
                install_log "Writing $websh_conf ..."
                set fd [open $websh_conf w]
                puts $fd {# Set interpreter to be recreated every few requests
                    proc web::interpmap file {
                        web::interpclasscfg $file maxrequests 100
                        return $file
                    }
                }
                close $fd
            }
        }
        default {
            error "Not implemented"
        }
    }
}

proc installer::write_defaults {woof_dir} {
    # Writes the default files for new installations.
    variable root_dir

    foreach {src_path dst_path} {
        config/_application.cfg-template       config/application.cfg
        app/controllers/views/_layout.wtf  app/controllers/views/layout.wtf
    } {
        set dst_path [file join $woof_dir $dst_path]
        if {![file exists $dst_path]} {
            set src_path [file join $root_dir $src_path]
            install_log "Copying '$src_path' to '$dst_path'."
            # TBD - undo / rollback ?
            file copy -- $src_path $dst_path
        }
    }
}

proc installer::install {server module args} {
    # Installs Woof
    # module - the name of the server module to be used (eg. ncgi_server)
    # server - the name of the server (eg. apache)
    # -installdir - the directory where the software is to be installed
    # -tclpath PATH - the fully qualified path to the Tcl installation
    #   to be used for Woof!. Defaults to the directory under which
    #   the executable invoking this script resides.
    # -urlroot URLPREFIX - the URL root under which the application
    #   will reside
    
    variable log_fd
    variable root_dir
    variable woof_version
    variable manifest_name

    switch -exact -- $server {
        iis {
            if {$::tcl_platform(platform) ne "windows"} {
                error "Server $server is not supported on this platform"
            }
        }
        lighttpd {
            if {$::tcl_platform(platform) eq "windows"} {
                error "Server $server is not supported on this platform"
            }
        }
        apache {
            # All platforms supported
        }
        default {
            error "$server is not a supported web server"
        }
    }

    puts "Installing. Please be patient..."

    set timestamp [clock format [clock seconds] -format %y%m%d%H%M%S]
    array set opts $args
    if {[info exists opts(-installdir)]} {
        if {[file isdirectory $opts(-installdir)]} {
            set log_fd [open [file join $opts(-installdir) install-$timestamp.log] w]
            install_log "Starting install of version $woof_version - installing in existing directory $opts(-installdir)."
            install_log "Installation arguments: [join [list $server $module {*}$args] {. }]."

            # Verify that it is a lower or equal version
            # by loading into a separate interpreter
            set ip [interp create]
            set old_version_file [file join $opts(-installdir) lib woof woofversion.tcl]
            if {[file exists $old_version_file]} {
                catch {
                    $ip eval [list source $old_version_file]
                    set old_version [$ip eval ::woof::version]
                }
            }
            if {![info exists old_version]} {
                # Could not get version. Try another way.
                catch {
                    $ip eval "set ::auto_path \[linsert \$::auto_path 0 {[file join $opts(-installdir) lib]}\]"
                    set old_version [$ip eval {package require woof}]
                }
            }
            interp delete $ip
            if {![info exists old_version]} {
                # See if it looks like a Woof install or is just some directory
                if {[file exists [file join $opts(-installdir) $manifest_name]] ||
                    [file exists [file join $opts(-installdir) public]] ||
                    [file exists [file join $opts(-installdir) lib woof]] ||
                    [file exists [file join $opts(-installdir) config]] ||
                    [file exists [file join $opts(-installdir) app]]} {
                    # Looks like Woof
                    error "Could not determine version of Woof! in directory '$opts(-installdir)'."
                } else {
                    # Treat like a new install
                    install_log "There does not seem to be an installation of Woof! in directory '$opts(-installdir)'."
                }
            } else {
                install_log "Version of Woof! already installed is $old_version."
                # Verify the version. Must be >= installed version
                if {[package vcompare $old_version [::woof::version]] > 0} {
                    error "Installed version $old_version is newer than distribution version [::woof::version]."
                }
                # OK to proceed with upgrade
            }
        } elseif {[file exists $opts(-installdir)]} {
            error "$opts(-installdir) exists and is not a directory."
        } else {
            # Directory does not exist. Create it
            file mkdir $opts(-installdir)
            set log_fd [open [file join $opts(-installdir) install-$timestamp.log] w]
            install_log "Starting install of version $woof_version - new installation in directory '$opts(-installdir)'."
            install_log "Installation arguments: [join [list $server $module {*}$args] {. }]."
        }
        install_log "Copying files into target directory '$opts(-installdir)'."
        distro::install $root_dir $opts(-installdir) -manifest $manifest_name -logcmd [namespace current]::install_log
    } else {
        # This is treated as a new (in-place) install
        set opts(-installdir) $root_dir
        set log_fd [open [file join $opts(-installdir) install-$timestamp.log] w]
        install_log "Starting install of version $woof_version - in-place install in directory $opts(-installdir)."
        install_log "Installation arguments: [join [list $server $module {*}$args] {. }]."
    }

    try {
        # Create default files if they do not exist
        write_defaults $opts(-installdir)

        # Set the Tcl interpreter on the scripts. We don't bother to do this
        # on Windows as the line is ignored
        if {$::tcl_platform(platform) eq "unix"} {
            set updates {}
            foreach script_file [glob [file join $opts(-installdir) scripts *.tcl]] {
                lappend updates $script_file
                install_log "Adding shebang line to script $script_file."
                replace_shebang $script_file
                install_log "Marking script $script_file as executable."
                file attributes $script_file -permissions ugo+x
            }
            install_log "Updating manifest."
            distro::refresh $opts(-installdir) $updates -manifest $manifest_name
        }

        install_webserver_interface $server $module $opts(-installdir)

        puts "Installation completed."
        install_log "Installation completed."
    } on error {msg eopts } {
        install_log "Error: $msg"
        return -options $eopts $msg
    } finally {
        close $log_fd
        unset log_fd
    }

    return
}


################################################################
# Utility procs

proc installer::replace_shebang {from {to ""}} {
    # Replace/add the shebang line in the script.
    # from - the file path to be copied
    # to - the destination path. If unspecified or empty string,
    #  the $from file is modified in place
    # Sets the shebang line to the path to the Tcl interpreter. Also marks
    # the file as executable on Unix

    variable tclexe

    if {$to eq ""} {
        set to $from
    }

    set fd [open $from r]
    set data [read $fd]
    close $fd

    # Get rid of shebang line if it exists
    regsub {^#![^\n]*\n} $data {} data

    set fd [open $to w]
    # Write out the Tcl program path on this system
    puts $fd "#!$tclexe"
    puts -nonewline $fd $data
    close $fd

    if {$::tcl_platform(platform) eq "unix"} {
        # Mark it as executable so Apache can run it
        file attributes $to -permissions ugo+x
    }
}


proc installer::crlf {from mode {to ""}} {
    # Convert the given file to have line feed endings
    # from - path of source file
    # mode - cr, crlf, or lf
    # to - path of destination file. If empty or unspecified,
    #  the source file is modified in place
    # The command always results in end-of-line at the end of
    # the file even if original did not have one.

    # We do the simple thing. Just read, map and write back out.
    # Not workable for large files but we do not have those.
    # Other streaming techniques are more cumbersome, including
    # temp files in case from==to, maintaining attributes, permissions etc.

    set fd [open $from];   # Mode is auto
    try {
        set data [read $fd]
    } finally {
        close $fd
    }
    
    if {$to eq ""} {
        set to $from
    }

    set fd [open $to w]
    try {
        fconfigure $fd -translation $mode
        puts -nonewline $fd $data
    } finally {
        close $fd
    }

    return
}

proc installer::crlf_tree {dir mode patterns} {
    # Converts files to the specified line endings
    # dir - directory containing the files to be converted
    # mode - cr, lf or crlf - specifies line endings
    # patterns - list of patterns to use for matching
    # Recursively traverses the specified directory and changes
    # files whose names match one of the specified patterns
    # (using string match -nocase rules) to the specified
    # line endings.
    
    foreach f [fileutil::find $dir [list file isfile]] {
        foreach pat $patterns {
            if {[string match -nocase $pat [file tail $f]]} {
                crlf $f $mode
            }
        }
    }
    return
}

################################################################
# Main routine

proc installer::main {command args} {
    variable exit_code

    # Utility for managing Woof deployments and installations
    # command - the command to carry out, must be one of
    #  'distribute', or 'install'.
    # args - arguments specific to the command to be executed.
    #
    # The program invokes one of several different functions as
    # indicated by the $command parameter. Refer to the documentation
    # of the specific command for more information.

    if {[catch {
        switch -exact -- $command {
            distribute -
            install {
                installer::$command {*}$args
            }
            default {
                usage "Unknown command '$command'"
            }
        }
    } msg]} {
        puts stderr "Error: $msg"
        if {$command eq "install"} {
            puts stderr "Please see the installation log for details."
        }
        set exit_code 1
    }

    return $exit_code
}


if {![info exists ::starkit::topdir]} {
    # Only add paths if not in starkit since that already has appropriate paths set up.
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. lib]]]
    ::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. lib]]
}
if {[catch {
    package require cmdline
    package require md5 2
    package require fileutil
    package require distro
}]} {
    # For development purposes
    set auto_path [linsert $auto_path 0 [file normalize [file join [file dirname [info script]] .. thirdparty lib]]]
    ::tcl::tm::path add [file normalize [file join [file dirname [info script]] .. thirdparty lib]]
    package require cmdline
    package require md5 2
    package require fileutil
    package require distro
}

# If we are not being included in another script, off and running we go
if {[file normalize $::argv0] eq [file normalize [info script]]} {
    installer::main [lindex $argv 0] {*}[lrange $argv 1 end]
    exit $installer::exit_code
}


