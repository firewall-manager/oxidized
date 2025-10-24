# 为Puma打补丁，防止其覆盖我们的信号处理器
# 同时防止Puma注册自己的SIGHUP处理器
module Puma
  class Signal
    class << self
      alias os_trap trap
      def Signal.trap(sig, &block)
        sigshortname = sig.gsub "SIG", ''
        Oxidized::Signals.register_signal(sig, block) unless sigshortname.eql? 'HUP'
      end
    end
  end
end

module Oxidized
  # 信号处理类
  # 管理Unix信号的处理和分发
  class Signals
    @handlers = Hash.new { |h, k| h[k] = [] }
    class << self
      # 信号处理器哈希表
      attr_accessor :handlers

      # 注册信号处理器
      # @param sig [String] 信号名称
      # @param procobj [Proc] 处理器过程对象
      def register_signal(sig, procobj)
        # 计算信号的短名称（去掉SIG前缀）
        sigshortname = sig.gsub "SIG", ''
        signum = Signal.list[sigshortname]

        # 向操作系统注册处理器
        Signal.trap signum do
          Oxidized::Signals.handle_signal(signum)
        end

        # 将过程添加到请求信号的处理器列表中
        @handlers[signum].push(procobj)
      end

      # 处理信号
      # 调用所有注册的处理器
      # @param signum [Integer] 信号编号
      def handle_signal(signum)
        return unless handlers.has_key?(signum)

        @handlers[signum].each do |handler|
          handler.call
        end
      end
    end
  end
end
