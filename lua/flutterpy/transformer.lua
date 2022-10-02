local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local ensure_flutterpy_user_in_path = require('flutterpy.utils').ensure_flutterpy_user_in_path
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local load_configs = require('flutterpy.utils').load_configs
local collect_from_modules = require('flutterpy.utils').collect_from_modules
local get_segments_from_composition = require('flutterpy.utils').get_segments_from_composition

local _M = {}

--mylog('as')
--logcall(function () mylog(require('flutterpy.transformer').get_lua_composition(env.engine.context.composition)) end)
--mylog('ad')

_M.flutterpy_transformer_modules_cache = nil
_M.flutterpy_transformer_cache = nil

_M.collect_transformers_from_modules = collect_from_modules

function _M.ensure_transformer_loaded()
    ensure_flutterpy_user_in_path()
    if not _M.flutterpy_transformer_modules_cache then
        local modules = require('flutterpy_transformer')
        _M.flutterpy_transformer_modules_cache = modules
    end
    if not _M.flutterpy_transformer_cache then
        _M.flutterpy_transformer_cache = _M.collect_transformers_from_modules(_M.flutterpy_transformer_modules_cache)
    end
end

function _M.get_rime_candidate(lua_candidate)
    local rime_candidate = Candidate(lua_candidate.type, lua_candidate.start, lua_candidate._end, lua_candidate.text, lua_candidate.comment)
    rime_candidate.quality = lua_candidate.quality
    rime_candidate.preedit = lua_candidate.preedit
    return rime_candidate
end

function _M.get_lua_candidate(candidate)
    local lua_candidate = {}
    lua_candidate.type = candidate.type
    lua_candidate.start = candidate.start
    lua_candidate._start = candidate._start
    lua_candidate._end = candidate._end
    lua_candidate.quality = candidate.quality
    lua_candidate.text = candidate.text
    lua_candidate.comment = candidate.comment
    lua_candidate.preedit = candidate.preedit
    return lua_candidate
end

function _M.get_lua_segment(segment)
    local lua_segment = {}
    lua_segment.status = segment.status
    lua_segment.start = segment.start
    lua_segment._start = segment._start
    lua_segment._end = segment._end
    lua_segment.tags = segment.tags
    lua_segment.selected_index = segment.selected_index

    local candidates = {}
    local i = 0
    while true do
        local cand = segment:get_candidate_at(i)
        if not cand then break end
        table.insert(candidates, _M.get_lua_candidate(cand))
        i = i + 1
    end
    lua_segment.candidates = candidates

    return lua_segment
end

function _M.get_lua_composition(composition)
    local lua_comp = {}
    lua_comp.input = composition:toSegmentation().input
    local segments = get_segments_from_composition(composition)
    local lua_segments = {}
    for i, seg in ipairs(segments) do
        lua_segments[i] = _M.get_lua_segment(seg)
    end
    lua_comp.segments = lua_segments
    return lua_comp
end

function _M.get_commit_text(lua_composition, start, _end)
    -- 与rime c++中处理的方式不同，若无候选项则无上屏文本（除raw外）
    if not start then start = 1 end
    if not _end then _end = #lua_composition.segments end
    local text_list = {}
    if #lua_composition.segments == 0 then
        return lua_composition.input -- 直接输入没有分段
    end
    for i = start, _end do
        local seg = lua_composition.segments[i]
        if seg.tags['raw'] then -- 上屏输入原文
            table.insert(text_list, string.sub(lua_composition.input, seg.start + 1, seg._end))
        elseif not (seg.tags['flutterpy_trans_open'] or seg.tags['flutterpy_trans_close']) then
            local cand = seg.candidates[seg.selected_index + 1] -- lua下标从1开始
            if cand then
                table.insert(text_list, cand.text)
            end
        end
    end
    return table.concat(text_list)
end

function _M.get_current_transformers(lua_composition)
    local transformers = {}
    for i, seg in ipairs(lua_composition.segments) do
        if seg.status == 'kConfirmed' then
            if seg.tags['flutterpy_trans_open'] then
                local s = string.sub(lua_composition.input, seg.start+2, seg._end)
                if string.sub(s, -1, -1) == '\\' then s = string.sub(s, 1, -2) end
                table.insert(transformers, s)
            end
            if seg.tags['flutterpy_trans_close'] then
                if next(transformers) then
                    table.remove(transformers)
                end
            end
        end
    end
    return transformers
end

function _M.get_transformed_composition(lua_composition, transformer_table, autocomplete_closing)
    if autocomplete_closing == nil then autocomplete_closing = true end
    local segment_stack = {}
    local function process_closing()
        local segments_to_transform = {}
        local transformer_opening = nil
        while #segment_stack > 0 do
            local pop_seg = table.remove(segment_stack)
            table.insert(segments_to_transform, pop_seg)
            if pop_seg.tags['flutterpy_trans_open'] then
                transformer_opening = pop_seg
                break
            end
        end
        local segments_ordered = {} -- 整理顺序
        while next(segments_to_transform) ~= nil do
            local s = table.remove(segments_to_transform)
            table.insert(segments_ordered, s)
        end
        segments_to_transform = segments_ordered
        if transformer_opening then -- 有配对的opening
            local transformer_input = string.sub(lua_composition.input, transformer_opening.start + 1, transformer_opening._end)
            local transformer_name
            if string.sub(transformer_input, -1, -1) == '\\' then
                transformer_name = string.sub(transformer_input, 2, -2)
            else
                transformer_name = string.sub(transformer_input, 2, -1)
            end
            local transformer_def = transformer_table[transformer_name]
            if transformer_def then
                local func = transformer_def.comm_func
                local transforming_start = segments_to_transform[1].start
                local transforming_end = segments_to_transform[#segments_to_transform]._end
                local transforming_quality = segments_to_transform[1].candidates[1].quality
                local transforming_comment = segments_to_transform[1].candidates[1].comment
                local transforming_tags = segments_to_transform[1].tags - Set({'flutterpy_trans_open'})
                local succeed, transformer_output = pcall(func, env, transformer_name, {input = lua_composition.input, segments = segments_to_transform})
                if not succeed then
                    transformer_output = '<!Error! ' .. transformer_output .. ' !>'
                end
                segments_to_transform = transformer_output
                if type(transformer_output) == 'string' then -- 生成transform后的默认segment
                    segments_to_transform = {{
                        candidates = {{
                            type = 'flutterpy_trans_transformed',
                            start = transforming_start,
                            _start = transforming_start,
                            _end = transforming_end,
                            text = transformer_output,
                            preedit = string.sub(lua_composition.input, transforming_start + 1, transforming_end),
                            quality = transforming_quality,
                            comment = transforming_comment,
                        }},
                        start = transforming_start,
                        _start = transforming_start,
                        _end = transforming_end,
                        selected_index = 0,
                        tags = transforming_tags + Set({'flutterpy_trans_transformed'}),
                    }}
                end
            end
        end
        -- 若有多余的结束符，不改变内容，原样放回
        for _, pop_seg in ipairs(segments_to_transform) do
            table.insert(segment_stack, pop_seg)
        end
        return transformer_opening, segments_to_transform
    end
    local last_transformer_opening = nil
    local last_segments_to_transform = nil
    for i, seg in ipairs(lua_composition.segments) do
        table.insert(segment_stack, seg)
        if seg.tags['flutterpy_trans_close'] then -- 遇到closing，则从栈中弹出，直到遇到opening
            last_transformer_opening, last_segments_to_transform = process_closing()
        end
    end
    if autocomplete_closing then
        last_transformer_opening, last_segments_to_transform = process_closing()
        while last_transformer_opening do -- 执行没有关闭的transformer
            last_transformer_opening, last_segments_to_transform = process_closing()
        end
    end
    local new_composition = {}
    for k, v in pairs(lua_composition) do
        new_composition[k] = v
    end
    new_composition.segments = segment_stack
    return new_composition, last_segments_to_transform
end

_M.transformer_translator = {
    init = function (env)
        ensure_env_flutterpy(env)
        _M.ensure_transformer_loaded()
        env.flutterpy.flutterpy_transformer_modules = _M.flutterpy_transformer_modules_cache
        env.flutterpy.flutterpy_transformer = _M.flutterpy_transformer_cache
        env.flutterpy.transformer_commit_notifier = env.engine.context.commit_notifier:connect(function(ctx)
            local original_composition = _M.get_lua_composition(env.engine.context.composition)
            local transformed_composition = _M.get_transformed_composition(original_composition, env.flutterpy.flutterpy_transformer)
            local commit_text = _M.get_commit_text(transformed_composition)
            env.engine:commit_text(commit_text)
        end)
        env.flutterpy.original_dumb_state = env.engine.context:get_option('dumb')
        env.engine.context:set_option('dumb', 1) -- suppress default commit behaviour
    end,
    func = function (input, seg, env)
        if seg:has_tag('flutterpy_trans_open') then
            if string.sub(input, -1, -1) == '\\' then
                input = string.sub(input, 2, -2)
            else
                input = string.sub(input, 2, -1)
            end
            local transformer_def = env.flutterpy.flutterpy_transformer[input]
            if transformer_def then
                yield(Candidate('flutterpy_trans_open', seg.start, seg._end, '<\\' .. transformer_def.desc .. '\\', ''))
            else
                yield(Candidate('flutterpy_trans_open', seg.start, seg._end, '<!\\' .. input .. '\\', ''))
            end
        elseif seg:has_tag('flutterpy_trans_close') then
            local preview_text = ''
            if string.len(input) == 1 then
                -- 只输入了一个反斜杠，预览上屏内容
                local original_composition = _M.get_lua_composition(env.engine.context.composition)
                local lua_seg = original_composition.segments[#original_composition.segments]
                lua_seg.tags = lua_seg.tags - Set({'flutterpy_trans_open'}) + Set({'flutterpy_trans_close'})
                local transformed_composition, last_transformed_segments = _M.get_transformed_composition(original_composition, env.flutterpy.flutterpy_transformer, false)
                preview_text = _M.get_commit_text({input = transformed_composition.input, segments = last_transformed_segments})
            end
            yield(Candidate('flutterpy_trans_close', seg.start, seg._end, '\\\\>', string.sub(preview_text, 1, 120)))
        end
    end,
    fini = function (env)
        env.flutterpy.transformer_commit_notifier:disconnect()
        env.engine.context:set_option('dumb', env.flutterpy.original_dumb_state)
    end
}

_M.transformer_filter = {
    init = function (env)
        ensure_env_flutterpy(env)
        _M.ensure_transformer_loaded()
        env.flutterpy.flutterpy_transformer_modules = _M.flutterpy_transformer_modules_cache
        env.flutterpy.flutterpy_transformer = _M.flutterpy_transformer_cache
    end,
    func = function (input, env)
        local lua_composition = _M.get_lua_composition(env.engine.context.composition)
        local current_transformers = _M.get_current_transformers(lua_composition)
        local candidates = {}
        for cand in input:iter() do
            table.insert(candidates, _M.get_lua_candidate(cand))
        end
        while next(current_transformers) do
            local current_transformer_name = table.remove(current_transformers) -- 由内到外
            local transformer_def = env.flutterpy.flutterpy_transformer[current_transformer_name]
            local succeed = true
            if transformer_def then
                local func = transformer_def.cand_func
                if func then
                    succeed, candidates = pcall(func, env, current_transformer_name, lua_composition, candidates)
                end
            end
            if not succeed then
                yield(Candidate('flutterpy_trans_error', 0, env.engine.context.caret_pos, '', 'Error: ' .. candidates))
                break
            end
        end
        for i, lua_cand in ipairs(candidates) do
            yield(_M.get_rime_candidate(lua_cand))
        end
    end,
    fini = function (env) end
}

return _M
