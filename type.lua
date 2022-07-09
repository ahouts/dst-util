local function init(util)
    local tcheck_type = {
        any = 1,
        all = 2,
        single = 3,
        invert = 4,
    }

    local function tcheck_any(checks)
        local all_booleans = true
        for _, check in pairs(checks) do
            if check == true then
                return true
            end
            if type(check) ~= "boolean" then
                all_booleans = false
            end
        end
        if all_booleans then
            return false
        end
        return {
            t = tcheck_type.any,
            checks = checks,
        }
    end

    local function tcheck_all(checks)
        local all_booleans = true
        for _, check in pairs(checks) do
            if check == false then
                return false
            end
            if type(check) ~= "boolean" then
                all_booleans = false
            end
        end
        if all_booleans then
            return true
        end
        return {
            t = tcheck_type.all,
            checks = checks,
        }
    end

    local function tcheck_invert(check)
        if type(check) == "boolean" then
            return not check
        end
        return {
            t = tcheck_type.invert,
            check = check,
        }
    end

    local function tcheck(checker, obj)
        if checker.constant_stack then
            return checker.validate(obj)
        end
        return {
            t = tcheck_type.single,
            checker = checker,
            obj = obj,
        }
    end

    local function type_check(ty, obj)
        local root = ty.validate(obj)
        local stack = {}
        local progress_made = true

        local function walk(item, idx)
            if item.t == tcheck_type.all or item.t == tcheck_type.any then
                return item.checks[idx]
            elseif item.t == tcheck_type.invert then
                return item.check
            end
        end
        local function assign(item, idx, value)
            if item.t == tcheck_type.all or item.t == tcheck_type.any then
                item.checks[idx] = value
            elseif item.t == tcheck_type.invert then
                item.check = value
            end
        end

        local function head()
            local result = root
            for _, v in pairs(stack) do
                result = walk(result, v)
            end
            return result
        end

        local function set_stack(value)
            progress_made = true
            local last = root
            local second_to_last = nil
            for _, v in pairs(stack) do
                second_to_last = last
                last = walk(last, v)
            end
            if second_to_last == nil then
                root = value
            else
                assign(second_to_last, stack[#stack], value)
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
                elseif current.t == tcheck_type.single then
                    set_stack(current.checker.validate(current.obj))
                elseif current.t == tcheck_type.all then
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
                elseif current.t == tcheck_type.any then
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
                elseif current.t == tcheck_type.invert then
                    if type(current.check) == "boolean" then
                        set_stack(not current.check)
                    else
                        table.insert(stack, 0)
                        table.insert(paths_to_check, stack_copy())
                        table.remove(stack)
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
                return "<any>"
            end,
            validate = function()
                return true
            end,
            constant_stack = true,
        }
    end

    local function Boolean(value)
        return {
            describe = function()
                if value ~= nil then
                    return tostring(value)
                end
                return "<a boolean>"
            end,
            validate = function(obj)
                return type(obj) == "boolean" and (value == nil or value == obj)
            end,
            constant_stack = true,
        }
    end

    local function Number(value)
        return {
            describe = function()
                if value ~= nil then
                    return tostring(value)
                end
                return "<a number>"
            end,
            validate = function(obj)
                return type(obj) == "number" and (value == nil or value == obj)
            end,
            constant_stack = true,
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
            constant_stack = true,
        }
    end

    local function String(value)
        return {
            describe = function()
                if value ~= nil then
                    return tostring(value)
                end
                return "<a string>"
            end,
            validate = function(obj)
                return type(obj) == "string" and (value == nil or value == obj)
            end,
            constant_stack = true,
        }
    end

    local function Function()
        return {
            describe = function()
                return "<a function>"
            end,
            validate = function(obj)
                return type(obj) == "function"
            end,
            constant_stack = true,
        }
    end

    local function Primitive(value)
        if type(value) == "nil" then
            return Nil()
        elseif type(value) == "boolean" then
            return Boolean(value)
        elseif type(value) == "number" then
            return Number(value)
        elseif type(value) == "string" then
            return String(value)
        elseif type(value) == "function" then
            return Function()
        else
            util.error("unknown primitive")
        end
    end

    local function Table(fields)
        tmp_fields = fields or {}
        fields = {}
        for key, value in pairs(tmp_fields) do
            if type(key) ~= "table" then
                key = Primitive(key)
            end
            if type(value) ~= "table" then
                value = Primitive(value)
            end
            fields[key] = value
        end
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
                    local k_check = {}
                    for ok, _ in pairs(obj) do
                        table.insert(k_check, tcheck(k, ok))
                    end
                    local key_not_found = tcheck_invert(tcheck_any(k_check))
                    local nil_ok = tcheck_all({tcheck(k, nil), tcheck(v, nil), key_not_found})

                    local kv_check = {nil_ok}
                    for ok, ov in pairs(obj) do
                        table.insert(kv_check, tcheck_all({ tcheck(k, ok), tcheck(v, ov) }))
                    end

                    table.insert(to_check, tcheck_any(kv_check))
                end
                return tcheck_all(to_check)
            end,
            constant_stack = false,
        }
    end

    local function Class(name, fields)
        local table = Table(fields)
        tmp_fields = fields or {}
        fields = {}
        for key, value in pairs(tmp_fields) do
            if type(key) ~= "table" then
                key = Primitive(key)
            end
            if type(value) ~= "table" then
                value = Primitive(value)
            end
            fields[key] = value
        end
        return {
            describe = function()
                local desc = name .. " { "
                for k, v in pairs(fields) do
                    desc = desc .. k.describe() .. " = " .. v.describe() .. ", "
                end
                return desc .. "}"
            end,
            validate = function(obj)
                if type(obj) ~= "table" then
                    return false
                end
                local class = util.get_class(obj)
                if class == nil then
                    return false
                end
                return table.validate(class)
            end,
            constant_stack = false,
        }
    end

    local function Union(...)
        local options = { ... }
        for i, option in pairs(options) do
            if type(option) ~= "table" then
                options[i] = Primitive(option)
            end
        end
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
            constant_stack = #options == 0,
        }
    end

    local function Intersect(...)
        local options = { ... }
        for i, option in pairs(options) do
            if type(option) ~= "table" then
                options[i] = Primitive(option)
            end
        end
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
                    if type(option) ~= "table" then
                        option = Primitive(option)
                    end
                    table.insert(to_check, tcheck(option, obj))
                end
                return tcheck_all(to_check)
            end,
            constant_stack = #options == 0,
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