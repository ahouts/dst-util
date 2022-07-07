local function access(item, ...)
    local args = { ... }
    local result = item
    for i = 1, #args do
        if result == nil then
            return nil
        end
        result = result[args[i]]
    end
    return result
end

local function display(o, printer)
    local println = printer or access(GLOBAL, "modprint") or print

    local function short_display(obj)
        local known_types = {}
        local display_known = {}
        local validate = {}

        local function add_known(t, disp, v)
            for k, _ in pairs(t) do
                known_types[k] = t
            end
            display_known[t] = disp
            validate[t] = v
        end

        add_known({ x = false, y = false, z = false }, tostring)
        add_known({ false }, function(item)
            return "{ " .. tostring(item[1]) .. " }"
        end, function(item)
            return type(item[1]) == "function"
        end)

        for k, _ in pairs(obj) do
            if known_types[k] then
                known_types[k][k] = true
            end
        end

        for _, known in pairs(known_types) do
            local correct = true
            for _, set in pairs(known) do
                if not set then
                    correct = false
                end
            end
            for k, _ in pairs(obj) do
                if not known[k] then
                    correct = false
                end
            end
            local v = validate[known]
            if v ~= nil then
                if not v(obj) then
                    correct = false
                end
            end
            if correct then
                return display_known[known](obj)
            end
        end
    end

    local ids = {
        root = 1,
        beginrow = 2,
        sep = 3,
        endkv = 4,
        endtable = 5,
    }

    local depth = 0
    local head = 1
    local stack = { { ids.root, o } }
    local line = ""
    local already_seen = {}

    local function pop()
        local p = stack[head]
        stack[head] = nil
        head = head - 1
        return p
    end

    local function push(val)
        head = head + 1
        stack[head] = val
    end

    local function write(txt)
        line = line .. txt
    end

    local function writeln(txt)
        write(txt)
        println(line)
        line = ""
    end

    local function indent()
        for _ = 1, depth do
            line = line .. "    "
        end
    end

    while head > 0 do
        local p = pop()
        local t = p[1]
        local val = p[2]

        if t == ids.root then
            if type(val) == 'table' then
                local short = short_display(val)
                if short then
                    write(short)
                elseif already_seen[val] then
                    write("<")
                    write(tostring(val))
                    write(">")
                else
                    already_seen[val] = true
                    write(tostring(val))
                    writeln(" @ {")

                    depth = depth + 1

                    push({ ids.endtable })

                    for k, v in pairs(val) do
                        push({ ids.endkv })
                        push({ ids.root, v })
                        push({ ids.sep })
                        push({ ids.root, k })
                        push({ ids.beginrow })
                    end
                end
            else
                write(tostring(val))
            end
        elseif t == ids.beginrow then
            indent()
        elseif t == ids.sep then
            write(" = ")
        elseif t == ids.endkv then
            writeln(",")
        elseif t == ids.endtable then
            depth = depth - 1
            indent()
            write("}")
        end
    end
    writeln("")
end

return { display = display, access = access }
