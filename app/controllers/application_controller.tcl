# All application controllers should be derived from this
# class and not directly from Controller. Any mixins,
# filters etc. should be done here

catch {ApplicationController destroy}
oo::class create ApplicationController {
    superclass ::woof::Controller
    constructor args {
        next {*}$args
    }
}