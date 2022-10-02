
-- 加载flutterpy的对象和函数
for k, v in pairs(require('flutterpy')) do
    _G['flutterpy_' .. k] = v
end
