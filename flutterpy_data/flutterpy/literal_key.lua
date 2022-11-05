
local mylog = require('flutterpy.utils').mylog
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local load_configs = require('flutterpy.utils').load_configs

local _M = {}

_M.literal_key_processor = {
    init = function(env)
        ensure_env_flutterpy(env)
        load_configs(env.name_space, {
            {type = 'string', config_name = 'zh_literal_option_name', default = 'enable_zh_literal'},
        }, env.engine.schema.config, env.flutterpy)
        env.flutterpy.is_apostrophe_down = false
        -- env.flutterpy.quotation_mark_close = false
        env.flutterpy.original_ascii_mode = false
    end,
    func = function(key_event, env)
        if not env.engine.context:is_composing() and key_event.keycode == 39 and not key_event:release() then
            local prev_down = env.flutterpy.is_apostrophe_down
            env.flutterpy.is_apostrophe_down = true
            env.flutterpy.original_ascii_mode = env.engine.context:get_option('ascii_mode')
            if env.engine.context:get_option(env.flutterpy.zh_literal_option_name) then
                if not prev_down and env.flutterpy.original_ascii_mode then
                    return 1
                else
                    return 2
                end
            else
                return 2
            end
        elseif (key_event.keycode == 39 or key_event.keycode == 34) and key_event:release() then -- 如果按下单引号后，继续按下shift，那么keycode就会变双引号
            env.flutterpy.is_apostrophe_down = false
            if env.flutterpy.original_ascii_mode and env.engine.context:get_option('enable_zh_literal') then
                if env.engine.context:get_option('ascii_mode') then -- 按了分号但是没有输入字母
                    env.engine:commit_text("'")
                else -- 快捷中文输入结束
                    env.engine.context:commit()
                    env.engine.context:set_option('ascii_mode', env.flutterpy.original_ascii_mode)
                end
            end
            return 2
        else
            if env.flutterpy.is_apostrophe_down then -- 快捷英文/中文输入
                if not env.flutterpy.original_ascii_mode then
                    env.engine.context:clear()
                    return 0
                elseif env.engine.context:get_option('ascii_mode') and env.engine.context:get_option('enable_zh_literal') then
                    env.engine.context:set_option('ascii_mode', false)
                    return 2
                end
            end
            -- if not key_event:release()
            --   and (key_event.keycode == 39 or key_event.keycode == 34)
            --   and string.sub(env.engine.context.input, 1, 1) == "'" then -- 临时英文输入模式，按单引号上屏
            --     if string.len(env.engine.context.input) == 1 then
            --         env.engine.context:select(quotation_mark_close and 2 or 1) -- 输入单引号时依次成对输入
            --         quotation_mark_close = not quotation_mark_close
            --     end
            --     env.engine.context:commit()
            --     return 1
            -- end
            return 2
        end
    end,
    fini = function(env) end
}

return _M
