module Mongorilla
  class Cursor
    include Enumerable

    def [](idx)
      if idx < 0
        idx = @cursor.count + idx
      end
      return @members[idx] if @members[idx] 
      ret = @cursor.skip(idx).limit(1).first
      @members[idx] = ret ? @klass.new(ret) : nil
    end

    def each
      @cursor.each do|v|
        yield @klass.new(v)
      end
    end

    def count
      @cursor.count
    end

    def initialize(klass,cursor)
      @members = {}
      @klass = klass
      @cursor = cursor
    end
  end
end
