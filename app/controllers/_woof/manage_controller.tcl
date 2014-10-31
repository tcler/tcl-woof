oo::class create ManageController {
    superclass ApplicationController
    variable woof_url
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args

        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set layout _layout
        
        pagevar set styles {
            _woof.css
        }

        pagevar set sidebar {tag nav cssclasses {wf_nav}}
        pagevar set main {cssclasses {+ pure-skin-woof}}

        pagevar set MODULE_SUBHEADING "Site management"
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
