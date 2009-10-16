oo::class create TestController {
    superclass ApplicationController
    mixin DevModeOnly LocalClientOnly
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
            {relativeurl stylesheets/_yui-2-8-0r4-reset-fonts-grids.css}
            {relativeurl stylesheets/_yui-2-8-0r4-base-min.css}
            {file _woof.css}
        }
    }
}
