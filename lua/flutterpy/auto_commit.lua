
local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local get_segments_from_composition = require('flutterpy.utils').get_segments_from_composition
local get_current_transformers = require('flutterpy.utils').get_current_transformers
local check_if_transformer_closed = require('flutterpy.utils').check_if_transformer_closed
local load_configs = require('flutterpy.utils').load_configs

local _M = {}

_M.auto_commit_processor = {
    init = function(env)
        ensure_env_flutterpy(env)
        load_configs(env.name_space, {
            {type = 'item', config_name = 'auto_select_rules', default = {}, to_lua = true},
        }, env.engine.schema.config, env.flutterpy)
        env.flutterpy.auto_commit_select_notifier = env.engine.context.select_notifier:connect(function(ctx)
            -- 段选定好了，没有目前生效的transformer，自动上屏
            local segments = get_segments_from_composition(env.engine.context.composition)
            -- mylog(get_current_transformers(env.engine.context.composition:toSegmentation().input, segments))
            -- mylog(require('flutterpy.transformer').get_lua_composition(env.engine.context.composition))
            if check_if_transformer_closed(segments) then
                env.engine.context:commit()
            end
        end)
        env.flutterpy.auto_select_update_notifier = env.engine.context.update_notifier:connect(function(ctx)
            -- 段的状态更新了，如果该段结束了，那么自动选定，结束规则匹配终止符，还有指定个数的分隔符
            if env.engine.context.composition:empty() then return end
            local segment_to_check = env.engine.context.composition:back()
            if segment_to_check:has_tag('raw') then
                env.engine.context:confirm_current_selection()
            end
            local input = env.engine.context.composition:toSegmentation().input
            local segment_input = string.sub(input, segment_to_check.start+1, segment_to_check._end+1)
            if segment_to_check.status == 'kGuess' then
                for tag, _ in pairs(segment_to_check.tags) do
                    local current_rule = env.flutterpy.auto_select_rules[tag]
                    if current_rule then
                        if string.len(segment_input) > 1
                          and string.find(string.sub(segment_input, -1, -1), current_rule.terminator)
                          and (
                            current_rule.separator_n == 0
                            or select(2, string.gsub(string.sub(segment_input, 2, -2), current_rule.separator, '')) == current_rule.separator_n
                          ) then
                            env.engine.context:confirm_current_selection()
                            break
                        end
                    end
                end
            end
        end)
    end,
    func = function(key_event, env) return 2 end,
    fini = function(env)
        env.flutterpy.auto_commit_select_notifier:disconnect()
        env.flutterpy.auto_select_update_notifier:disconnect()
    end
}

return _M
