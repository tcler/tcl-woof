oo::class create woof::_ManageController {
    superclass ApplicationController
    variable woof_url
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args

        set woof_url(user_guide) "http://woof.magicsplat.com/woof_guide"
        set woof_url(quick_start) "http://woof.magicsplat.com/woof_guide/quick_start"
        set woof_url(reference)   "http://woof.magicsplat.com/manuals/woof/index.html"
    }
}

oo::define woof::_ManageController {
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
