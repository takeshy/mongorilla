require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'logger'

class User 
  UserFields = [:_id,:name,:password,:logs,:log_count]
  include Mongorilla::Document
end

class Item
  ItemFields = [:_id,:name,:price]
  include Mongorilla::Document
end

describe User do
  before do
    Mongorilla::Collection.build(File.expand_path("../config.yml",__FILE__),Logger.new(STDOUT))
  end
  context "create" do
    before do
      @user = User.create(:name => "morita",:password => "pass")
    end
    it{@user.name.should == "morita"}
    it{@user.password.should == "pass"}
  end
  context "find" do
    before do
      @user = User.create(:name => "morita",:password => "pass")
    end
    it{User.find(@user.id,:master=>true).id.should == @user.id}
    it{User.find({:name => "morita"},:master=>true)[0].name.should == "morita"}
  end
  context "save" do
    context "sync" do
      before do
        @user = User.create(:name => "morita",:password => "pass")
        @item = Item.create(:name => "card",:price => 10)
        @user.name = "mora"
        @user.password = "hey"
        @user.push("logs","oooo")
        @user.push("logs","aaa")
        @user.inc("log_count",2)
        @user.save(Mongorilla::Document::SYNC)
      end
      it{User.count({:name => "mora",:password => "hey"},:master=>true).should == 1}
      it{@user.name.should == "mora"}
      it{@user.password.should == "hey"}
      it{@user.logs[1].should == "aaa"}
      it{@user.log_count.should == 2}
    end
    context "reload" do
      before do
        @user = User.create(:name => "morita",:password => "pass")
        @user.name = "mori"
        @user.password = "hello"
        @user.push("logs","ooooo")
        @user.inc("log_count",1)
        @user.save(Mongorilla::Document::RELOAD)
      end
      it{@user.logs[0].should == "ooooo"}
      it{@user.log_count.should == 1}
    end
    context "condition success" do
      before do
        @user = User.create(:name => "morita",:password => "pass")
        @user.name = "mor"
        @user.password = "he"
        @user.push("logs","cc")
        @user.inc("log_count",1)
        @user.save({:log_count => nil},Mongorilla::Document::RELOAD)
      end
      it{@user.logs[0].should == "cc"}
      it{@user.log_count.should == 1}
    end
    context "condition fail" do
      before do
        @user = User.create(:name => "morita",:password => "pass")
        @user.name = "mo"
        @user.password = "hh"
        @user.push("logs","dd")
        @user.inc("log_count",1)
        @ret = @user.save({:log_count => {"$ne" => nil}},Mongorilla::Document::RELOAD)
      end
      it{@ret.should == false}
      it{@user.name.should == "morita"}
      it{@user.logs.should == nil}
    end
  end
  after do
    User.remove()
  end
end
