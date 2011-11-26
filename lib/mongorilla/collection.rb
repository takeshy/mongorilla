require 'yaml'
require 'mongo'
module Mongorilla
  class Collection
    @@master = nil
    @@slaves = nil
    @@slave_index = 0
    @@config = nil

    def self.master
      @@master
    end

    def self.slaves
      @@slaves
    end

    def self.config
      @@config
    end

    def self.load_config(path)
      @@config = YAML.load(File.read(path))
    end

    def self.build(path=File.expand_path("../config.yml",__FILE__))
      load_config(path)
      @@config["max_retries"] ||= 10
      @@config["meantime"] ||= 0.5
      if @@config["hosts"]
        @@master = Mongo::ReplSetConnection.new(*@@config["hosts"]).db(@@config["database"])
      elsif @@config["slaves"]
        @@master = Mongo::Connection.new(@@config["host"],@@config["port"]).db(@@config["database"])
        @@slaves = @@config["slaves"].map{|s| Mongo::Connection.new(s["host"],s["port"]).db(@@config["database"])}
      else
        host = @@config["host"] ? @@config["host"] : "localhost"
        port = @@config["port"] ? @@config["port"].to_i : 27017
        @@master = Mongo::Connection.new(host,port).db(@@config["database"])
      end
    end

    def r_col
      if @@slaves
        @@slave_index += 1
        @@slaves[@@slave_index % @@slaves.length][@name]
      else
        @@master[@name]
      end
    end

    def w_col
      @@master[@name]
    end

    def initialize(collection_name)
      @name = collection_name
    end

    def find_one(cond={},opt={})
      opt[:limit] = 1
      if cond.is_a?(String) || cond.is_a?(BSON::ObjectId)
        cond = BSON::ObjectId(cond) if cond.is_a?(String)
        cond = {:_id => cond}
      end
      ret = find(cond,opt)
      ret.first
    end

    def count(cond={},opt={})
      find(cond,opt).count
    end

    def find(cond={},opt={})
      if opt[:master] || opt["master"]
        opt.delete(:master)
        opt.delete("master")
        if @@config["hosts"]
          opt[:read] = :primary
        end
        rescue_connection_failure do
          w_col.find(cond,opt)
        end
      else
        if @@config["hosts"] && @@config["read_secondary"]
          opt[:read] = :secondary
        end
        begin
          rescue_connection_failure do
            r_col.find(cond,opt)
          end
        rescue
          w_col.find(cond,opt)
        end
      end
    end

    def insert(data,opt={})
      rescue_connection_failure do
        w_col.insert(data,opt)
      end
    end

    def update(cond,data,opt)
      rescue_connection_failure do
        w_col.update(cond,data,opt)
      end
    end

    def remove(cond={},opt={})
      if cond.is_a? String
        cond = {:_id => BSON::ObjectId(cond)}
      elsif cond.is_a? BSON::ObjectId
        cond = {:_id => cond}
      end
      rescue_connection_failure do
        w_col.remove(cond,opt)
      end
    end

    def rescue_connection_failure(max_retries=@@config["max_retries"])
      retries = 0
      begin
        yield
      rescue Mongo::ConnectionFailure => ex
        retries += 1
        raise ex if retries > max_retries
        sleep(@@config["meantime"])
        retry
      end
    end
  end
end
