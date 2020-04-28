# block(func)
# return_from(name, value=nothing)
# available_restart(name)
# invoke_restart(name, args...)
# restart_bind(func, restarts...)
# error(exception::Exception)
# handler_bind(func, handlers...)

import Base: error

struct ReturnFromException <: Exception
    name
    expr
end

function block(func)
    name = nothing
    try
        name = (Base.method_argnames(methods(func).ms[1])[2])
        func(name)
    catch e
        if e isa ReturnFromException
            if Symbol(e.name) == name
                return e.expr
            end
        end
        rethrow(e)
    end
end

function return_from(name, value=nothing)
    throw(ReturnFromException(name, value))
end

current_available_restarts = []

function available_restart(name)
    global current_available_restarts
    any(r->r[1] == name, current_available_restarts)
end

function invoke_restart(name, args...)
    global current_available_restarts
    i = findfirst(r->r[1] == name, current_available_restarts)
    func = current_available_restarts[i][2]
    func(args...)
end

function restart_bind(func, restarts...)
    global current_available_restarts
    for r in restarts
        push!(current_available_restarts, r)
    end
    result = nothing
    try
        result = func()
    catch e
        rethrow(e)
    end

    # nao corre porque rethrow
    # tmb é preciso depois no handler_bind
    for i in restarts
        pop!(current_available_restarts)
    end
    result
end

error(exception::Exception) = throw(exception)

function handler_bind(func, handlers...)
    try
        func()
    catch exception
        for handler in handlers
            if  exception isa handler[1]
                return handler[2](exception)
            end
        end
        rethrow(exception)
    end
end

# Signal Extension: idk

# type SignalException <: Exception
#    var::String
# end

# signal(msg) = throw(SignalException(msg))
