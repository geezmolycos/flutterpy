
-- Begin flutterpy loader

local user_data_dir = rime_api:get_user_data_dir()
package.path = package.path .. ';' .. user_data_dir .. '/flutterpy_data/?.lua'
package.path = package.path .. ';' .. user_data_dir .. '/flutterpy_data/?/init.lua'

-- 加载flutterpy的对象和函数
for k, v in pairs(require('flutterpy')) do
    _G['flutterpy_' .. k] = v
end

-- End flutterpy loader
