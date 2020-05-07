function signal(exception::Exception)
    global current_available_handlers

    for handler_group in current_available_handlers
        #TODO: descobrir se o signal so corre o primeiro handler
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
        for handler in handlers
            push!(handler.args[3].args[2].args, :(return_from($(esc(escape_block)))))
        end
        quote
            block() do $(esc(escape_block))
                handler_bind($(handlers...)) do
                    $func
                end
            end
        end
    end
end
