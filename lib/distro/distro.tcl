# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof! root directory for license

# Package distro
# Commands for packaging and installing a distribution

package require Tcl 8.5
package require csv
package require fileutil
package require md5

namespace eval distro {
    variable version 0.3

    # Array keeping track of bundles, indexed by an id. Each
    # element is a dictionary with the following keys:
    #  path - path to the distribution
    #  manifest - a dictionary containing the file manifest for
    #   the distribution
    #  version - application version
    #  manifest_name - name of the manifest file
    variable distros
    array set distros {}

    # Counter to keep track of distro ids
    variable id_counter

    # Dir where this file is
    variable package_dir
    set script_dir [file normalize [file dirname [file dirname [info script]]]]

    # Various manifest file settings
    variable manifest_defaults
    # Default name for file manifest
    set manifest_defaults(filename) "MANIFEST"
    # Prefix character for special manifest lines
    set manifest_defaults(prefix_char) "!"
    # Prefixes for manifest lines
    set manifest_defaults(version_prefix) "$manifest_defaults(prefix_char)version"
    set manifest_defaults(file_prefix) "$manifest_defaults(prefix_char)file"
}


proc distro::distro {path args} {
    # Makes a new distribution object
    #  path - path to where the distribution files reside
    #  -manifest NAME - the name to use for the file manifest
    # Creates a new empty distribution object and returns its id.
    # The application must then use commands to either create
    # the distribution (e.g. build_manifest) or to install it.
    variable id_counter
    variable distros
    variable manifest_defaults

    array set opts [list -manifest $manifest_defaults(filename)]
    array set opts $args

    set id distro_[incr id_counter]

    # Note path need not exist yet. Caller could add files to it later.
    # Also we store both original path and normalized path as we might
    # need both later to calculate relative paths of added files (future
    # enhancement)
    set distros($id) [dict create \
                          path $path \
                          npath [file normalize $path] \
                          version 0.0 \
                          manifest_name $opts(-manifest)]
    return $id
}

proc distro::release {id} {
    # Releases all resources for a distribution
    # id - id of the distribution object as returned by distro
    variable distros
    unset -nocomplain $distros($id)
}

proc distro::build_manifest {id version} {
    # Builds the manifest for a distribution
    # id - id of the distribution as returned by the distro command
    # version - the version of the distribution
    # The command builds a manifest based on all files in the distribution
    # directory. The built manifest is not written to disk.
    # The created file manifest is keyed by the relative path
    # of each file.
    variable distros
    variable manifest_defaults

    dict set distros($id) version $version

    set nocase [expr {$::tcl_platform(platform) eq "windows" ? "-nocase" : ""}]

    set dir [dict get $distros($id) npath]

    # Get rid of existing manifest
    dict set distros($id) manifest [dict create]
    foreach f [fileutil::find $dir [list file isfile]] {
        # Skip manifest itself in case an old copy exists
        set rel_path [fileutil::stripPath $dir $f]
        if {[string equal {*}$nocase [dict get $distros($id) manifest_name] $rel_path]} continue
        update_manifest_entries $id $rel_path
    }
}

proc distro::save_manifest {id {crlf auto}} {
    # Saves the current manifest for the specified distribution
    # id - id of the distribution as returned by the distro command
    variable distros
    variable manifest_defaults

    set manifest [dict get $distros($id) manifest]
    set fd [open [file join [dict get $distros($id) npath] [dict get $distros($id) manifest_name]] w]
    fconfigure $fd -translation $crlf

    # Always start with a version line
    puts $fd [::csv::join [list $manifest_defaults(version_prefix) [dict get $distros($id) version]]]
    try {
        foreach pathkey [lsort -dictionary [dict keys $manifest]] {
            set vals [list $pathkey \
                          [dict get $manifest $pathkey size] \
                          [dict get $manifest $pathkey md5]]
            if {[string index $pathkey 0] eq $manifest_defaults(prefix_char)} {
                # Distinguish file path from commands
                set vals [linsert $vals 0 $manifest_defaults(file_prefix)]
            }
            puts $fd [::csv::join $vals]
        }
    } finally {
        close $fd
    }
    return
}

proc distro::update_manifest_entries {id args} {
    # Updates the manifest entry for the specified files
    # id - id of the distribution as returned by the distro command
    # args - file paths, either relative or absolute, but assumed to lie
    #   inside the distribution directory.
    variable distros

    set dir [dict get $distros($id) npath]
    foreach path $args {
        if {[file pathtype $path] eq "relative"} {
            set rel_path $path
            set path [file join [dict get $distros($id) npath] $path]
        } else {
            set rel_path [fileutil::stripPath $dir [file normalize $path]]
            if {[file pathtype $rel_path] ne "relative"} {
                error "File $path lies outside the distribution directory $dir."
            }
        }

        dict set distros($id) manifest $rel_path size [file size $path]
        dict set distros($id) manifest $rel_path md5 [md5::md5 -hex -filename $path]
    }

    return
}

proc distro::read_manifest {id} {
    # Reads a manifest from a file
    # id - id of the distribution as returned by the distro command
    # Reads in the manifest file for a distribution. No error is generated
    # if no manifest file exists. The existing manifest for the distribution
    # is discarded.

    variable distros
    variable manifest_defaults

    set nocase [expr {$::tcl_platform(platform) eq "windows" ? "-nocase" : ""}]

    # Get rid of existing manifest
    dict set distros($id) manifest [dict create]

    set dir [dict get $distros($id) npath]
    set manifest_file [file join [dict get $distros($id) npath] [dict get $distros($id) manifest_name]]
    if {![file exists $manifest_file]} {
        return;                 # No error, empty manifest
    }
    set linenum 0
    fileutil::foreachLine line $manifest_file {
        incr linenum
        try {
            # Trim whitespace because hand-editors may leave
            # whitespace between commas. Note this means
            # file names cannot have leading or trailing spaces
            # but is probably more robust in practice.
            set fields {}
            foreach field [::csv::split $line] {
                lappend fields [string trim $field]
            }
            # Check if special command
            set first [lindex $fields 0]
            # !version ?
            if {$first eq $manifest_defaults(version_prefix)} {
                set ver [lindex $fields 1]
                if {$ver ne ""} {
                    dict set distros($id) version $ver
                }
                continue
            }
            # !file ?
            if {$first eq $manifest_defaults(file_prefix)} {
                set fields [lrange $fields 1 end]
            } elseif {[string index $first 0] eq $manifest_defaults(prefix_char)} {
                error "Unknown or invalid command '$first' on line $linenum of file manifest $manifest_file"
            }
            lassign $fields pathkey size md5
            incr size 0;        # Check numeric else error out
        } on error {msg eopts} {
            return -options $eopts "Badly formatted line '$line' at line $linenum in file '$manifest_file'. $msg"
        }
        if {[file pathtype $pathkey] ne "relative"} {
            # Just to be safe
            error "Path $pathkey in file manifest $manifest_file is not a relative path."
        }
        # The file join converts \ to /, just in case
        dict set distros($id) manifest [file join $pathkey] size $size
        dict set distros($id) manifest [file join $pathkey] md5 $md5
    }
    return
}


proc distro::prepare_install_steps {distro_id target_id args} {
    # Generates the commands to be executed to install files from a
    # distribution.
    # distro_id - id of distribution to be installed
    # target_id - id for destination directory
    # -dirs DIRLIST - list of relative directory paths. Only files
    #   within these directories (at any depth) are considered for install.
    #
    # The command returns two lists. The first list contains pairs of
    # commands, each pair consisting of an "install command"
    # to run as part of the install and a "rollback command" to reverse its
    # effect if rollback is required. Either element in the pair may be empty.
    #
    # The second list contains commands to be run to clean up if the first
    # set of commands is run without errors.
    #
    # An application can call the run_install_steps command to execute
    # the returned steps, or run them itself. In the latter case, the
    # application should invoke the first command, the install command,
    # of each pair in the
    # first list in turn. For each such command, it should simultaneously 
    # record the second command in the pair, the "rollback command"
    # in a rollback list if the first command in the pair does not fail.
    # If the install command fails, all existing commands in the rollback
    # list should be run in reverse order to undo any changes. The rollback
    # list can also be saved for uninstallation purposes. Note that either
    # or both commands in a pair may be empty.
    
    variable distros

    #ruff
    # -updatesameversion BOOLEAN - if specified as true (default),
    #  updates the target directory even if it is the same version.
    set opts(-updatesameversion) true
    array set opts $args

    set srcdir [dict get $distros($distro_id) npath]
    set dstdir [dict get $distros($target_id) npath]

    set nocase [expr {$::tcl_platform(platform) eq "windows" ? "-nocase" : ""}]

    if {[string equal {*}$nocase $srcdir $dstdir]} {
        error "Source and destination directories are the same."
    }

    # file join allows for relative as well as absolute paths
    set src_manifest_path [file join $srcdir [dict get $distros($distro_id) manifest_name]]
    set dst_manifest_path [file join $dstdir [dict get $distros($target_id) manifest_name]]

    set target_version [dict get $distros($target_id) version]
    set distro_version [dict get $distros($distro_id) version]
    set version_compare [package vcompare $target_version $distro_version]
    if {$version_compare > 0 || ($version_compare == 0 && ! $opts(-updatesameversion))} {
        # error "Installed version $target_version is same or newer than distribution version $distro_version."
        #ruff
        # The command returns an empty list if the installed version is newer or
        # if it is the same and the -updatesameversion option is false.
        return {}
    }

    set srcfiles [dict get $distros($distro_id) manifest]
    set dstfiles [dict get $distros($target_id) manifest]
    set cmds {};                # Commands to run
    set cleanup_cmds {};        # Cleanup commands to be run at the end

    if {[info exists opts(-dirs)]} {
        set dirs {}
        foreach dir $opts(-dirs) {
            # Note the dirs may contain glob characters though
            # we do not explicitly document this. Else we need
            # to escape them if we do not want that behavior
            lappend dirs [file join $dir *]
        }
    }

    # Construct the commands for copying
    foreach path [dict keys $srcfiles] {
        # $path is the relative path

        # If the caller has specified a dir option, ignore all
        # files that do not fall under one of the specified 
        # directories.
        if {[info exists dirs]} {
            set match 0
            foreach dir $dirs {
                if {[string match {*}$nocase $dir $path]} {
                    set match 1
                    break
                }
            }
            if {! $match} {
                continue;       # Skip this file
            }
        }
        
        set src [file join $srcdir $path]
        set dst [file join $dstdir $path]

        #ruff
        # The following algorithm defines how and when files are copied
        # to the target directory.
        #
        # If the destination file does not exist, the source file is
        # simply copied. The corresponding rollback command will delete
        # the newly copied file but not any intermediate directories that
        # might have been created.
        if {![file exists $dst]} {
            # No rollback for mkdir
            lappend cmds [list [list file mkdir [file dirname $dst]] [list ]]
            lappend cmds [list [list file copy -- $src $dst] [list file delete -force -- $dst]]
            continue
        }
            
        #ruff
        # If the destination file exists, a backup copy is saved with
        # any existing backups being overwritten. The destination file
        # is then checked against the entry
        # in its corresponding manifest.
        # If it appears to have been changed since the previous install,
        # the backup copy is preserved. Otherwise, the backup copy will
        # be deleted during cleanup.

        set backup ${dst}.bak
        lappend cmds [list [list file rename -force -- $dst $backup] [list file rename -force -- $backup $dst]]
        lappend cmds [list [list file copy -- $src $dst] [list ]]

        # See if we need to remove the backup file on cleanup (successful install)
        # We check size first as md5 is more expensive
        if {[dict exists $dstfiles $path] &&
            [dict get $dstfiles $path size] == [file size $dst] &&
            [dict get $dstfiles $path md5] eq [md5::md5 -hex -filename $dst]} {
            # End user had not changed the file so clean up the saved copy
            lappend cleanup_cmds [list file delete -force -- $backup]
        }
    }

    #ruff
    # Files that were present in the old manifest are added for deletion
    # through the cleanup commands if they are not listed in the new manifest.
    foreach path [dict keys $dstfiles] {
        set dst [file join $dstdir $path]
        if {[dict exists $srcfiles $path] ||
            ![file exists $dst]} {
            # Either file is new manifest or is not actually on system.
            # No need to do anything
            continue
        }

        # Rename the file to backup, will be deleted later as part of cleanup
        set backup ${dst}.bak
        lappend cmds [list [list file rename -force -- $dst $backup] [list file rename -force -- $backup $dst]]
        if {[dict get $dstfiles $path size] == [file size $dst] &&
            [dict get $dstfiles $path md5] eq [md5::md5 -hex -filename $dst]} {
            # End user had not changed the file so clean up the saved copy
            lappend cleanup_cmds [list file delete -force -- $backup]
        }
    }
    

    # Finally copy the manifest itself. Note we do this irrespective of -dirs option.
    set backup ${dst_manifest_path}.bak
    if {[file exists $dst_manifest_path]} {
        lappend cmds [list [list file rename -force -- $dst_manifest_path $backup] [list file rename -force -- $backup $dst_manifest_path]]
        lappend cmds [list [list file copy -- $src_manifest_path $dst_manifest_path] [list ]]
        lappend cleanup_cmds [list file delete -force -- $backup]
    } else {
        lappend cmds [list [list file copy -- $src_manifest_path $dst_manifest_path] [list file delete -force -- $dst_manifest_path]]
    }

    return [list $cmds $cleanup_cmds]
}

proc distro::simulate_install_steps {steps} {
    # Extract the list of commands that will be executed for an install.
    # steps - return value from prepare_install_steps

    lassign $steps cmds cleanup_cmds
    set commands {}
    foreach cmd $cmds {
        lassign $cmd cmd rollback
        if {$cmd ne ""} {
            lappend commands $cmd
        }
    }

    return [concat $commands $cleanup_cmds]
}


proc distro::run_install_steps {steps args} {
    # Runs the installation steps with rollback if necessary
    # steps - return value from prepare_install_steps
    # -logcmd SCRIPT - command to call to log actions. An additional message
    #   string is appended to SCRIPT before it is called.
    # Runs the installation steps as returned by prepare_install_steps.
    # See its documentation for details.

    array set opts {-logcmd ""}
    array set opts $args

    lassign $steps cmds cleanup_cmds

    # Actually run the commands
    set rollback_cmds {}
    try {
        foreach pair $cmds {
            lassign $pair cmd rollback
            if {$opts(-logcmd) ne ""} {
                {*}$opts(-logcmd) "Executing: $cmd"
            }
            eval $cmd
            # Command ran so add its reverse to the rollback.
            # Note rollback_cmds are in reverse order to how they
            # will be actually run
            if {[llength $rollback]} {
                lappend rollback_cmds $rollback
            }
        }

    } on error {msg eopts} {
        #ruff
        # In case of errors, the command attempts to rollback any changes it has
        # effected. Even in the case of successful rollbacks, certain changes
        # like deletion of old backup files and creation of new directories, 
        # if any, are not recovered.
        
        if {[info exists opts(-logcmd)]} {
            {*}$opts(-logcmd) "Error: $msg. Attempting to rollback."
        }

        foreach cmd [lreverse $rollback_cmds] {
            if {[info exists opts(-logcmd)]} {
                {*}$opts(-logcmd) "Rollback: $cmd"
            }
            # Ignore errors, what can we do?
            if {[catch $cmd rollback_msg]} {
                if {[info exists opts(-logcmd)]} {
                    {*}$opts(-logcmd) "Rollback command failed: $cmd. $rollback_msg"
                }
            }
        }
        
        return -options $eopts $msg
    }

    # Now run cleanup under a catch
    if {[llength $cleanup_cmds]} {
        foreach cmd [lreverse $cleanup_cmds] {
            if {[info exists opts(-logcmd)]} {
                {*}$opts(-logcmd) "Cleanup: $cmd"
            }
            # Ignore errors, what can we do other than log?
            if {[catch $cmd msg]} {
                if {[info exists opts(-logcmd)] && $opts(-logcmd) ne ""} {
                    {*}$opts(-logcmd) "Cleanup command failed: $cmd. $msg"
                }
            }
        }
    }

    return
}


proc distro::install {distro_path target_path args} {
    # Installs a distribution into a target directory 
    # distro_path - path to the distribution directory
    # target_path - path to the target directory. Must not be
    #   the same as $distro_path.
    #
    # This is a wrapper around prepare_install_steps and run_install_steps.
    # See those commands for details.

    variable manifest_defaults

    #ruff
    # -logcmd SCRIPT - command to call to log actions. An additional message
    #   string is appended to SCRIPT before it is called.
    #  -manifest NAME - the name to use for the file manifest
    # -updatesameversion BOOLEAN - if specified as true (default),
    #  updates the target directory even if it is the same version.
    array set opts [list -manifest $manifest_defaults(filename) \
                        -logcmd "" \
                        -updatesameversion true]
    array set opts $args

    #ruff
    # -dirs DIRLIST - list of relative directory paths. Only files
    #   within these directories (at any depth) are considered for install.
    if {[info exists opts(-dirs)]} {
        set opt_dirs [list -dirs $opts(-dirs)]
    } else {
        set opt_dirs {}
    }

    if {[_contained_file $distro_path $target_path]} {
        error "Target directory '$target_path' must not be under the distribution directory '$distro_path'."
    }
    
    set from_distro [distro::distro $distro_path -manifest $opts(-manifest)]
    distro::read_manifest $from_distro
    set to_distro [distro::distro $target_path -manifest $opts(-manifest)]
    distro::read_manifest $to_distro
    set install_steps [distro::prepare_install_steps $from_distro $to_distro \
                           {*}$opt_dirs \
                           -updatesameversion $opts(-updatesameversion)]
    distro::run_install_steps $install_steps -logcmd $opts(-logcmd)
    # distro::save_manifest $to_distro - not needed, as the install steps include copying of manifest
    distro::release $from_distro
    distro::release $to_distro
    return
}

proc distro::uninstall {target_path args} {
    # Uninstalls a distribution
    # target_path - path to the target directory.

    variable distros
    variable manifest_defaults

    #ruff
    # -logcmd SCRIPT - command to call to log actions. An additional message
    #   string is appended to SCRIPT before it is called.
    #  -manifest NAME - the name to use for the file manifest
    array set opts [list -manifest $manifest_defaults(filename) \
                        -logcmd "" \
                        -updatesameversion true]
    array set opts $args

    set msgs {}
    set id [distro::distro $target_path -manifest $opts(-manifest)]
    distro::read_manifest $id
    dict for {relpath meta} [dict get $distros($id) manifest] {
        if {[catch {
            set path [file join $target_path $relpath]
            #ruff
            # All files in the manifest are deleted, but only if the file
            # has not changed since the installation. Directories are
            # not removed even if they are empty.

            # Check that file size is the same as in manifest
            # (cheaper than directly going to md5)
            if {[file exists $path] &&
                [file size $path] == [dict get $meta size] &&
                [md5::md5 -hex -filename $path] eq [dict get $meta md5]} {
                puts stderr  "Deleting $path"
                # file delete -force -- $path
            }
        } msg]} {
            # If any errors are encountered in deleting a file, the process
            # is continues with the next file in the manifest.
            lappend msgs $msg
        }
    }

    if {[catch {
        #ruff
        # The manifest file is deleted after uninstalling.
        file delete -force [file join $target_path [dict get $distros($id) manifest_name]]
    } msg]} {
        lappend msgs $msg
    }

    distro::release $id

    #ruff
    # Returns a list of errors encountered in deleting files, if any.
    return $msgs
}

proc distro::build {path version args} {
    # Prepares the specified directory as a distribution area
    # path - path to directory where the distribution files reside
    # version - the version to use for the distribution
    # -manifest NAME - the name to use for the file manifest
    # -crlf LINEEND - 'lf', 'crlf', or 'auto' (default). The line endings
    #   to use for the manifest file.
    # The command builds a file manifest in the specified directory so
    # that the directory can be used as a distribution.

    variable manifest_defaults
    array set opts [list -manifest $manifest_defaults(filename) -crlf auto]
    array set opts $args

    set id [distro $path -manifest $opts(-manifest)]
    build_manifest $id $version
    distro::save_manifest $id $opts(-crlf)
    distro::release $id
}


proc distro::refresh {distro_path paths args} {
    # Updates the manifest for the specified files in
    # a distribution and writes it back out.
    # distro_path - directory path of the distribution
    # paths - list of paths to update. These may be relative to
    #  the distribution directory or absolute but must
    #  lie within the distribution directory
    
    variable manifest_defaults

    #ruff
    #  -manifest NAME - the name to use for the file manifest
    #  -version VERSION
    array set opts [list -manifest $manifest_defaults(filename)]
    array set opts $args
    
    #ruff
    # It is an error for the manifest to not exist.
    if {![file isfile [file join $distro_path $opts(-manifest)]]} {
        error "Manifest '$opts(-manifest)' not found in directory '$distro_path'."
    }

    set id [distro $distro_path -manifest $opts(-manifest)]
    read_manifest $id
    update_manifest_entries $id {*}$paths
    save_manifest $id
    return
}

proc distro::_contained_file {base path} {
    # Returns true if a path is contained within another
    # (including if they are the same) and false otherwise

    set base [file normalize $base]
    set path [file normalize $path]

    set base_len [string length $base]

    set nocase [expr {$::tcl_platform(platform) eq "windows" ? "-nocase" : ""}]

    if {[string compare {*}$nocase -length $base_len $base $path]} {
        return false
    }

    # First base_len chars match. Next char must be / (even on Windows
    # after normalization) or 
    if {[string index $path $base_len] eq "/" ||
        [string length $path] == $base_len} {
        return true
    }

    return false
}

proc distro::_document_self {path} {
    # Generates documentation for the package in HTML format.
    # path - path to the output file
    variable version

    package require ruff

    set intro {
        distro is a simple library that aids in distributing
        software packages. Note it is a library,
        not an installation script, so needs to be invoked from
        the application installation script.

        The package provides the following features:
        - generating a file manifest for the distribution
        - installation on the target system based on the manifest
        - rollback of installation on failure
        - basic uninstall
        - updating of installed software with version checking,
          and backup of modified files
        - logging of all install actions
        - simulation of install to display actions that will
          taken without actually executing them.

        The package is not a full blown install builder or
        installer like InstallJammer. It is targeted towards
        software with very basic installation needs. Limitations
        are too many to mention, but include:
        - no ability to install into directories outside a single
          directory tree
        - no ability to modify the system configuration
          (eg. creating users)
        - no user interface
        - no facility for subpackages etc.
        - no integration with the host operating system installer

        Basically, distro is a glorified file copying utility that provides rollback,
        simulation and versioning. For anything more sophisticated, you have to write your
        own scripts wrapping it or use a real installer like InstallJammer.
    }

    set build_usage {
        To build a distribution, first create the distribution directory and
        populate it with files with the same exact layout desired on the target
        system. Then execute the ::distro::build command from your Tcl script:
           package require distro
           distro::build DIRPATH VERSION
        where DIRPATH is the directory where your distribution resides, and VERSION
        is the version to use for the distribution. You can then use gzip or some
        other archiving utility to create a distribution archive.
    }

    set install_usage {
        To install a distribution, unpack the distribution archive and run the following
        commands from a script:
          package require distro
          distro::install DISTROPATH TARGETPATH
        where DISTROPATH is the directory where the distribution was
        unpacked, and TARGETPATH is the path of the directory where
        the files are to be installed.  If an older version of the
        distribution is already installed in the target directory, it
        will be upgraded. See the ::distro::install command for other
        options, such as creation of an installation log.
    }

    set uninstall_usage {
        To uninstall a distribution, run the following commands from a script:
          package require distro
          distro::uninstall TARGETPATH
        where TARGETPATH is the directory where the package was installed.
        Uninstalling is simplistic in that all files listed in the manifest
        are deleted. See the ::distro::uninstall command for other
        options, such as creation of an installation log.
    }

    set custom_usage {
        More sophisticated distribution and install scripts may built
        using lower level commands. Refer to the command reference
        for details.
    }

    ::ruff::document_namespaces html [namespace current] \
        -recurse true \
        -output $path \
        -titledesc "distro - a distribution and installation utility (V$version)" \
        -copyright "[clock format [clock seconds] -format %Y] Ashok P. Nadkarni" \
        -includesource false \
        -preamble [dict create :: \
                       [list \
                            Introduction [::ruff::extract_docstring $intro] \
                            "Building a distribution" [::ruff::extract_docstring $build_usage] \
                            "Installing a distribution" [::ruff::extract_docstring $install_usage] \
                            "Uninstalling a distribution"  [::ruff::extract_docstring $uninstall_usage] \
                            "Customization" [::ruff::extract_docstring $custom_usage] \
                           ]]
}

package provide distro $distro::version
