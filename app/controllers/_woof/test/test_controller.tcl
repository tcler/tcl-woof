oo::class create TestController {
    superclass ApplicationController
    mixin DevModeOnly LocalClientOnly
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args
        # Only use Woof default section layout, not something user might
        # have defined.
        pagevar set layout _layout
        
        pagevar set responsive_settings { threshold sm }

        pagevar lappend stylesheets [my url_for_stylesheet _woof.css]

        pagevar set styles [my url_for_stylesheet _woof.css]
    }
    
    method stop {} {
        page store main "Stopped"
        woof::webserver stop
    }
}
