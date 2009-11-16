puts ns:[namespace current]
uses TestController
oo::class create RequestController {
    superclass TestController
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args
    }
}

oo::define RequestController {
    method dump {} {
        # Nothing to do. Let template do it all
    }
}
