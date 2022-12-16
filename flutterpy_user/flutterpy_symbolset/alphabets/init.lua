
local mylog = require('flutterpy.utils').mylog

local _M = {}

-- 希腊字母
-- 布局来源：https://www.branah.com/greek
_M.xl = {
    combined_alphabet_table = {
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
    },

    func = function (env, name, label)
        local result = ''
        local modifier = ''
        for i = 1, string.len(label) do
            local ch = string.sub(label, i, i)
            if modifier == '' and _M.xl.combined_alphabet_table[ch] then
                modifier = ch
            else
                local output = _M.xl.combined_alphabet_table[modifier][ch]
                if output then
                    result = result .. output
                else
                    result = result .. ch
                end
                modifier = ''
            end
        end
        return {{result, ''}}
    end,
    desc = '希腊'
}

return _M
