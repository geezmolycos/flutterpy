import json
import sys
import string

codes_to_key = ["`~","1!","2@","3#","4$","5%","6^","7&","8*","9(","0)","-_","=+","qQ","wW","eE","rR","tT","yY","uU","iI","oO","pP","[{","]}","\\|","aA","sS","dD","fF","gG","hH","jJ","kK","lL",";:","'\"","zZ","xX","cC","vV","bB","nN","mM",",<",".>","/?", "\\|"]

branah_layout_obj = json.loads(sys.stdin.read(), strict=False)
key_to_char = {}
char_to_key = {}
for key_obj in branah_layout_obj['keys']:
    code = int(key_obj['i'][1:])
    plain, shifted = codes_to_key[code]
    key_to_char[plain] = key_obj['n']
    char_to_key[key_obj['n']] = plain
    key_to_char[shifted] = key_obj['s']
    char_to_key[key_obj['s']] = shifted

combination = {}
for key_obj in branah_layout_obj['deadkeys']:
    try:
        kk = char_to_key[key_obj['k']]
    except KeyError:
        kk = key_obj['k']
    combination[kk] = combination.get(kk, {})
    try:
        combination[kk][char_to_key[key_obj['b']]] = key_obj['c']
    except KeyError:
        pass

def letters_then_symbols(table):
    for lower, upper in zip(string.ascii_lowercase, string.ascii_uppercase):
        if lower in table and upper in table:
            sys.stdout.write(f"    {upper} = '{table[upper]}', {lower} = '{table[lower]}',\n")
        elif lower in table:
            sys.stdout.write(f"    {lower} = '{table[lower]}',\n")
        elif upper in table:
            sys.stdout.write(f"    {upper} = '{table[upper]}',\n")
    for k, v in table.items():
        if k in string.ascii_letters:
            continue
        if k == v:
            continue
        sys.stdout.write(f"    ['{k}'] = '{v}',\n")

combination[''] = key_to_char

for k, v in sorted(combination.items()):
    sys.stdout.write(f"['{k}'] = {{\n")
    letters_then_symbols(v)
    sys.stdout.write(f"}},\n")
