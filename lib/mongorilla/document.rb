require File.expand_path("../collection.rb",__FILE__)
module Mongorilla
  module Document
    RELOAD = :reload
    SYNC = :sync
    ASYNC = :async
    def self.pluralize(name)
      underscore_name = name.gsub(/^[A-Z]/){|m| "_" + m.downcase}[1 .. -1]
      case underscore_name
      when /(s|ss|sh|ch|o|x)$/
        underscore_name + "es"
      when /[^aeiou]y$/
        underscore_name[0 .. -2] + "ies"
      when /(f|fe)$/
        underscore_name.gsub(/(f|fe)$/){|m| "ves"}
      when /child$/
        underscore_name + "en"
      when /foot$/
        underscore_name.gsub(/foot$/){|m| "feet"}
      when /tooth$/
        underscore_name.gsub(/tooth$/){|m| "teeth"}
      when /man$/
        underscore_name.gsub(/man$/){|m| "men"}
      when /woman$/
        underscore_name.gsub(/woman$/){|m| "women"}
      else
        underscore_name + "s"
      end
    end

    def self.included(c)
      fields = c.const_get("#{c}Fields")
      fields.each do |f|
        define_method(f) {@doc[f.to_s] }
        define_method(f.to_s + "="){|v| set(f.to_s,v);}
      end
      alias_method :id,:_id
      col_name = pluralize(c.to_s)
      @@col = Collection.new(col_name)

      def initialize(doc)
        @orig = doc.dup
        @doc = doc
        @changes={}
      end

      def changes
        @changes
      end

      def set(f,v)
        send(f)
        @doc[f] = v
        @changes["$set"] ||= {}
        @changes["$set"][f] = v
      end

      def inc(f,v)
        @doc[f] = 0 unless send(f)
        @doc[f] += v
        @changes["$inc"] ||= {}
        @changes["$inc"][f] = v
      end

      def push(f,v)
        @doc[f] = [] unless send(f)
        @doc[f].push(v)
        @changes["$push"] ||= {}
        @changes["$push"][f] = v
      end

      def unset(f)
        @doc.delete(f)
        @changes["$unset"] ||= {}
        @changes["$unset"][f] = 1
      end

      def push_all(f,v)
        if send(f)
          @doc[f] += v
        else
          @doc[f] = v
        end
        @changes["$pushAll"] ||= {}
        @changes["$pushAll"][f] = v
      end

      def add_to_set(f,v)
        if v.is_a? Hash
          values = v["$each"]
        else
          values = [v]
        end
        values.each do|val|
          if send(f)
            @doc[f].push(val) unless @doc[f].find{|r| r == val}
          else
            @doc[f] = [val]
          end
        end
        @changes["$addToSet"] ||= {}
        @changes["$addToSet"][f] = v
      end

      def pop(f,v)
        @changes["$pop"] ||= {}
        @changes["$pop"][f] = v
        if v > 0
          send(f).pop
        else
          send(f).shift
        end
      end

      def pull(f,v)
        @changes["$pull"] ||= {}
        @changes["$pull"][f] = v
      end

      def pull_all(f,v)
        @changes["$pull_all"] ||= {}
        @changes["$pull_all"][f] = v
      end

      def save(*args)
        cond = {}
        opt = {}
        mode = SYNC
        args.each do|arg|
          if arg.is_a?(Symbol)
            mode = arg
          elsif cond == {} 
            cond = arg
          else
            opt = arg
          end
        end
        opt[:safe] = true if [SYNC,RELOAD].include?(mode)
        cond.merge!({"_id" => @doc["_id"]})
        if @changes
          ret = @@col.update(cond,@changes,opt)
          if opt[:safe] && ret["n"] != 1
            reset
            return false
          end
        end
        if mode == RELOAD
          reload
        end
        @orig = @doc.dup
        @changes={}
        true
      end

      def reset
        @changes={}
        @doc = @orig.dup
      end

      def delete
        self.class.remove(:_id => id)
      end

      def reload
        @changes={}
        @doc = @@col.find_one(id,:master => true)
        @orig = @doc.dup
      end

      def c.collection
        @@col
      end

      def c.create(data,opt={})
        if opt == {}
          opt[:safe] = true
        end
        ret = @@col.insert(data,opt)
        if opt[:safe] == true
          if ret.is_a? Array
            ret.map{|uid| find(uid,:master=>true)}
          elsif ret
            find(ret,:master=>true)
          end
        end
      end

      def c.find_one(cond,opt={})
        ret = @@col.find_one(cond,opt)
        if ret
          return self.new(ret)
        else
          return nil
        end
      end

      def c.count(cond={},opt={})
        @@col.count(cond,opt)
      end

      def c.find(cond={},opt={})
        if !cond.is_a? Hash
          find_one(cond,opt)
        else
          ret = @@col.find(cond,opt)
          return [] if ret.count == 0
          ret.map{|r| self.new(r)}
        end
      end

      def c.update(cond,data,opt={})
        @@col.update(cond,data,opt)
      end

      def c.remove(cond={},opt={})
        @@col.remove(cond,opt)
      end
    end
  end
end
