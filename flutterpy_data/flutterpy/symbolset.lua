
local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local ensure_flutterpy_user_in_path = require('flutterpy.utils').ensure_flutterpy_user_in_path
local ensure_env_flutterpy = require('flutterpy.utils').ensure_env_flutterpy
local load_configs = require('flutterpy.utils').load_configs
local collect_from_modules = require('flutterpy.utils').collect_from_modules

local _M = {}

_M.collect_symbolsets_from_modules = collect_from_modules

_M.flutterpy_symbolset_modules_cache = nil
_M.flutterpy_symbolset_cache = nil

_M.symbolset_translator = {
    init = function (env)
        ensure_env_flutterpy(env)
        ensure_flutterpy_user_in_path()
        load_configs(env.name_space, {
            {type = 'string', config_name = 'symbolset_pattern', default = ''},
        }, env.engine.schema.config, env.flutterpy)
        if not _M.flutterpy_symbolset_modules_cache then
            local modules = require('flutterpy_symbolset')
            _M.flutterpy_symbolset_modules_cache = modules
        end
        env.flutterpy.flutterpy_symbolset_modules = _M.flutterpy_symbolset_modules_cache
        if not _M.flutterpy_symbolset_cache then
            _M.flutterpy_symbolset_cache = _M.collect_symbolsets_from_modules(_M.flutterpy_symbolset_modules_cache)
        end
        env.flutterpy.flutterpy_symbolset = _M.flutterpy_symbolset_cache
    end,
    func = function (input, seg, env)
        if not seg:has_tag('flutterpy_symbolset') then return end
        local set_name, separator, label, terminator = string.match(input, env.flutterpy.symbolset_pattern)
        local symbolset_def = env.flutterpy.flutterpy_symbolset[set_name]
        if symbolset_def then
            local func = symbolset_def.func
            local desc = symbolset_def.desc
            if separator == '' then
                yield(Candidate('flutterpy_symbolset_desc', seg.start, seg._end, '', desc))
            else
                local succeed, cand_tuples = pcall(func, env, set_name, label)
                if succeed then
                    for i, t in ipairs(cand_tuples) do
                        yield(Candidate('flutterpy_symbolset', seg.start, seg._end, t[1], t[2]))
                    end
                else
                    yield(Candidate('flutterpy_symbolset_error', seg.start, seg._end, '', 'Error: ' .. cand_tuples))
                end
            end
        end
    end,
    fini = function (env) end
}


return _M
