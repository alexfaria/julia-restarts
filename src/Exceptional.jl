import Base: error

struct ReturnFromException <: Exception
    name
    value
end

current_available_restarts = []
current_available_handlers = []
current_block_id = 0

function block(func)
    global current_block_id
    current_block_id += 1
    name = current_block_id

    try
        func(name)
    catch e
        if e isa ReturnFromException && e.name == name
            return e.value
        end
        rethrow(e)
    end
end

function return_from(name, value = nothing)
    throw(ReturnFromException(name, value))
end

function available_restart(name)
    global current_available_restarts
    any(r -> r[1] == name, current_available_restarts)
end

function invoke_restart(name, args...)
    global current_available_restarts
    i = findfirst(r -> r[1] == name, current_available_restarts)
    func = current_available_restarts[i][2]
    func(args...)
end

function restart_bind(func, restarts...)
    global current_available_restarts
    block() do rb_block
        for r in restarts
            # wrap inside an anonymous function that captures the value of rb_block
            pushfirst!(current_available_restarts, (r[1] => (args...) -> return_from(rb_block, r[2](args...))))
        end

        try
            func()
        finally
            for i in restarts
                popfirst!(current_available_restarts)
            end
        end
    end
end

function error(exception::Exception)
    global current_available_handlers

    # procurar handlers
    for handler_group in current_available_handlers
        # só um por grupo, o primeiro
        for handler in handler_group
            # direct instance or else it is a direct instance of one subtype of that type
            if exception isa handler[1]
                handler[2](exception)
                break
            end
        end
    end

    throw(exception)
end

function handler_bind(func, handlers...)
    global current_available_handlers

    pushfirst!(current_available_handlers, handlers)

    try
        func()
    finally
        popfirst!(current_available_handlers)
    end
end
