local util = require("util")({})
local type = require("type")(util)

local function assert_matches(ty, value)
    if not type.type_check(ty, value) then
        util.modprint("expected", ty.describe())
        util.modprint("actual")
        util.display(value)
        util.error("did not match when supposed to match")
    end
end
local function assert_not_matches(ty, value)
    if type.type_check(ty, value) then
        util.modprint("expected", ty.describe())
        util.modprint("actual")
        util.display(value)
        util.error("matched when not supposed to match")
    end
end
local function assert_throws(func, ...)
    local success, mesg = pcall(func, ...)
    assert_matches(type.Table({ type.Boolean(false), type.Any() }), { success, mesg })
end

assert_matches(
        type.Table({
            [type.String()] = type.Number(),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_matches(
        type.Table({
            [type.String("abc")] = type.Number(),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_matches(
        type.Table({
            abc = type.Number(),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_matches(
        type.Table({
            abc = 123,
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_not_matches(
        type.Table({
            abc = 1234,
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_not_matches(
        type.Table({
            def = 123,
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_matches(
        type.Table({
            [type.String()] = type.Number(123),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = 10,
            }
        }
)

assert_matches(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ aaa = 2 })] = true
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = true,
            }
        }
)

assert_not_matches(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ aaa = 2 })] = false
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = true,
            }
        }
)

assert_not_matches(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ aaa = type.Number(3) })] = true
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = true,
            }
        }
)

assert_not_matches(
        type.Union(
                type.Table({})
        ),
        false
)

assert_matches(
        type.Union(
                type.Table({}),
                type.Boolean()
        ),
        false
)

assert_matches(
        type.Intersect(
                type.Table({
                    [type.String("abc")] = type.Number(),
                }),
                type.Table({
                    [type.String("def")] = type.Boolean(),
                })
        ),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = true,
            }
        }
)

assert_not_matches(
        type.Intersect(
                type.Table({
                    [type.String("abc")] = type.Number(),
                }),
                type.Table({
                    [type.String("def")] = type.Table(),
                })
        ),
        {
            abc = 123,
            def = false,
            ghi = {
                [{ aaa = 2 }] = true,
            }
        }
)

assert_not_matches(
        type.Intersect(),
        {}
)

assert_not_matches(
        type.Union(),
        {}
)

assert_matches(
        type.Table(),
        {}
)

assert_not_matches(
        type.Table(),
        false
)

assert_matches(
        type.Class("Torpedo", {
            speed = type.Number(),
        }),
        {
            ["_"] = {
                speed = 100,
            }
        }
)

assert_not_matches(
        type.Class("Torpedo", {
            speed = type.Number(),
        }),
        {
            speed = 100,
        }
)

assert_matches(
        type.Union(5, 6),
        6
)

assert_not_matches(
        type.Union(5, 6),
        7
)

assert_matches(
        type.Intersect(5, type.Any()),
        5
)

assert_not_matches(
        type.Intersect(5, 6),
        5
)

assert_matches(
        type.Table({
            type.Table({
                type.Table({
                    "abc"
                }),
            }),
            true,
        }),
        {
            { { "abc" } },
            true,
        }
)

local variant_1 = type.Table({
    id = "variant_1",
    field_1 = type.String(),
    field_2 = type.Union(type.String(), type.Number()),
    field_3 = type.Any(),
})

local variant_2 = type.Table({
    id = "variant_2",
    field_1 = type.String(),
    [type.Union(type.Nil(), type.String("field_7"))] = type.Union(type.Nil(), type.String()),
})

local variant_3 = type.Table({
    id = "variant_3",
})

local sum_type = type.Union(variant_1, variant_2, variant_3)

assert_matches(
        sum_type,
        {
            id = "variant_1",
            field_1 = "asdf",
            field_2 = 123,
            field_3 = {},
        }
)

assert_not_matches(
        sum_type,
        {
            id = "variant_1",
            field_1 = 321,
            field_2 = 123,
            field_3 = {},
        }
)

assert_matches(
        sum_type,
        {
            id = "variant_2",
            field_1 = "asdf",
        }
)

assert_not_matches(
        sum_type,
        {
            id = "variant_2",
            field_1 = "asdf",
            field_7 = false,
        }
)

assert_matches(
        sum_type,
        {
            id = "variant_3",
            aaa = "123",
        }
)

assert_not_matches(
        sum_type,
        {
            id = "variant_4",
        }
)

assert_not_matches(sum_type, {})
assert_not_matches(sum_type, true)

local my_func = type.TypedFunction(
        {
            type.Number(),
            type.String(),
            type.Union(type.Nil(), type.String())
        },
        type.Table({ ok = type.Boolean(), }),
        function(the_number, the_string, maybe_string)
            if the_number == 5 then
                return "AAAAA"
            end
            return { ok = true }
        end)

assert_throws(my_func, 1, 1)
assert_throws(my_func)
assert_throws(my_func, 1, "a", 2)
assert_throws(my_func, 5, "a")

assert_matches(
        type.Table({ ok = true }),
        my_func(1, "a")
)
assert_matches(
        type.Table({ ok = true }),
        my_func(1, "a", "b")
)