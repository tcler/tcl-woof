

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
            {system_requirements "System requirements"}
            {quick_start "Quick start"}
            {qs_first_steps "First steps" 1}
            {qs_stubs_generate "Generating stubs" 1}
            {qs_stubs_implement "Implementing the stubs" 1}
            {qs_session "Keeping state" 1}
            {qs_page_display "Displaying the page" 1}
            {qs_enhancements "Enhancing the application" 1}
            {qs_page_layout "Laying out a page" 1}
            {qs_story_so_far "The story so far" 1}
            {qs_wtf_syntax "Writing page templates" 1}
            {qs_purecss "Stylin' with PureCSS" 1}
            {qs_user_input "Getting user input" 1}
            {qs_flash "Using the flash" 1}
            {qs_default_page "Configuring the default page" 1}
            {qs_finish "Finishing up" 1}
            {installation "Installation"}
            {install_under_apache "Woof! under Apache 2" 1}
            {apache_cgi_dedicated "Dedicated CGI on Apache" 2}
            {apache_cgi_shared "Shared CGI on Apache" 2}
            {apache_scgi "SCGI on Apache" 2}
            {install_under_iis "Woof! under Microsoft IIS" 1}
            {iis_scgi "SCGI on IIS 5.1 and 6" 2}
            {iis7_scgi "SCGI on IIS 7 and 8" 2}
            {install_under_lighttpd "Woof! under Lighttpd" 1}
            {lighttpd_scgi "SCGI on Lighttpd" 2}
            {start_scgi "Running as an SCGI server" 1}
            {start_scgi_linux "SCGI on Linux" 2}
            {start_scgi_windows "SCGI on Windows" 2}
            {install_final_steps "Verifying the installation" 1}
            {basics "Woof! basics"}
            {mvc "The Model-View-Controller architecture" 1}
            {interpreter "The Woof! interpreter model" 1}
            {loading_packages "Loading packages" 2}
            {filesystem_layout "File system layout" 1}
            {directory_structure "Directory structure" 2}
            {file_naming  "File naming and ownership" 2}
            {configuration "Configuration settings" 1}
            {development_aids "Development aids" 1}
            {request_handling "Request handling"}
            {url_dispatcher "URL Mapping" 1}
            {default_dispatcher "Default URL mapping" 2}
            {routes "URL routes" 2}
            {url_construction "URL construction" 2}
            {controller_object "The <span class='ug-code'>controller</span> object" 1}
            {controller_example "A simple controller example" 2}
            {implementing_controllers "Implementing controllers" 2}
            {implementing_actions "Implementing actions" 2}
            {request_object "The <span class='ug-code'>request</span> object" 1}
            {session_object "The <span class='ug-code'>session</span> object" 1}
            {icookies_object "The <span class='ug-code'>icookies</span> object" 1}
            {flash_object "The <span class='ug-code'>flash</span> object" 1}
            {params_object "The <span class='ug-code'>params</span> object" 1}
            {env_object "The <span class='ug-code'>env</span> object" 1}
            {response_construction "Response construction"}
            {response_object "The <span class='ug-code'>response</span> object" 1}
            {normal_response "Returning a normal response" 1}
            {redirects "Redirecting a request" 1}
            {error_responses "Sending error responses" 1}
            {response_headers "Adding HTTP response headers" 1}
            {sending_files "Sending files and non-HTML data" 1}
            {ocookies_object "The <span class='ug-code'>ocookies</span> object" 1}
            {page_generation "Page generation"}
            {page_layout "Page layout" 1}
            {default_page_layout "Default page layout" 2}
            {page_title "Setting the page title" 3}
            {default_layout_tailoring "Tailoring the default layout" 3}
            {extending_default_layout "Extending the default layout" 3}
            {custom_page_layout "Custom page layout" 2}
            {page_sections "Page sections" 1}
            {page_section_templates "Template based page sections" 2}
            {page_section_direct "Directly generated page sections" 2}
            {locating_templates "Locating templates" 1}
            {template_plugins "Template processor plug-ins" 1}
            {template_plugin_implementation "Implementing template processors" 2}
            {template_plugin_config "Configuring template processors" 2}
            {pagevar "The <span class='ug-code'>pagevar</span> object" 1}
            {static_resources "Using static resources" 1}
            {locating_resources "Locating static resources" 2}
            {using_images "Using images" 2}
            {using_stylesheets "Using stylesheets" 2}
            {using_javascript "Using Javascript" 2}
            {wtf "Woof! Template Format" 1}
            {responsive_web_design "Responsive web design"}
            {purecss_screen_widths "Pure CSS screen widths" 1}
            {enabling_responsive_pages "Enabling responsive pages" 1}
            {setting_responsive_threshold "Setting the responsive threshold" 1}
            {responsive_section_layout "Responsive section layout" 1}
            {responsive_content_visibility "Displaying responsive content" 1}
            {responsive_menus "Responsive menus" 1}
            {localization "Localization"}
            {client_language "Client language preference" 1}
            {message_catalogs "Using message catalogs" 1}
            {language_specific_pages "Language-specific page templates" 1}
            {library "The Woof! library"}
            {error_handling "Error handling" 1}
            {error_display "Error pages" 2}
            {error_generation "Generating exceptions" 2}
            {logging "The Logging interface" 1}
            {purecss "Pure CSS controls" 1}
            {purecss_buttons "Pure CSS buttons" 2}
            {purecss_menu "Pure CSS menus" 2}
            {purecss_table "Pure CSS tables" 2}
            {purecss_paginator "Pure CSS paginator" 2}
            {purecss_form "Pure CSS forms" 2}
            {purecss_images "Pure CSS images" 2}
            {purecss_skins "Skinning using Pure CSS" 2}
            {tools "Tools and utilities"}
            {installer "installer - installation utility" 1}
            {wag "wag - Woof! Application Generator" 1}
            {generating_stubs "Generating controller stubs" 2}
            {verifying_stubs "Verifying controller stubs" 2}
            {bowwow "bowwow - a Lightweight web Server" 1}
            {bowwow_exe "bowwow.exe standalone executable" 2}
            {bowwow_script "bowwow.tcl script" 2}
            {console "console - interactive console" 1}
            {ruffian "ruffian - documentation generator" 1}
            {scgi_winservice "scgi_winservice - Woof! Windows service" 1}
            {recommended_reading "Recommended reading"}
            {acknowledgements "Acknowledgements"}
        }

        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set layout _layout
        
        pagevar lappend scripts [my url_for_javascript _woof_ug.js]

        pagevar lappend stylesheets \
            [my url_for_stylesheet _woof_ug.css] \
            [my url_for_stylesheet pure-skin-ug.css]

        pagevar set responsive_settings { threshold sm }

        pagevar set main {cssclasses {+ pure-skin-ug}}

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
            return "<pre class='ug-console'>[hesc [::woof::util::remove_left_margin $text]]</pre>"
        } else {
            return "<pre class='ug-console'>[::woof::util::remove_left_margin $text]</pre>"
        }
    }

    method _filename {path} {
        return "<span class='ug-filename'>[::woof::util::hesc $path]</span>"
    }

    method _ui {text} {
        return "<span class='ug-ui'>[::woof::util::hesc $text]</span>"
    }

    method _code {text} {
        return "<span class='ug-code'>[::woof::util::hesc $text]</span>"
    }

    method _code_sample_with_output {text {escape true}} {
        append html "[my _code_sample $text $escape]\n"
        append html [my _sample_output [uplevel 1 [list subst $text]]]
        return $html
    }

    method _sample_output html {
        return "<div class='ug-sample'>$html</div>"
    }

    method _note {text} {
        return "<table class='ug-note'><tbody><tr><td>NOTE</td><td>[::woof::util::hesc $text]</td></tr></tbody></table>"
    }

    method _hnote {html} {
        return "<table class='ug-note'><tbody><tr><td>NOTE</td><td>$html</td></tr></tbody></table>"
    }

    method _image {image alt} {
        return [my include_image $image alt $alt class pure-img]
    }

    method _manpage_link {name {display ""}} {
        # Generates a link to manpage for a class or proc
        if {$display eq ""} {
            set display "<span class='ug-code'>[hesc [namespace tail $name]]</span>"
        }
        return "<a href='[my url_for_static woof_manual.html -subdir html/_woof]#$name'>$display</a>"
    }

    method _tcl_manpage_link {name {display ""}} {
        # Generates a link to Tcl manpage
        if {$display eq ""} {
            set display "<span class='ug-code'>[hesc [namespace tail $name]]</span>"
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
        append content "<div class='ug-toc'>"
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

