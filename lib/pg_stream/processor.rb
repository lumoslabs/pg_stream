module PgStream
  class Processor
    CALLBACK_TYPES = [:before_execute, :during_execute, :after_execute]

    def initialize(stream)
      @stream = stream
      @callbacks = CALLBACK_TYPES.map do |type|
        [type, []]
      end.to_h
      @row_count = 0
    end

    def register(args)
      args.each do |type, function|
        if CALLBACK_TYPES.include?(type)
          @callbacks[type] << function
        else
          raise "#{type} is not an acceptable callback type. Types include #{CALLBACK_TYPES.join(', ')}"
        end
      end
      @callbacks
    end

    def execute
      @callbacks[:before_execute].each(&:call)
      @stream.each_row do |row|
        @row_count += 1
        @callbacks[:during_execute].each { |y| y.call(row, @row_count) }
      end
      @callbacks[:after_execute].each { |y| y.call(@row_count) }
      @row_count
    end
  end
end
