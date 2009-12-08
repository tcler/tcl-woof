set test_conf_dir [file dirname [info script]]
proc main {config apache_root woof_root} {

    set apache_root [file normalize $apache_root]
    set woof_root [file normalize $woof_root]

    # Read in test configuration
    set test_conf [file join $::test_conf_dir httpd-${config}.conf]
    set fd [open $test_conf r]
    set conf_data [read $fd]
    close $fd

    # Substitute the config
    regsub -all -- {%SERVER_ROOT%} $conf_data $apache_root conf_data
    regsub -all -- {%WOOF_ROOT%} $conf_data $woof_root conf_data

    # Assume if .sav exists, original httpd.conf already backed up
    set httpd_conf [file join $apache_root conf httpd.conf]
    if {![file exists ${httpd_conf}.sav]} {
        file copy $httpd_conf ${httpd_conf}.sav
    }

    set fd [open $httpd_conf w]
    puts $fd $conf_data
    close $fd

    file copy -force [file join $::test_conf_dir common.conf] [file join $apache_root conf common.conf]
}

if {[llength $argv] < 3} {
    puts stderr "Usage:"
    puts "[file tail [info nameofexecutable]] $::argv0 [string toupper [info args main]]"
    exit 1
}
main {*}$argv
