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
            {installation Installation}
            {apache Apache 2}
            {iis IIS 2}
            {systemrequirements "System Requirements"}
            {recommendedreading "Recommended Reading"}
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
            {relativeurl stylesheets/_yui-2-8-0r4-reset-fonts-grids.css}
            {relativeurl stylesheets/_yui-2-8-0r4-base-min.css}
            {file _woof.css}
            {file _woof_ug.css}
        }

        # Set page title based on the section
        pagevar set title "Woof! - [my _heading]"
        pagevar set module_subheading "User Guide"
    }

    method _heading {{action ""}} {
        if {$action eq ""} {
            set action [my requested_action]
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
        set action [my requested_action]
        set i [lsearch -exact -index 0 $_toc $action]
        return [list [lindex $_toc [expr {$i-1}]] [lindex $_toc [incr i]]]
    }

    method _missing_action {action} {
        # Empty method as we will just show the templates
    }
}

