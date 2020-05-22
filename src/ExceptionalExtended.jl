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


## INTERACTIVE RESTARTS

# https://www.cs.cmu.edu/Groups/AI/html/cltl/clm/node341.html#SECTION003347000000000000000
mutable struct Restart
    restart     # restart pair :return_zero => () -> 0
    test        # test if the restart is available
    interactive # function to get the parameters for the restart
    report      # name of the restart that appears in the prompt

    function Restart(restart; test= ()->true, interactive=nothing, report=nothing)
        interactive = interactive == nothing ? () -> readline() : interactive
        report = report == nothing ? string(name) : report
        new(restart, test, interactive, report)
    end
end

current_available_interactive_restarts = []
current_available_handlers = push!(current_available_handlers, [Exception => (c) -> picking_interactive_restart_handler(c)])
function picking_interactive_restart_handler(exception)
    global current_available_restarts
    restarts = filter(r -> (r[2].r isa Restart && r[2].r.test()), current_available_restarts)
    if length(restarts) > 0
        println()
        println("#<$(exception)>#")
        println(" [Condition of type $(typeof(exception))]")
        println("Restarts:")
        i = 1
        for r in restarts
            println(" $(i): [$(uppercase(String(r[1])))] $(r[2].r.report)")
            i += 1
        end

        selected_restart = readline()
        i = tryparse(Int, selected_restart)
        selected_restart = restarts[i]

        value = nothing
        if selected_restart[2].r.interactive != nothing
            println("Input parameters: ")
            value = Meta.parse(selected_restart[2].r.interactive())
        end
        invoke_restart(selected_restart[1], value)
    end
end

function restart_bind(func, restarts::Restart...)
    global current_available_restarts
    block() do rb_block

        for r in restarts
            # meter dentro de outra funcao que recebe rb_block
            pushfirst!(current_available_restarts, (r.restart[1] => (args...) -> return_from(rb_block, r.restart[2](args...))))
        end
        pushfirst!(current_available_interactive_restarts, restarts)

        try
            func()
        finally
            for i in restarts
                popfirst!(current_available_restarts)
            end
            popfirst!(current_available_interactive_restarts)
        end
    end
end
