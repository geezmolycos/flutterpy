# 小蝶音形

小蝶音形(flutterpy)是小鹤音形rime输入方案的魔改版，与小鹤音形的主要区别是使用lua加入了个人喜欢的功能。该方案依赖于小鹤音形方案，但是本身独立，可以与小鹤音形共存，便于更新小鹤版本。该方案兼容小鹤用户词库，但也带有自己独立的用户词库和用户脚本，方便在小鹤现有的基础上迁移。

## 特性介绍

- 移除词语
  - 提供可选开关移除小鹤的四字以上短语，默认开启（本方案用户词库中的词保持原样）。移除的原因是我经常不小心打出成语或短语，删除时麻烦，真正想打成语的时候很少。
  - 移除小鹤的o开头的符号、部首等编码（不影响o开头的正常字词）。原因是有更好的模式用来输入符号或部首，但是也可以在配置文件手动关闭。
  - 移除小鹤自带的emoji表情（同上）
- 快捷输入
  - 快捷英文输入，按住（像Shift一样）单引号并同时按下你想输入的一个字符，可以直接输入该字符，放开后可继续正常输入其他内容
  - 快捷中文输入，输入法处于英文模式时，按住单引号输入会临时进入中文模式(可切换，默认关闭)
  - 临时英文输入，单引号开始，输入结束后按空格或单引号确认
- 符号输入
  
  分号开始，直观输入符号，多层次，用户可以自己加想要的，有预览，快速索引符号。
  
  符号输入方式分为形符、名符和类符三种

  - 形符，包括类和标签，类由不包括分号的ASCII标点符号组成，标签是单个字母或数字。输完类符以后，候选窗中会显示标签对应符号的预览。输完标签后，符号自动上屏。
    - 例如`;-n`可以输入`–`(`en dash`)，而`;-m`可以输入`—`(`em dash`)
    - 预览就是，在输入了`;-`以后，候选窗会弹出一个键盘的图案，上面显示按哪个键输入什么字符。
    - 还有一个形符软键盘的功能，在输入完了类以后，再输入一个分号，现在按标签不会自动上屏，而是会将输入的所有字母和数字按照当前类的映射关系映射成符号。可以用这个功能快速输入一个类中多个字符，例如输入八个em dash作为分割线，可以输入`;-;mmmmmmmm`，再按空格选择候选。
  - 名符，是特殊的类符，就是类名为空字符串的类符（详见下文）。这种方式可以给常用的符号指定名字，按名字输入。输入的模式是两个分号，再加字母或数字组成的标签，比如说可以把星形叫`;;xkxk`，输入完成之后需要按空格选择候选。
  - 类符，包括类和标签，类不能以标点符号开头，类和标签中间用分号分隔。标签不限长度，不限字符。比如可以设置按盲文点的有无输入盲文，`;mhwf;125`输入符号`⠓`(如果看不到盲文符号，可能是你的字体不支持)。
    - 类符会交给用户定义的脚本处理，用户在`flutterpy_user/flutterpy_symbolset`中可以放lua脚本。
  - 名符和类符输入完成时也可以按分号自动选中。
- 变换器
  
  变换器是该输入方案最强大的功能，提供了接口，让用户可以用lua脚本变换输入的内容，变换器还可以嵌套。

  - `\name\`代表某个变换器开始，`\\`代表最近的变换器结束。
  - 变换器的嵌套，候选会先被内部的变换器处理，再被外部处理；上屏时同理。
- 计算器
  - 输入等号以后再输入数学表达式，会给表达式求值，使用[`luaxp`](https://github.com/toggledbits/luaxp)库求值，同`librime-lua`库示例中的计算器相比，这个计算器虽然功能差点（一般用这个计算就是一些简单的计算），但是可以避免执行任意lua脚本，消除潜在的安全风险。
 
## 配置文件说明

方案采用便携化设计，方便用户按照自己的需求进一步修改，同时lua脚本分成模块，可以根据自己的需求使用或不使用特定功能。lua脚本设置了很多用户配置项，会从输入方案文件里(`flutterpy.schema.yaml`)的对应命名空间读取设置。

(TODO)

## 安装

(TODO)
