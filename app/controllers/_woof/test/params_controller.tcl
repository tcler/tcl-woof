uses TestController
oo::class create ParamsController {
    superclass TestController
    constructor args {
        # Very important to pass arguments to parent
        next {*}$args
    }
}

oo::define ParamsController {
    method dump {} {
        params lazy_load
    }
}
