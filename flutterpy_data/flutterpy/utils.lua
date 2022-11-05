
local _M = {}

local table_printed = {}

function _M.print_table_item(k, v, level)
    for i = 1, level do
        io.write('  ')
    end
    io.write(tostring(k), ' = ', '(', type(v), ') ',  tostring(v), '\n')
    if type(v) == "table" then
        if not table_printed[v] then
            table_printed[v] = true
            for k, v in pairs(v) do
                _M.print_table_item(k, v, level + 1)
            end
        end
    end
end

function _M.mylog(...)
    local arg = {...}
    local file = io.open(rime_api:get_user_data_dir() .. '/flutterpy_user/flutterpy_log.txt', 'a')
    io.output(file)
    io.write(os.date('%Y-%m-%d %H:%M:%S',os.time()), '\n')
    for i, v in ipairs(arg) do
        table_printed = {}
        _M.print_table_item(i, v, 0)
    end
    io.write('\n')
    io.close(file)
end

function _M.logcall(f, ...)
    local status, err = pcall(f, ...)
    if not status then
        _M.mylog(err)
    end
    return err
end

function _M.ensure_env_flutterpy(env)
    if env.flutterpy == nil then
        env.flutterpy = {}
    end
end

function _M.copy_segment(segment)
    local new_segment = Segment(segment.start, segment._end)
    new_segment.status = segment.status
    new_segment.tags = segment.tags
    if segment.menu ~= nil then
        new_segment.menu = segment.menu
    end
    new_segment.selected_index = segment.selected_index
    new_segment.prompt = segment.prompt
    return new_segment
end

-- rime的lua api没有提供从composition（也是vector<Segment>）直接获取所有segment的功能
-- 进行workaround
function _M.get_segments_from_composition(composition)
    local segments = {}
    while not composition:empty() do
        -- 如果不copy_segment，在pop_back以后，Segment对象下的C++引用会失效
        table.insert(segments, _M.copy_segment(composition:back()))
        composition:pop_back()
    end
    local segments_ordered = {}
    while next(segments) ~= nil do
        local s = table.remove(segments)
        table.insert(segments_ordered, s)
        composition:push_back(s)
    end
    return segments_ordered
end

function _M.check_if_transformer_closed(segments)
    local level = 0
    for i, seg in ipairs(segments) do
        if seg:has_tag('flutterpy_trans_open') then
            level = level + 1
        end
        if seg:has_tag('flutterpy_trans_close') then
            level = level - 1
        end
        if level < 0 then level = 0 end -- being permissive of redundant closing tag
    end
    return level <= 0
end

function _M.configitem_to_lua_obj(item)
    if type(item) ~= 'userdata' then return item end
    if item.type == 'kNull' then
        return nil
    elseif item.type == 'kScalar' then
        local val = item:get_value()
        local bool = val:get_bool()
        if bool ~= nil then return bool end
        local int = val:get_int()
        if int ~= nil then return int end
        local double = val:get_double()
        if double ~= nil then return double end
        local string = val:get_string()
        return string
    elseif item.type == 'kList' then
        local list = {}
        local itemlist = item:get_list()
        for i = 0, itemlist.size - 1 do
            table.insert(list, _M.configitem_to_lua_obj(itemlist:get_at(i)))
        end
        return list
    elseif item.type == 'kMap' then
        local map = {}
        local itemmap = item:get_map()
        for i, key in ipairs(itemmap:keys()) do
            map[key] = _M.configitem_to_lua_obj(itemmap:get(key))
        end
        return map
    end
end

function _M.load_configs(namespace, config_info, config, store_table)
    for i, info in ipairs(config_info) do
        local t = config['get_' .. info.type](config, namespace .. '/' .. info.config_name)
        if t and info.to_lua then t = _M.configitem_to_lua_obj(t) end
        store_table[info.store_name or info.config_name] = t or info.default
    end
end

_M.flutterpy_user_in_path = false
function _M.ensure_flutterpy_user_in_path()
    if not _M.flutterpy_user_in_path then
        local user_data_dir = rime_api:get_user_data_dir()
        package.path = package.path .. ';' .. user_data_dir .. '/flutterpy_user/?.lua'
        package.path = package.path .. ';' .. user_data_dir .. '/flutterpy_user/?/init.lua'
    end
    _M.flutterpy_user_in_path = true
end

function _M.collect_from_modules(module_list)
    local collected = {}
    for module_name, module in pairs(module_list) do
        for key_name, content in pairs(module) do
            content.module_name = module_name
            collected[key_name] = content
        end
    end
    return collected
end

return _M
