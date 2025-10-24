# 向后兼容性垫片，用于已弃用的模型 `supermicro`
# 请将您的源从 `supermicro` 迁移到 `edgecos`

require_relative 'edgecos'

# 将 Supermicro 类设置为 EdgeCOS 的别名
Supermicro = EdgeCOS

# 记录警告信息
logger.warn "Using deprecated model supermicro, use edgecos instead."

# 已弃用
