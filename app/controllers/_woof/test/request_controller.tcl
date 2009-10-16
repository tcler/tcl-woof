uses TestController
oo::class create RequestController {
    superclass TestController
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args
    }
}

oo::define RequestController {
    method index {} {
        # Nothing to do. Let template do it all
    }
}
