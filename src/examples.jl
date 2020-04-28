struct DivisionByZero <: Exception end

reciprocal(x) = x == 0 ? error(DivisionByZero()) : 1 / x

reciprocal(10)

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


mystery(n) = 1 + block("outer") do outer
    1 + block("inner") do inner
        1 + if n == 0
            return_from(inner, 1)
        elseif n == 1
            return_from(outer, 1)
        else
            1
        end
    end
end

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
        :retry_using => reciprocal
    ) do
        value == 0 ? error(DivisionByZero()) : 1 / value
    end

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_zero)) do
    reciprocal(0)
end

handler_bind(DivisionByZero => (c) -> invoke_restart(:return_value, 1)) do
    reciprocal(0)
end

handler_bind(DivisionByZero => (c)->invoke_restart(:retry_using, 10)) do
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
#1
