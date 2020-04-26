# block(func)
# return_from(name, value=nothing)
# available_restart(name)
# invoke_restart(name, args...)
# restart_bind(func, restarts...)
# error(exception::Exception)
# handler_bind(func, handlers...)

import Base: error

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
