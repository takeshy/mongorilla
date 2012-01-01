module Mongorilla
  class Cursor
    include Enumerable

    def [](idx)
      if idx < 0
        idx = @cursor.count + idx
        return nil if idx < 0
      else
        return nil if idx >= @cursor.count
      end
      return @members[idx] if @members[idx]
      ret = @cursor.skip(idx).limit(1).first
      @cursor = @col.find(@cond,@opt)
      @members[idx] = ret ? @klass.new(ret) : nil
    end

    def each
      @cursor.each_with_index do|v,i|
        @members[i] = @klass.new(v) unless @members[i]
        yield @members[i]
      end
    end

    def count
      @cursor.count
    end

    def initialize(klass,cursor,col,cond,opt)
      @members = {}
      @klass = klass
      @cursor = cursor
      @col = col
      @cond = cond
      @opt = opt
    end
  end
end
