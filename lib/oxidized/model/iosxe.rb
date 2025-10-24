# Cisco IOS XE 设备模型
# IOS 解析器应该在这里工作
# IOS XE 基于 IOS，因此可以重用 IOS 模型

require_relative 'ios'

# IOS XE 模型是 IOS 模型的别名
# 因为 IOS XE 与 IOS 使用相同的命令和配置格式
IOSXE = IOS
