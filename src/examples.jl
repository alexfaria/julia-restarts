struct DivisionByZero <: Exception end

reciprocal(x) = x == 0 ? error(DivisionByZero()) : 1 / x

reciprocal(10) # 0.1

try
    reciprocal(0)
catch r
    print("i saw $(r)")
end

handler_bind(DivisionByZero => (c) -> println("I saw a division by zero")) do
    reciprocal(0)
end


handler_bind(DivisionByZero => (c) -> println("I saw it too")) do
    handler_bind(
        DivisionByZero => (c) -> println("I saw a division by zero"),
    ) do
        reciprocal(0)
    end
end

mystery(n) = 1 + block() do outer
    1 + block() do inner
        1 + if n == 0
            return_from(inner, 1)
        elseif n == 1
            return_from(outer, 1)
        else
            1
        end
    end
end

mystery(0)
mystery(1)
mystery(2)

block() do escape
    handler_bind(DivisionByZero => (c) -> (println("I saw it too");
    return_from(escape, "Done"))) do
        handler_bind(
            DivisionByZero => (c) -> println("I saw a division by zero"),
        ) do
            reciprocal(0)
        end
    end
end

block() do escape
    handler_bind(DivisionByZero => (c) -> println("I saw it too")) do
        handler_bind(
            DivisionByZero => (c) -> (println("I saw a division by zero");
            return_from(escape, "Done")),
        ) do
            reciprocal(0)
        end
    end
end


reciprocal(value) =
    restart_bind(
        :return_zero => () -> 0,
        :return_value => identity,
        :retry_using => reciprocal,
    ) do
        value == 0 ? error(DivisionByZero()) : 1 / value
    end

# outro exemplo
reciprocal(value) =
    restart_bind(
        :return_zero => () -> 0,
        :return_value => identity,
        :retry_using => reciprocal,
    ) do
        r = 0
        if value == 0
            r = error(DivisionByZero()) + 100
        else
            r = value
        end
        println("Reciprocal of $(value) is $(r)")
        r
    end

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_zero)) do
    reciprocal(0)
end

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_value, 1)) do
    reciprocal(0)
end

handler_bind(DivisionByZero => (c) -> invoke_restart(:retry_using, 10)) do
    reciprocal(0)
end

handler_bind(
    DivisionByZero =>
        (c) -> for restart in (:return_one, :return_zero, :die_horribly)
            if available_restart(restart)
                invoke_restart(restart)
            end
        end,
) do
    reciprocal(0)
end

infinity() =
    restart_bind(:just_do_it => () -> 1 / 0) do
        reciprocal(0)
    end

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_zero)) do
    infinity()
end
# 0

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_value, 1)) do
    infinity()
end
# 1

handler_bind(DivisionByZero => (c) -> invoke_restart(:just_do_it)) do
    infinity()
end
# Inf

@handler_case(
    reciprocal(0),
    DivisionByZero => (c) -> (println("I saw a division by zero!"); 10),
)

@handler_case(DivisionByZero => (c) -> (println("I saw a division by zero!"); 10)) do
    reciprocal(0)
end

struct TestingHandlerCase <: Exception end

function nested_handler_case()
    @handler_case(
        reciprocal(0),
        DivisionByZero => (c) -> println("I saw a division by zero!"),
    )
    error(TestingHandlerCase())
end

@handler_case(
    nested_handler_case(),
    TestingHandlerCase => (c) -> println("I saw TestingHandlerCase"),
)

@handler_case(DivisionByZero => (c) -> invoke_restart(:return_value, 10)) do
    @restart_case(
                  :return_zero => () -> 0,
                  :return_value => identity,
                  :retry_using => reciprocal
                  ) do
                  reciprocal(0)
              end
end

struct LineEndLimit <: Exception end

function print_line(str)
    block() do truncate
        line_end = 5
        col = 0

        for i = 1:length(str)
            print(str[i])

            if col < line_end
                col = col + 1
            else
                restart_bind(
                    :wrap => () -> (println(); col = 0),
                    :truncate => () -> (return_from(truncate, col)),
                    :continue => () -> (col = col + 1),
                ) do
                    error(LineEndLimit())
                end
            end
        end
        col
    end
end

print_line("ola")
print_line("0123456789")

handler_bind(LineEndLimit => (c) -> invoke_restart(:continue)) do
    print_line("0123456789")
end


## INTERACTIVE RESTART EXAMPLES

struct DivisionByZero <: Exception end

reciprocal(value) =
    restart_bind(
        Restart(:return_zero => (args...) -> 0, report="Return Zero"),
        Restart(:return_value => identity, report="Return Value", interactive=true, test=() -> false),
        Restart(:retry_using => reciprocal, report="Retry with another parameter", interactive=true)
    ) do
        value == 0 ? error(DivisionByZero()) : 1 / value
    end

reciprocal(value) =
    restart_bind(
        :return_zero => () -> 0,
        :return_value => identity,
        :retry_using => reciprocal,
    ) do
        value == 0 ? error(DivisionByZero()) : 1 / value
    end

handler_bind(DivisionByZero => (c) -> (println("Zero!"); invoke_restart(:return_zero))) do
    reciprocal(0)
end
reciprocal(0)
