current_available_handlers = []
current_available_handlers = push!(current_available_handlers, [Exception => (c) -> restart_user_handler(c)])

function restart_user_handler(exception)
    global current_available_restarts
    if length(current_available_restarts) > 0
        println()
        println("#<$(exception)>#")
        println(" [Condition of type $(typeof(exception))]")
        println("Restarts:")
        i = 1
        for restart in current_available_restarts
            println(" $(i): [$(uppercase(String(restart[1])))] $(restart[1])")
            i += 1
        end

        selected_restart = readline()
        i = tryparse(Int, selected_restart)
        invoke_restart(current_available_restarts[i][1])
    end
end

function signal(exception::Exception)
    global current_available_handlers

    for handler_group in current_available_handlers
        for handler in handler_group
            if exception isa handler[1]
                handler[2](exception)
                break
            end
        end
    end
end

macro handler_case(func, handlers...)
    let
        escape_block = Symbol("escape_block")
        handler_func = func

        for handler in handlers
            handler_body = handler.args[3].args[2]
            handler.args[3].args[2] = :(return_from($(escape_block), $handler_body))
        end

        # hack in order to work with both macro calling syntax
        # @handler_case(reciprocal(0), DivisionByZero => (c) -> println("zero!"))
        # @handler_case(DivisionByZero => (c) -> println("zero!")) do reciprocal(0) end
        if func.head == :call
            handler_func = :(() -> begin $func end)
        end
        quote
            block() do $(escape_block)
                handler_bind($handler_func, $(handlers...))
            end
        end
    end
end

macro restart_case(func, restarts...)
    let
        quote
            restart_bind($func, $(restarts...))
        end
    end
end
