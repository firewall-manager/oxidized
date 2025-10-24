# ZPE Nodegrid 设备模型
# 支持 ZPE Nodegrid 网络设备的配置备份
# 测试设备：Nodegrid Gate/Bold/NSR
# https://www.zpesystems.com/products/
class Nodegrid < Oxidized::Model
  using Refinements

  # ZPE Nodegrid (Tested with Nodegrid Gate/Bold/NSR)
  # https://www.zpesystems.com/products/

  # 提示符正则表达式：匹配 Nodegrid 设备提示符
  prompt /(?<!@)\[(.*?\s\/)\]#/
  # 注释字符：Nodegrid 使用井号作为注释
  comment '# '

  # 处理系统信息，显示系统、型号、软件版本
  cmd 'show system/about/' do |cfg|
    comment cfg # Show System, Model, Software Version
  end

  # 处理许可证信息
  cmd 'show settings/license/' do |cfg|
    comment cfg # Show License information
  end

  # 处理配置导出，包含明文密码以便导入
  cmd 'export_settings settings/ --plain-password' do |cfg|
    cfg # Print all system config including keys to be importable via import_settings function
  end

  # SSH 连接配置
  cfg :ssh do
    pre_logout 'exit'
  end
end
