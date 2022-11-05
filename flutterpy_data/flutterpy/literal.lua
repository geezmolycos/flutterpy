
local _M = {}

function _M.literal_translator(input, seg, env)
    if not seg:has_tag('flutterpy_literal') then return end
    if string.sub(input, -1, -1) == "'" then
        input = string.sub(input, 2, -2)
    else
        input = string.sub(input, 2, -1)
    end
    yield(Candidate('flutterpy_literal', seg.start, seg._end, input, ''))
end

return _M
