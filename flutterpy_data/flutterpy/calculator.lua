local luaxp = require('flutterpy.luaxp')
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local state = require('flutterpy.state')

local _M = {}

state.calculator_context = {__lvars = {}}
state.calculator_context_updated = state.calculator_context

_M.calculator_translator = {
    init = function(env)
        ensure_env_flutterpy(env)
        env.flutterpy.calculator_select_notifier = env.engine.context.select_notifier:connect(function(ctx)
            -- 选定时才更新context
            state.calculator_context = state.calculator_context_updated
        end)
    end,
    func = function(input, seg, env)
        if not seg:has_tag('flutterpy_calculation') then return end
    
        -- 空格輸入可能
        local expression = (string.sub(input, -1, -1) == "=") and string.sub(input, 2, -2) or string.sub(input, 2, -1)
        expression = expression:gsub("`", " ")
        
        -- 复制一份context，在上面修改变量，保留原context
        local context_updated = {}
        for k, v in pairs(state.calculator_context) do
            context_updated[k] = v
        end
        context_updated.__lvars = {}
        for k, v in pairs(state.calculator_context.__lvars) do
            context_updated.__lvars[k] = v
        end
        
        local result, err = luaxp.evaluate(expression, context_updated)
        
        if err ~= nil then
            yield(Candidate('flutterpy_calculation_result', seg.start, seg._end, expression, '|Error: '..luaxp.dump(err)))
        else
            context_updated.__lvars._ = result
            state.calculator_context_updated = context_updated
            yield(Candidate('flutterpy_calculation_result', seg.start, seg._end, luaxp.dump(result), ''))
            yield(Candidate('flutterpy_calculation_result', seg.start, seg._end, expression .. ' = ' ..luaxp.dump(result), ''))
        end
    end,
    fini = function(env)
        env.flutterpy.calculator_select_notifier:disconnect()
    end
}

return _M
