local function init(GLOBAL)
    local util = require("util")(GLOBAL)

    local function tcheck_any(checks)
        return {
            t = "any",
            checks = checks,
        }
    end

    local function tcheck_all(checks)
        return {
            t = "all",
            checks = checks,
        }
    end

    local function tcheck(checker, obj)
        return {
            t = "single",
            checker = checker,
            obj = obj,
        }
    end

    local function type_check(ty, obj)
        local root = ty.validate(obj)
        local stack = {}
        local progress_made = true

        local function head()
            local result = root
            for _, v in pairs(stack) do
                result = result.checks[v]
            end
            return result
        end

        local function set_stack(value)
            progress_made = true
            local last = root
            local second_to_last = nil
            for _, v in pairs(stack) do
                second_to_last = last
                last = last.checks[v]
            end
            if second_to_last == nil then
                root = value
            else
                second_to_last.checks[stack[#stack]] = value
            end
        end

        local function stack_copy()
            local copy = {}
            for k, v in pairs(stack) do
                copy[k] = v
            end
            return copy
        end

        while type(root) ~= "boolean" and progress_made do
            progress_made = false
            stack = {}
            local paths_to_check = { stack }

            while #paths_to_check > 0 do
                stack = table.remove(paths_to_check)
                local current = head()

                if type(current) == "boolean" then
                elseif current.t == "single" then
                    set_stack(current.checker.validate(current.obj))
                elseif current.t == "all" then
                    if #current.checks == 0 then
                        set_stack(true)
                    else
                        local all_true = true
                        local done = false
                        for _, v in pairs(current.checks) do
                            if v ~= true then
                                all_true = false
                            end
                            if v == false then
                                set_stack(false)
                                done = true
                            end
                        end
                        if all_true then
                            set_stack(true)
                            done = true
                        end
                        if not done then
                            for i, _ in pairs(current.checks) do
                                table.insert(stack, i)
                                table.insert(paths_to_check, stack_copy())
                                table.remove(stack)
                            end
                        end
                    end
                elseif current.t == "any" then
                    if #current.checks == 0 then
                        set_stack(false)
                    else
                        local all_false = true
                        local done = false
                        for _, v in pairs(current.checks) do
                            if v ~= false then
                                all_false = false
                            end
                            if v == true then
                                set_stack(true)
                                done = true
                            end
                        end
                        if all_false then
                            set_stack(false)
                            done = true
                        end
                        if not done then
                            for i, _ in pairs(current.checks) do
                                table.insert(stack, i)
                                table.insert(paths_to_check, stack_copy())
                                table.remove(stack)
                            end
                        end
                    end
                end
            end
        end

        if not progress_made then
            return false
        end

        return root
    end

    local function Any()
        return {
            describe = function()
                return "any"
            end,
            validate = function()
                return true
            end,
        }
    end

    local function Boolean(value)
        return {
            describe = function()
                return "boolean"
            end,
            validate = function(obj)
                return type(obj) == "boolean" and (value == nil or value == obj)
            end,
        }
    end

    local function Number(value)
        return {
            describe = function()
                return "number"
            end,
            validate = function(obj)
                return type(obj) == "number" and (value == nil or value == obj)
            end,
        }
    end

    local function Nil()
        return {
            describe = function()
                return "nil"
            end,
            validate = function(obj)
                return type(obj) == "nil"
            end,
        }
    end

    local function String(value)
        return {
            describe = function()
                return "string"
            end,
            validate = function(obj)
                return type(obj) == "string" and (value == nil or value == obj)
            end,
        }
    end

    local function Function()
        return {
            describe = function()
                return "function"
            end,
            validate = function(obj)
                return type(obj) == "function"
            end,
        }
    end

    local function Table(fields)
        fields = fields or {}
        return {
            describe = function()
                local desc = "table { "
                for k, v in pairs(fields) do
                    desc = desc .. k.describe() .. " = " .. v.describe() .. ", "
                end
                return desc .. "}"
            end,
            validate = function(obj)
                if type(obj) ~= "table" then
                    return false
                end
                local to_check = {}
                for k, v in pairs(fields) do
                    local kv_check = {}
                    for ok, ov in pairs(obj) do
                        table.insert(kv_check, tcheck_all({tcheck(k, ok), tcheck(v, ov)}))
                    end
                    table.insert(to_check, tcheck_any(kv_check))
                end
                return tcheck_all(to_check)
            end,
        }
    end

    local function Class(name, fields)
        local table = Table(fields)
        return {
            describe = function()
                local desc = name .. " { "
                for k, v in pairs(fields) do
                    desc = desc .. k.describe() .. " = " .. v.describe() .. ", "
                end
                return desc .. "}"
            end,
            validate = function(obj)
                local class = util.get_class(obj)
                if class == nil then
                    return false
                end
                return table.validate(class)
            end,
        }
    end

    local function Union(...)
        local options = { ... }
        return {
            describe = function()
                local desc = "union( "
                for _, option in pairs(options) do
                    desc = desc .. option.describe() .. ", "
                end
                return desc .. ")"
            end,
            validate = function(obj)
                local to_check = {}
                for _, option in pairs(options) do
                    table.insert(to_check, tcheck(option, obj))
                end
                return tcheck_any(to_check)
            end,
        }
    end

    local function Intersect(...)
        local options = { ... }
        return {
            describe = function()
                local desc = "intersect( "
                for _, option in pairs(options) do
                    desc = desc .. option.describe() .. ", "
                end
                return desc .. ")"
            end,
            validate = function(obj)
                if #options == 0 then
                    return false
                end
                local to_check = {}
                for _, option in pairs(options) do
                    table.insert(to_check, tcheck(option, obj))
                end
                return tcheck_all(to_check)
            end,
        }
    end

    return {
        type_check = type_check,
        Any = Any,
        Boolean = Boolean,
        Number = Number,
        Nil = Nil,
        String = String,
        Function = Function,
        Table = Table,
        Class = Class,
        Union = Union,
        Intersect = Intersect,
    }
end

return init