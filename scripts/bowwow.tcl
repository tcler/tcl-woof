# Set argv0 to the wibble server so it knows it should run standalone.
set ::argv0 [file join [file dirname [info script]] .. lib woof webservers wibble_server.tcl]
source $::argv0
