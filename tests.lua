
local util = require("util")({})
local type = require("type")({})

local function assert_eq(expected, actual, ...)
    if expected ~= actual then
        util.modprint("expected")
        util.display(expected)
        util.modprint("actual")
        util.display(actual)
        util.error(...)
    end
end

local function assert(actual, ...)
    assert_eq(true, actual, ...)
end

assert(type.type_check(
        type.Table({
            [type.String()] = type.Number(),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = 10,
            }
        }
))

assert(type.type_check(
        type.Table({
            [type.String("abc")] = type.Number(),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = 10,
            }
        }
))

assert(type.type_check(
        type.Table({
            [type.String()] = type.Number(123),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = 10,
            }
        }
))

assert(type.type_check(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ [type.String("aaa")] = type.Number(2)})] = type.Boolean(true)
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = true,
            }
        }
))

assert(not type.type_check(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ [type.String("aaa")] = type.Number(2)})] = type.Boolean(false)
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = true,
            }
        }
))

assert(not type.type_check(
        type.Table({
            [type.String()] = type.Table({
                [type.Table({ [type.String("aaa")] = type.Number(3)})] = type.Boolean(true)
            }),
        }),
        {
            abc = 123,
            def = false,
            ghi = {
                [{aaa = 2}] = true,
            }
        }
))

assert(not type.type_check(
        type.Union(
                type.Table({})
        ),
        false
))

assert(type.type_check(
        type.Union(
                type.Table({}),
                type.Boolean()
        ),
        false
))

assert(type.type_check(
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
                [{aaa = 2}] = true,
            }
        }
))

assert(not type.type_check(
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
                [{aaa = 2}] = true,
            }
        }
))

assert(not type.type_check(
        type.Intersect(),
        {}
))

assert(not type.type_check(
        type.Union(),
        {}
))

assert(type.type_check(
        type.Table(),
        {}
))

assert(not type.type_check(
        type.Table(),
        false
))

assert(type.type_check(
        type.Class("Torpedo", {
            [type.String("speed")] = type.Number(),
        }),
        {
            ["_"] = {
                speed = 100,
            }
        }
))

assert(not type.type_check(
        type.Class("Torpedo", {
            [type.String("speed")] = type.Number(),
        }),
        {
            speed = 100,
        }
))
