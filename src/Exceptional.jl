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

function block(func, name)
    try
        func(name)
    catch e
        if e isa ReturnFromException
            if  e.name == name
                return e.expr
            end
        end
        rethrow(e)
    end
end

function return_from(name, value=nothing)
    throw(ReturnFromException(name, value))
end

error(exception::Exception) = throw(exception)

function handler_bind(func, handlers...)
    try
        func()
    catch exception
        for handler in handlers
            if  exception isa handler[1]
                handler[2](exception)
            end
        end
        rethrow(exception)
    end
end
