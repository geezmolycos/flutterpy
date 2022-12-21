
local mylog = require('flutterpy.utils').mylog
local logcall = require('flutterpy.utils').logcall
local layouted_symbol_hint = require('flutterpy.symbol').layouted_symbol_hint

return logcall(function()

local _M = {}

local function generate_symbolset_with_combined_table(combined_table, hint_function)
    -- generate keyboard hint

    local hint_table = {}
    for modifier, inner_table in pairs(combined_table) do
        local group_table_as_input = {}
        for key, char in pairs(inner_table) do
            group_table_as_input[key] = {cap = char}
        end
        hint_table[modifier] = hint_function(group_table_as_input)
    end

    return function(env, name, label)
        local result = ''
        local modifier = ''
        for i = 1, string.len(label) do
            local ch = string.sub(label, i, i)
            if modifier == '' and combined_table[ch] then
                modifier = ch
            else
                local output = combined_table[modifier][ch]
                if output then
                    result = result .. output
                else
                    result = result .. ch
                end
                modifier = ''
            end
        end
        return {{result, ''}, {'', hint_table[modifier][1] or ''}, {'', hint_table[modifier][2] or ''}}
    end
end

-- 希腊字母
-- 布局来源：https://www.branah.com/greek
_M.x = {

    func = generate_symbolset_with_combined_table({
        [''] = {
            A = 'Α', a = 'α',
            B = 'Β', b = 'β',
            C = 'Ψ', c = 'ψ',
            D = 'Δ', d = 'δ',
            E = 'Ε', e = 'ε',
            F = 'Φ', f = 'φ',
            G = 'Γ', g = 'γ',
            H = 'Η', h = 'η',
            I = 'Ι', i = 'ι',
            J = 'Ξ', j = 'ξ',
            K = 'Κ', k = 'κ',
            L = 'Λ', l = 'λ',
            M = 'Μ', m = 'μ',
            N = 'Ν', n = 'ν',
            O = 'Ο', o = 'ο',
            P = 'Π', p = 'π',
            Q = ':', q = ';',
            R = 'Ρ', r = 'ρ',
            S = 'Σ', s = 'σ',
            T = 'Τ', t = 'τ',
            U = 'Θ', u = 'θ',
            V = 'Ω', v = 'ω',
            W = '΅', w = 'ς',
            X = 'Χ', x = 'χ',
            Y = 'Υ', y = 'υ',
            Z = 'Ζ', z = 'ζ',
            ['\\'] = '<',
            ['|'] = '>',
            ['\''] = '΄',
            [':'] = '¨',
        },
        [':'] = {
            I = 'Ϊ', i = 'ϊ',
            Y = 'Ϋ', y = 'ϋ',
            [':'] = '¨',
        },
        ['\''] = {
            A = 'Ά', a = 'ά',
            E = 'Έ', e = 'έ',
            H = 'Ή', h = 'ή',
            I = 'Ί', i = 'ί',
            O = 'Ό', o = 'ό',
            V = 'Ώ', v = 'ώ',
            Y = 'Ύ', y = 'ύ',
            ['\''] = '΄',
        },
        ['W'] = {
            i = 'ΐ',
            W = '΅',
            y = 'ΰ',
        },
    }, function (group_table)
        return {layouted_symbol_hint(group_table, 1, false, 1, 1), layouted_symbol_hint(group_table, 1, true, 1, 1)}
    end),
    desc = '希腊'
}

-- 俄语西里尔字母
_M.e = {

    func = generate_symbolset_with_combined_table({
        [''] = {
            A = 'Ф', a = 'ф',
            B = 'И', b = 'и',
            C = 'С', c = 'с',
            D = 'В', d = 'в',
            E = 'У', e = 'у',
            F = 'А', f = 'а',
            G = 'П', g = 'п',
            H = 'Р', h = 'р',
            I = 'Ш', i = 'ш',
            J = 'О', j = 'о',
            K = 'Л', k = 'л',
            L = 'Д', l = 'д',
            M = 'Ь', m = 'ь',
            N = 'Т', n = 'т',
            O = 'Щ', o = 'щ',
            P = 'З', p = 'з',
            Q = 'Й', q = 'й',
            R = 'К', r = 'к',
            S = 'Ы', s = 'ы',
            T = 'Е', t = 'е',
            U = 'Г', u = 'г',
            V = 'М', v = 'м',
            W = 'Ц', w = 'ц',
            X = 'Ч', x = 'ч',
            Y = 'Н', y = 'н',
            Z = 'Я', z = 'я',
            ['['] = 'х',
            ['{'] = 'Х',
            [']'] = 'ъ',
            ['}'] = 'Ъ',
            ['\\'] = 'ж',
            ['|'] = 'Ж',
            ["'"] = 'э',
            ['"'] = 'Э',
            [','] = 'б',
            ['<'] = 'Б',
            ['.'] = 'ю',
            ['>'] = 'Ю',
            ['/'] = 'ё',
            ['?'] = 'Ё',
        },
    }, function (group_table)
        return {layouted_symbol_hint(group_table, 3, false, 1, 1)}
    end),
    desc = '俄西'
}

return _M

end)
