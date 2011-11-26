require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

Standalone = <<EOF
host: 127.0.0.1
port: 27017
database: dev_test
EOF

Slave = <<EOF
host: 127.0.0.1
port: 27017
database: dev_test
slaves:
  - host: localhost
    port: 27018
EOF
ReplicaSet = <<EOF
hosts: 
  - - 127.0.0.1
    - 27017
  - - localhost
    - 27018
  - - localhost
    - 27019
read_secondary: true
database: dev_test
EOF

describe Mongorilla::Collection do
  context "standalone" do
    before do
      File.stub!(:read).and_return(Standalone)
      Mongorilla::Collection.build
    end
    it{ Mongorilla::Collection.master.name.should == "dev_test"}
  end
  context "slaves" do
    before do
      File.stub!(:read).and_return(Slave)
      Mongorilla::Collection.build
    end
    it{Mongorilla::Collection.slaves[0].connection.host.should =="localhost"}
  end

#  context "replica_set" do
#    before do
#      File.stub!(:read).and_return(ReplicaSet)
#      Mongorilla::Collection.build
#    end
#    it{Mongorilla::Collection.master.should_not be_nil}
#  end
  context "insert" do
    before do
      Mongorilla::Collection.stub!(:load_config).and_return(YAML.load(Slave))
      Mongorilla::Collection.build
      @col = Mongorilla::Collection.new(:users)
      @rand = rand
      u_id = @col.insert("name" => "morita","password"=>"#{@rand}")
      @data = @col.find_one(u_id,:master=>true)
      #slaveに反映される時間
      sleep(0.4)
      @s_data = @col.find_one(u_id)
    end
    it{@data["password"].should ==  "#{@rand}"}
    it{@data["name"].should ==  "morita"}
    it{@s_data["password"].should ==  "#{@rand}"}
    it{@s_data["name"].should ==  "morita"}
  end
  after(:all) do
    Mongorilla::Collection.stub!(:load_config).and_return(YAML.load(Slave))
    Mongorilla::Collection.build
    col = Collection.new(:users)
    col.remove()
  end
end
