#
# Copyright (c) 2009, Ashok P. Nadkarni
# All rights reserved.
#
# See the file LICENSE for license

# This file contains tests for the Request object
namespace eval ::woof::test {
    variable test_url
    # The indices of the array are the same as the field names used by
    array set test_url {
        scheme "http"
        host "127.0.0.1"
        port "8015"
        application_url /
        test_url_path "woof/_test"
        query ""
    }
}