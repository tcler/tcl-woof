# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the Woof root directory for license

# File caching for Woof

catch {FileCache destroy}
oo::class create FileCache {
    constructor {args} {
        # Maintains an in-memory cache of file locations and content
        #
        # -relativeroot PATH - the path to use for normalizing relative
        #  paths if this option is not specified in calls to locate
        #  or read methods. Defaults to current working directory.
        #
        # In order to minimize reads from the file system, the class
        # keeps an internal cache from which file content can be returned.
        # In addition to caching of content, it also keeps track of
        # which directory a file was read from when searching for a file
        # in a directory path

        # The _locations cache is a dictionary that keeps track of
        # where files are located, given a specific search path.
        # It is a two-level dictionary, keyed by the search path,
        # and then the file tail (which is not necessarily just the name)
        my variable _locations
        set _locations [dict create]

        # The _content cache contains the actual content of files.
        # It is a dictionary keyed by the path, with the value
        # being the content
        my variable _content
        set _content [dict create]

        my variable _relativeroot
        if {[dict exists $args -relativeroot]} {
            set _relativeroot [dict get $args -relativeroot]
        } else {
            set _relativeroot [pwd]
        }
    }

    method locate {tail dirs args} {
        # Locates a file along a search path and returns its full path.
        #   tail - specifies the trailing portion of a full file path. Normally,
        #     this is just a file name but could include subdirectories as well
        #   dirs - a list of directory names. Each of these is joined with the
        #     tail and the resulting path is checked. Each directory path
        #     in the list may be either absolute or relative. In the latter
        #     case, it is assumed to be rooted at the value given by
        #     the -relativeroot option.
        #   -cachecontrol CACHECONTROL - controls how the location cache
        #     is handled. If CACHECONTROL is "readwrite" (default), the
        #     location cache is looked up. If not found there, the disk
        #     is searched and the result is stored in the location cache
        #     in addition to being returned. If CACHECONTROL is "read",
        #     the cache is looked up, but is not updated if the entry
        #     is not in it. If CACHECONTROL is "write", the cache is not
        #     looked up, but is updated. Finally, if CACHECONTROL is "ignore",
        #     the cache is completely bypassed.
        #   -relativeroot ROOTPATH - the root path to use for all elements in
        #     $dirs that are relative paths. Defaults to the -relativeroot
        #     value specified when the object was constructed.
        #
        # The command searches for a file whose path matches the path
        # constructed from joining each directory listed in $dirs with $tail.
        # Note that the search will stop at the first file found even
        # if that is unreadable for some reason (such as access denied).
        #
        # Returns the full absolute path if found or an empty string if the
        # the file is not found.
        
        # TBD - why does this not have same interface as method read ?
        # (for example why is $dirs not an option)

        my variable _locations
        my variable _relativeroot

        array set opts [list -cachecontrol readwrite -relativeroot $_relativeroot]
        array set opts $args

        if {$opts(-cachecontrol) in {readwrite read}} {
            # We look up the location cache. Note we do NOT normalize or
            # in any way process the file paths or tail since that itself
            # causes disk accesses that we want to avoid. This means
            # the same file may show up multiple times in the cache if
            # callers use different syntactic forms, but that's ok
            if {[dict exists $_locations $opts(-relativeroot) $dirs $tail]} {
                # Return absolute path or empty string (non-existent file)
                return [dict get $_locations $opts(-relativeroot) $dirs $tail]
            }
        }

        # Not in cache, search the directory path
        switch -exact -- [file pathtype $tail] {
            volumerelative -
            absolute {
                #ruff
                # If $tail specifies an absolute or volume-relative path,
                # it is returned
                # in normalized form if the file exists. $dirs is ignored.
                set path [file normalize $tail]
                if {! [file isfile $path]} {
                    # File does not exist or is not a regular file
                    set path ""
                }
            }
            relative {
                #ruff
                # When $tail is relative, it is checked relative to
                # each directory in $dirs, and the first existing match
                # is returned in normalized form. If $dirs is an empty list,
                # it is treated containing only ".". Paths in $dirs
                # that are themselves relative are qualified with the
                # path specified with the -relativeroot option.
                if {[llength $dirs] == 0} {
                    set dirs [list .]
                }
                set path ""
                foreach dir $dirs {
                    # Note that the file join command will ignore 
                    # $opts(-relativeroot) if $dir is not relative. That's
                    # exactly what we want.
                    set possible_path [file normalize [file join $opts(-relativeroot) $dir $tail]]
                    if {[file isfile $possible_path]} {
                        set path $possible_path
                        break
                    }
                }
            }
            default {
                error "Unexpected path type for file '$tail'"
            }
        }
        if {$opts(-cachecontrol) in {readwrite write}} {
            dict set _locations $opts(-relativeroot) $dirs $tail $path
        }

        return $path
    }

    method read {path args} {
        # Reads the content of a file.
        #   path - Path to the file to be read. May be absolute or relative.
        #   -cachecontrol CACHECONTROL - controls how the content cache
        #     is handled. If CACHECONTROL is "readwrite" (default), the
        #     content cache is looked up. If not found there, the disk
        #     is searched and the result is stored in the cache
        #     in addition to being returned. If CACHECONTROL is "read",
        #     the cache is looked up, but is not updated if the entry
        #     is not in it. If CACHECONTROL is "write", the cache is not
        #     looked up, but is updated. Finally, if CACHECONTROL is "ignore",
        #     the cache is completely bypassed.
        #   -defaultcontent DATA - If specified, DATA is returned
        #     as the content if the file does not exist. Note that if the
        #     file exists but is not readable (for example, because of permissions)
        #     an error is always generated.
        #   -contentvar VARNAME - Name of a variable in caller's context to hold
        #     the data. This option also impacts the return value and
        #     handling of errors (see below).
        #   -translation MODE - Translation mode as used by the Tcl open command.
        #   -dirs DIRLIST - list of directories to search for if $path is relative.
        #     Defaults to ".". Each element in the list
        #     may itself be either a relative path or absolute.
        #   -relativeroot ROOTPATH - See description of this option for the
        #     locate method.
        # For all errors, except missing files, the command will 
        # raise a Tcl exception. If the file is missing, the command will raise
        # an error only if neither -defaultcontent, nor -contentvar is 
        # specified. The corresponding error code will be {WOOF MissingFile}.

        my variable _content

        # Note -defaultcontent & -contentvar have no default setting
        array set opts {
            -cachecontrol readwrite
            -translation auto
            -dirs {}
        }
        array set opts $args

        # TBD - should we normalize file name? Not for now
        # TBD - place limit on cache size?
        
        # Locate file - essentially this will also tell us if the file is 
        # missing without going to disk unless necessary.
        if {[info exists opts(-relativeroot)]} {
            set real_path [my locate $path $opts(-dirs) -cachecontrol $opts(-cachecontrol) -relativeroot $opts(-relativeroot)]            
        } else {
            set real_path [my locate $path $opts(-dirs) -cachecontrol $opts(-cachecontrol)]
        }

        if {$real_path ne ""} {
            # File exists
            if {($opts(-cachecontrol) in {read readwrite}) &&
                [dict exists $_content $real_path]} {
                # Read caching allowed.
                set data [dict get $_content $real_path]
            } else {
                # Caching not allowed, or not in data cache.
                set fd [open $real_path]
                try {
                    set data [read $fd]
                } finally {
                    close $fd
                }
                # Update cache if so indicated
                if {$opts(-cachecontrol) in {write readwrite}} {
                    dict set _content $real_path $data
                }
            }
        } else {
            # File does not exist
            if {[info exists opts(-defaultcontent)]} {
                set data $opts(-defaultcontent)
            }
        }


        #ruff
        # Returns content of the file if the -contentvar option is not
        # specified. If the option is specified, stores the content, if any,
        # in the variable named by the option and returns true. If no
        # content is available, returns false in this case. Note the content
        # may be either the actual content of the file, or the value of
        # the -defaultcontent option, if specified.
        if {[info exists data]} {
            # We have some data, either from cache, the disk or -defaultcontent
            if {[info exists opts(-contentvar)]} {
                upvar 1 $opts(-contentvar) retdata
                set retdata $data
                return true
            } else {
                return $data
            }
        } else {
            # No data from anywhere
            if {[info exists opts(-contentvar)]} {
                return false
            } else {
                ::woof::errors::exception WOOF MissingFile "File $path could not be read."
            }
        }
    }

    method flush {} {
        # Flushes all cached information about files

        my variable _locations
        my variable _content
        set _locations [dict create]
        set _content [dict create]
        return
    }

}
