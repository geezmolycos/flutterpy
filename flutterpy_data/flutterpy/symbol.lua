
local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local load_configs = require('flutterpy.utils').load_configs

local _M = {}

function _M.symbol_hint(symbol_group_table, keys, key_padding, char_padding)
    local text = ''
    for i = 1, #keys do
        local c = string.sub(keys, i, i)
        if c == '\n' or c == '\r' then
            text = text .. '\r'
        elseif c == ' ' then
            text = text .. ' '
        else
            local symbol_defn = symbol_group_table[c]
            local keycap
            if not symbol_defn then
                keycap = c .. string.rep(' ', key_padding)
            else
                keycap = symbol_defn.cap .. string.rep(' ', char_padding)
            end
            text = text .. keycap
        end
    end
    return text
end

function _M.lower_symbol_hint(symbol_group_table)
    return _M.symbol_hint(symbol_group_table, '1234567890\nqwertyuiop\n asdfghjkl\n  zxcvbnm', 2, 1)
end

function _M.upper_symbol_hint(symbol_group_table)
    return _M.symbol_hint(symbol_group_table, '!@#$%^&*()\nQWERTYUIOP\n ASDFGHJKL\n  ZXCVBNM', 2, 1)
end

function _M.layouted_symbol_hint(symbol_group_table, layout, upper, key_width, space_width)
    local keys_str = ({
        {'qwertyuiop\n asdfghjkl\n  zxcvbnm', 'QWERTYUIOP\n ASDFGHJKL\n  ZXCVBNM'},
        {'1234567890\nqwertyuiop\n asdfghjkl\n  zxcvbnm', '!@#$%^&*()\nQWERTYUIOP\n ASDFGHJKL\n  ZXCVBNM'},
        {"qwertyuiop[]\\\n asdfghjkl;'\n  zxcvbnm,./", 'QWERTYUIOP{}|\n ASDFGHJKL:"\n  ZXCVBNM<>?'},
        {"`1234567890-=\nqwertyuiop[]\\\n asdfghjkl;'\n  zxcvbnm,./", '~!@#$%^&*()_+\nQWERTYUIOP{}|\n ASDFGHJKL:"\n  ZXCVBNM<>?'},
    })[layout][upper and 2 or 1]
    return _M.symbol_hint(symbol_group_table, keys_str, key_width + space_width - 1, space_width)
end

function _M.translate_string(s, symbol_group_table)
    return string.gsub(s, '.', function (match)
        local symbol_defn = symbol_group_table[match]
        return symbol_defn and symbol_defn.s or match
    end)
end

local symbol_table_cache = {} -- 使新会话的加载速度快一点

_M.symbol_translator = {
    init = function (env)
        ensure_env_flutterpy(env)
        if symbol_table_cache[env.name_space] then
            env.flutterpy.symbol_table = symbol_table_cache[env.name_space]
        else
            load_configs(env.name_space, {
                {type = 'item', config_name = 'symbol_table', default = {}, to_lua = true},
            }, env.engine.schema.config, env.flutterpy)
            symbol_table_cache[env.name_space] = env.flutterpy.symbol_table
        end
        load_configs(env.name_space, {
            {type = 'string', config_name = 'single_pattern', default = ''},
            {type = 'string', config_name = 'multiple_pattern', default = ''},
        }, env.engine.schema.config, env.flutterpy)
    end,
    func = function (input, seg, env)
        if seg:has_tag('flutterpy_symbol_single') then
            local shape, label = string.match(input, env.flutterpy.single_pattern)
            local symbol_group_table = env.flutterpy.symbol_table[shape]
            if symbol_group_table then
                local use_upper = symbol_group_table._use_upper
                local multi_hint = symbol_group_table._multi_hint
                if label == '' then -- 没有输入label，显示提示
                    local lower_hint = _M.lower_symbol_hint(symbol_group_table)
                    yield(Candidate('flutterpy_symbol_hint', seg.start, seg._end, '', lower_hint))
                    if use_upper then
                        local upper_hint = _M.upper_symbol_hint(symbol_group_table)
                        yield(Candidate('flutterpy_symbol_hint', seg.start, seg._end, '', upper_hint))
                    end
                else
                    if not use_upper then label = string.lower(label) end
                    local symbol_defn = symbol_group_table[label]
                    if symbol_defn then
                        yield(Candidate('flutterpy_symbol', seg.start, seg._end, symbol_defn.s, ''))
                    else
                        yield(Candidate('flutterpy_symbol', seg.start, seg._end, '', ''))
                    end
                end
            end
        elseif seg:has_tag('flutterpy_symbol_multiple') then
            local shape, label, terminator = string.match(input, env.flutterpy.multiple_pattern)
            local symbol_group_table = env.flutterpy.symbol_table[shape]
            if symbol_group_table then
                if label == '' then -- 没有输入label，显示提示
                else
                    if not use_upper then label = string.lower(label) end
                    yield(Candidate('flutterpy_symbol', seg.start, seg._end, _M.translate_string(label, symbol_group_table), ''))
                end
                if multi_hint then
                    local lower_hint = _M.lower_symbol_hint(symbol_group_table)
                    yield(Candidate('flutterpy_symbol_hint', seg.start, seg._end, '', lower_hint))
                    if use_upper then
                        local upper_hint = _M.upper_symbol_hint(symbol_group_table)
                        yield(Candidate('flutterpy_symbol_hint', seg.start, seg._end, '', upper_hint))
                    end
                end
            end
        end
    end,
    fini = function (env) end
}

return _M
