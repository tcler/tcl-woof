oo::class create ManageController {
    superclass ApplicationController
    variable woof_url
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args

        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set section_layout_alias _layout
        
        # Customize the layout as per our liking
        pagevar set \
            yui_page_width 750px \
            yui_sidebar_width 160px \
            yui_main_percent 75%
            
        pagevar set styles {
            stylesheets/_yui-2-8-0r4-reset-fonts-grids.css
            stylesheets/_yui-2-8-0r4-base-min.css
            _woof.css
        }

        pagevar set module_subheading "Site management"
    }
}

oo::define ManageController {
    method index {} {
        my redirect -action welcome
    }

    method welcome {} {
        # Nothing to do for the welcome page but display the template
    }

    method print_env {} {
        # Nothing to do but display the template
    }

    method print_config {} {
        # Nothing to do but display the template
    }
}
