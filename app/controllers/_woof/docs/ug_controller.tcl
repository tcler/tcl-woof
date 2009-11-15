

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
            {qs_user_input "Getting User Input" 1}
            {qs_flash "Using the Flash" 1}
            {qs_default_page "Configuring the Default Page" 1}
            {qs_finish "Finishing Up" 1}
            {installation "Installation"}
            {install_under_bowwow "Woof! under BowWow" 1}
            {install_under_apache "Woof! under Apache 2" 1}
            {apache_cgi_dedicated "Dedicated CGI on Apache" 2}
            {apache_cgi_shared "Shared CGI on Apache" 2}
            {apache_scgi "SCGI on Apache" 2}
            {apache_websh "Running as an Apache module" 2}
            {install_under_iis "Woof! under Microsoft IIS" 1}
            {iis_scgi "SCGI on IIS" 2}
            {install_under_lighttpd "Woof! under Lighttpd" 1}
            {lighttpd_scgi "SCGI on Lighttpd" 2}
            {start_scgi "Running as an SCGI server" 1}
            {start_scgi_linux "SCGI on Linux" 2}
            {start_scgi_windows "SCGI on Windows" 2}
            {install_final_steps "Verifying the Installation" 1}
            {basics "Woof! Basics"}
            {mvc "The Model-View-Controller Architecture" 1}
            {interpreter "The Woof! Interpreter" 1}
            {loading_packages "Loading Packages" 2}
            {filesystem_layout "File System Layout" 1}
            {directory_structure "Directory Structure" 2}
            {file_naming  "File Naming and Ownership" 2}
            {configuration "Configuration Settings" 1}
            {development_aids "Development Aids" 1}
            {request_handling "Request Handling"}
            {url_dispatcher "URL Dispatching" 1}
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
            {custom_page_layout "Custom Page Layout" 2}
            {page_sections "Page Sections" 1}
            {page_section_templates "Template Based Page Sections" 2}
            {page_section_direct "Directly Generated Page Sections" 2}
            {page_section_example "Page Section Layout Example" 2}
            {locating_templates "Locating Templates" 1}
            {pagevar "The <span class='wf_code'>pagevar</span> Object" 1}
            {using_stylesheets "Using Stylesheets" 1}
            {using_images "Using Images" 1}
            {wtf "Woof! Template Format" 1}
            {wtf_mistakes "Common WTF errors" 2}
            {localization "Localization"}
            {client_language "Client Language Preference" 1}
            {message_catalogs "Using Message Catalogs" 1}
            {language_specific_pages "Language-Specific Page Templates" 1}
            {error_and_logging "Error Handling and Logging"}
            {tools "Tools and Utilities"}
            {installer "installer - Installation Utility" 1}
            {wag "wag - Woof! Application Generator" 1}
            {generating_stubs "Generating controller stubs" 2}
            {verifying_stubs "Verifying controller stubs" 2}
            {bowwow "bowwow - a Lightweight Web Server" 1}
            {console "console - Interactive Console" 1}
            {ruffian "ruffian - Documentation Generator" 1}
            {scgi_winservice "scgi_winservice - Woof! Windows Service" 1}
            {recommended_reading "Recommended Reading"}
            {acknowledgements "Acknowledgements"}
        }

        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set section_layout_alias _layout
        
        # Customize the layout as per our liking
        pagevar set \
            yui_page_width 750px \
            yui_sidebar_width 160px \
            yui_main_percent 75%
            
        pagevar set styles {
            _yui-2-8-0r4-reset-fonts-grids.css
            _yui-2-8-0r4-base-min.css
            _woof.css
            _woof_ug.css
        }

        # Set page title based on the section
        pagevar set title "Woof! - [my _heading]"
        pagevar set module_subheading "User Guide (Version [::woof::version])"
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
        # Does nothing since the appropriate template is automatically
        # picked up.
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

}

