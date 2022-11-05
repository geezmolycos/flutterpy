
local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local load_configs = require('flutterpy.utils').load_configs

local _M = {}

_M.killer_filter = {
    init = function(env)
        ensure_env_flutterpy(env)
        load_configs(env.name_space, {
            {type = 'string', config_name = 'tetrakill_option_name', default = 'enable_tetrakill'},
            {type = 'int', config_name = 'tetrakill_length', default = 4},
            {type = 'bool', config_name = 'enable_ocodekill', default = true},
            {type = 'bool', config_name = 'enable_emojikill', default = true},
            {type = 'double', config_name = 'flypy_threshold', default = -100000},
            {type = 'double', config_name = 'flypy_offset', default = 200000},
            {type = 'double', config_name = 'flypy_sys_threshold', default = -100000},
            {type = 'double', config_name = 'flypy_sys_offset', default = 200000},
            {type = 'double', config_name = 'flutterpy_override_threshold', default = 100000},
            {type = 'double', config_name = 'flutterpy_override_offset', default = -200000},
        }, env.engine.schema.config, env.flutterpy)
    end,
    func = function(input, env)
        local enable_tetrakill = env.engine.context:get_option(env.flutterpy.tetrakill_option_name)
        local cand_output = {}
        local use_override = false
        for cand in input:iter() do
            if cand.quality >= env.flutterpy.flutterpy_override_threshold then
                if not use_override then
                    cand_output = {}
                end
                use_override = true
                cand.quality = cand.quality + env.flutterpy.flutterpy_override_offset
                table.insert(cand_output, cand)
            end
            if not use_override then
                if cand.quality < env.flutterpy.flypy_threshold then
                    -- 小鹤原有编码（不包括sys词库）
                    cand.quality = cand.quality + env.flutterpy.flypy_offset
                    -- 成语杀，遇到四字以上词语，杀掉。
                    if enable_tetrakill and utf8.len(cand.text) >= env.flutterpy.tetrakill_length then
                        cand = nil
                    end
                end
                if cand ~= nil and cand.quality < env.flutterpy.flypy_sys_threshold then
                    -- 小鹤原有编码（sys词库）
                    cand.quality = cand.quality + env.flutterpy.flypy_sys_offset
                    -- O码杀
                    if env.flutterpy.enable_ocodekill and string.sub(cand.preedit, 1, 1) == 'o' then
                        -- 两个码的O码汉字不在sys词库中
                        -- 需要白名单不是符号的O码（例如欧共体	ogt）
                        if string.len(cand.preedit) <= 2 or string.find('bftxyqw', string.sub(cand.preedit, 2, 2)) ~= nil then
                            cand = nil
                        end
                    end
                    -- emoji杀
                    if cand ~= nil and env.flutterpy.enable_emojikill and (string.find(cand.text, '\xf0\x9f..') or string.find(cand.text, '\xe2[\x96-\xaf].')) then
                        cand = nil
                    end
                end
                if cand ~= nil then table.insert(cand_output, cand) end
            end
        end
        -- 按候选项权重排序
        table.sort(cand_output, function(a,b) return a.quality > b.quality end)
        for i, v in ipairs(cand_output) do
            v:get_genuine().comment = v.comment .. ' ' .. v.type .. ' ' .. tostring(v.quality) .. ' '
            yield(v)
        end
    end,
    fini = function(env) end
}

return _M
