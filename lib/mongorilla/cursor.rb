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

    def to_a
      @cursor.map{|c| @klass.new(c)}
    end


    def to_yaml
      to_a().map(&:to_hash).to_yaml
    end

    def to_json
      to_a().map(&:to_hash).to_json
    end

    def each
      @cursor.each do|v|
        yield @klass.new(v)
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
