# Single file that defines the woof version
namespace eval ::woof {
    proc version {} {
        # Returns the version of Woof

        # Remember the pkgindex.tcl file also needs to change if
        # the version is changed here.
        return 0.4
    }
}

