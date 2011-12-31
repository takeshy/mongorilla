require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'logger'

class User 
  UserFields = [:_id,:name,:password,:logs,:log_count]
  include Mongorilla::Document
end

describe User do
  before do
    Mongorilla::Collection.build(File.expand_path("../config.yml",__FILE__),Logger.new(STDOUT))
  end
  context "create" do
    before do
      @users = User.create([
                          {:name => "user1",:password => "pass1"},
                          {:name => "user2",:password => "pass2"},
                          {:name => "user3",:password => "pass3"},
                          {:name => "user4",:password => "pass4"},
                          {:name => "user5",:password => "pass5"},
      ])
    end
    it{@users.count.should == 5}
    it{@users[0].name.should == "user1"}
    it{@users[-1].name.should == "user5"}
    it{@users[-2].name.should == "user4"}
    it{@users.map{|u| u.name}.should == ["user1","user2","user3","user4","user5"]}
  end
  after do
    User.remove()
  end
end
