

oo::class create UgController {
    superclass ApplicationController
    variable _toc _dispatchinfo
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
            {qs_first_steps "First Steps" 2}
            {qs_stubs_generate "Generating Stubs" 2}
            {qs_stubs_implement "Implementing the Stubs" 2}
            {qs_session "Keeping State" 2}
            {qs_page_display "Displaying the Page" 2}
            {qs_enhancements "Enhancing the Application" 2}
            {qs_page_layout "Laying out a Page" 2}
            {qs_story_so_far "The Story So Far" 2}
            {qs_wtf_syntax "Writing Page Templates" 2}
            {qs_user_input "Getting User Input" 2}
            {qs_flash "Using the Flash" 2}
            {qs_default_page "Configuring the Default Page" 2}
            {qs_finish "Finishing Up" 2}
            {installation "Installation"}
            {install_under_bowwow "Woof! under BowWow" 2}
            {install_under_apache "Woof! under Apache 2" 2}
            {apache_cgi_dedicated "Dedicated CGI on Apache" 3}
            {apache_cgi_shared "Shared CGI on Apache" 3}
            {apache_scgi "SCGI on Apache" 3}
            {install_final_steps "Verifying the Installation" 2}
            {tools "Tools and Utilities"}
            {installer "installer - Installation Utility" 2}
            {bowwow "bowwow - a Lightweight Web Server" 2}
            {page_generation "Page Generation"}
            {wtf "Woof! Template Files"}
            {recommended_reading "Recommended Reading"}
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
        pagevar set module_subheading "User Guide"
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
        return [my link_to [hesc $display] -action $action]
    }

    method _code_sample {text} {
        # Returns a code sample
        return "<pre class='woof_console_session'>[hesc [::woof::util::remove_left_margin $text]]</pre>"
    }

}

