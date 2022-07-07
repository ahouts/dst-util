local function display(o, _println)
    local _println = _println or GLOBAL.modprint

    local function short_display(obj)
        local known_types = {}
        local display_known = {}
        local validate = {}

        local function add_known(t, disp, v)
            for k,_ in pairs(t) do
                known_types[k] = t
            end
            display_known[t] = disp
            validate[t] = v
        end

        add_known({x = false, y = false, z = false}, tostring)
        add_known({false}, function()
            return "{ function }"
        end, function(item)
            return type(item[1]) == "function"
        end)

        for k,_ in pairs(obj) do
            if known_types[k] then
                known_types[k][k] = true
            end
        end

        for _,known in pairs(known_types) do
            local correct = true
            for _,set in pairs(known) do
                if not set then
                    correct = false
                end
            end
            for k,_ in pairs(obj) do
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

    local depth = 0
    local head = 1
    local stack = { {"root", o} }
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
        _println(line)
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

        if t == "root" then
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

                    push({"endtable"})
                    for k,v in pairs(val) do
                        push({"endkv"})
                        push({"root", v})
                        push({"sep"})
                        push({"root", k})
                        push({"beginrow"})
                    end
                end
            else
                write(tostring(val))
            end
        elseif t == "beginrow" then
            indent()
        elseif t == "sep" then
            write(" = ")
        elseif t == "endkv" then
            writeln(",")
        elseif t == "endtable" then
            depth = depth - 1
            indent()
            write("}")
        end
    end
    writeln("")
end

return { display = display }
