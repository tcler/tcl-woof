

oo::class create UgController {
    superclass ApplicationController
    variable _toc
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args

        # Define the table of contents
        # Each entry is an element consisting of
        # an action, the display label and optionally
        # the ToC heading level (1 by default)
        set _toc {
            {index "Detailed Table of Contents"}
            {preface Preface}
            {system_requirements "System Requirements"}
            {quick_start "Quick Start"}
            {qs_first_steps "First Steps" 1}
            {qs_stubs_generate "Generating Stubs" 1}
            {qs_stubs_implement "Implementing the Stubs" 1}
            {qs_session "Keeping State" 1}
            {qs_page_display "Displaying the Page" 1}
            {qs_enhancements "Enhancing the Application" 1}
            {qs_page_layout "Laying out a Page" 1}
            {qs_story_so_far "The Story So Far" 1}
            {qs_wtf_syntax "Writing Page Templates" 1}
            {qs_purecss "Stylin' with PureCSS" 1}
            {qs_user_input "Getting User Input" 1}
            {qs_flash "Using the Flash" 1}
            {qs_default_page "Configuring the Default Page" 1}
            {qs_finish "Finishing Up" 1}
            {installation "Installation"}
            {install_under_apache "Woof! under Apache 2" 1}
            {apache_cgi_dedicated "Dedicated CGI on Apache" 2}
            {apache_cgi_shared "Shared CGI on Apache" 2}
            {apache_scgi "SCGI on Apache" 2}
            {apache_websh "Running as an Apache module" 2}
            {install_under_iis "Woof! under Microsoft IIS" 1}
            {iis_scgi "SCGI on IIS 5.1 and 6" 2}
            {install_under_lighttpd "Woof! under Lighttpd" 1}
            {lighttpd_scgi "SCGI on Lighttpd" 2}
            {start_scgi "Running as an SCGI server" 1}
            {start_scgi_linux "SCGI on Linux" 2}
            {start_scgi_windows "SCGI on Windows" 2}
            {install_final_steps "Verifying the Installation" 1}
            {basics "Woof! Basics"}
            {mvc "The Model-View-Controller Architecture" 1}
            {interpreter "The Woof! Interpreter Model" 1}
            {loading_packages "Loading Packages" 2}
            {filesystem_layout "File System Layout" 1}
            {directory_structure "Directory Structure" 2}
            {file_naming  "File Naming and Ownership" 2}
            {configuration "Configuration Settings" 1}
            {development_aids "Development Aids" 1}
            {request_handling "Request Handling"}
            {url_dispatcher "URL Mapping" 1}
            {default_dispatcher "Default URL Mapping" 2}
            {routes "URL Routes" 2}
            {url_construction "URL Construction" 2}
            {controller_object "The <span class='wf_code'>controller</span> Object" 1}
            {controller_example "A Simple Controller Example" 2}
            {implementing_controllers "Implementing Controllers" 2}
            {implementing_actions "Implementing Actions" 2}
            {request_object "The <span class='wf_code'>request</span> Object" 1}
            {session_object "The <span class='wf_code'>session</span> Object" 1}
            {icookies_object "The <span class='wf_code'>icookies</span> Object" 1}
            {flash_object "The <span class='wf_code'>flash</span> Object" 1}
            {params_object "The <span class='wf_code'>params</span> Object" 1}
            {env_object "The <span class='wf_code'>env</span> Object" 1}
            {response_construction "Response construction"}
            {response_object "The <span class='wf_code'>response</span> Object" 1}
            {normal_response "Returning a Normal Response" 1}
            {redirects "Redirecting a Request" 1}
            {error_responses "Sending Error Responses" 1}
            {response_headers "Adding HTTP Response Headers" 1}
            {sending_files "Sending Files and Non-HTML Data" 1}
            {ocookies_object "The <span class='wf_code'>ocookies</span> Object" 1}
            {page_generation "Page Generation"}
            {page_layout "Page Layout" 1}
            {default_page_layout "Default Page Layout" 2}
            {extending_default_layout "Extending the Default Layout" 2}
            {custom_page_layout "Custom Page Layout" 2}
            {page_sections "Page Sections" 1}
            {page_section_templates "Template Based Page Sections" 2}
            {page_section_direct "Directly Generated Page Sections" 2}
            {locating_templates "Locating Templates" 1}
            {pagevar "The <span class='wf_code'>pagevar</span> Object" 1}
            {static_resources "Using Static Resources" 1}
            {locating_resources "Locating Static Resources" 2}
            {using_images "Using Images" 2}
            {using_stylesheets "Using Stylesheets" 2}
            {wtf "Woof! Template Format" 1}
            {wtf_mistakes "Common WTF errors" 2}
            {localization "Localization"}
            {client_language "Client Language Preference" 1}
            {message_catalogs "Using Message Catalogs" 1}
            {language_specific_pages "Language-Specific Page Templates" 1}
            {library "The Woof! Library"}
            {error_handling "Error Handling" 1}
            {error_display "Error Pages" 2}
            {error_generation "Generating Exceptions" 2}
            {logging "The Logging Interface" 1}
            {yui "The Yahoo User Interface library" 1}
            {tools "Tools and Utilities"}
            {installer "installer - Installation Utility" 1}
            {wag "wag - Woof! Application Generator" 1}
            {generating_stubs "Generating controller stubs" 2}
            {verifying_stubs "Verifying controller stubs" 2}
            {bowwow "bowwow - a Lightweight Web Server" 1}
            {bowwow_exe "bowwow.exe standalone executable" 2}
            {bowwow_script "bowwow.tcl script" 2}
            {console "console - Interactive Console" 1}
            {ruffian "ruffian - Documentation Generator" 1}
            {scgi_winservice "scgi_winservice - Woof! Windows Service" 1}
            {recommended_reading "Recommended Reading"}
            {acknowledgements "Acknowledgements"}
        }

        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set section_layout_alias _layout
        
        pagevar set styles {
            _woof.css
            _woof_ug.css
        }

        pagevar set section_layout_settings {
            sidebar {tag nav cssclasses {wf_nav}}
            main {cssclasses {pure-skin-woof wf_box}}
        }

        # Set page title based on the section
        pagevar set title "Woof! - [my _heading]"
        pagevar set MODULE_SUBHEADING "User Guide (Version [::woof::version])"
    }

    method _heading {{action ""}} {
        if {$action eq ""} {
            set action [my action]
        }
        set toc_entry [lsearch -exact -inline -index 0 $_toc $action]
        if {$toc_entry ne ""} {
            return [lindex $toc_entry 1]
        } else {
            string totitle $action
        }
    }

    method _neighbours {} {
        # Returns the previous and next chapters.
        set action [my action]
        set i [lsearch -exact -index 0 $_toc $action]
        return [list [lindex $_toc [expr {$i-1}]] [lindex $_toc [incr i]]]
    }

    method _missing_action {action} {
        # Called for all actions that are not defined.
        # The appropriate template is automatically
        # picked up. Nothing we need do here.
    }

    method _chapter_link {action {display ""}} {
        # Generates a link to a chapter
        if {$display eq ""} {
            set display [my _heading $action]
        }
        return [my link_to $display -action $action]
    }

    method _code_sample {text {escape true}} {
        # Returns a code sample
        if {$escape} {
            return "<pre class='wf_console_session'>[hesc [::woof::util::remove_left_margin $text]]</pre>"
        } else {
            return "<pre class='wf_console_session'>[::woof::util::remove_left_margin $text]</pre>"
        }
    }

    method _manpage_link {name {display ""}} {
        # Generates a link to manpage for a class or proc
        if {$display eq ""} {
            set display "<span class='wf_code'>[hesc [namespace tail $name]]</span>"
        }
        return "<a href='http://woof.magicsplat.com/manuals/woof/index.html#$name'>$display</a>"
    }

    method _tcl_manpage_link {name {display ""}} {
        # Generates a link to Tcl manpage
        if {$display eq ""} {
            set display "<span class='wf_code'>[hesc [namespace tail $name]]</span>"
        }
        return "<a href='http://www.tcl.tk/man/tcl8.6/TclCmd/${name}.htm'>$display</a>"
    }

    method tbd {} {
        # Generates a page showing which pages are still to be written
        set content "<p>The following pages still need to be written:</p><ul>"
        foreach sec $_toc {
            lassign $sec key title level
            if {![page fetch content "" -alias "ug-${key}-content"]} {
                lappend content "<li>$key</li>"
            }
        }
        append content "</ul>"
        page store content $content
    }

    method index {} {
        # Returns the chapter links
        append content "<div class='wf_navbox'>"
        set current_level -1
        foreach sec $_toc {
            lassign $sec key title level
            if {$level eq ""} {set level 0}
            if {$level > $current_level} {
                append content [string repeat <ul> [expr {$level-$current_level}]]
            } elseif {$level < $current_level} {
                append content [string repeat </ul> [expr {$current_level-$level}]]
            }
            set current_level $level
            append content "<li>[my _chapter_link [lindex $sec 0]]</li>"
        }
        append content [string repeat </ul> [incr current_level]]
        append content "</div>"
        page store content $content
    }
}

