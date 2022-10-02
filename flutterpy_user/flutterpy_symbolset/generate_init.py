import os

require_list = []
for filename in os.listdir('.'):
    if os.path.splitext(filename)[1] == '.lua':
        require_list.append(os.path.splitext(filename)[0])

generated_init = []
generated_init.append('return {')
for module in require_list:
    if module == 'init':
        continue
    generated_init.append(f"    {module} = require('flutterpy_symbolset.{module}'),")
generated_init.append('}')

with open('init.lua', 'w') as f:
    for line in generated_init:
        f.write(line)
        f.write('\n')
