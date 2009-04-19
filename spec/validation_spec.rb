require File.dirname(__FILE__) + '/spec_helper.rb'
require 'gtk2'
include KeystrokeDynamics
# Time to add your specs!
# http://rspec.info/

KeystrokeDynamics::PH_FILE = File.join(File.dirname(__FILE__), 'spec_password_hashes_file')
KeystrokeDynamics::KSD_DIR = File.join(File.dirname(__FILE__), 'spec_keystroke_dynamics_dir')
`rm -rf #{PH_FILE} #{KSD_DIR}`

describe "Validation.load_pass_hashes" do
  it "should load the password hashes file into memory" do
    Validation.load_pass_hashes.is_a?(Hash).should == true
  end
end

describe "Validation.enroll" do
  it "should enroll a new user" do
    Validation.enroll('test','test', [[{:character => 'a', :seek_time => 0, :hold_time => 0}]]).should == true
    Validation.load_pass_hashes[:test].nil?.should == false
  end

  it "should not enroll a new user when the password is blank" do
    Validation.enroll('test','', [[{:character => 'a', :seek_time => 0, :hold_time => 0}]]).should == false
  end

  it "should not enroll a new user when the password is blank" do
    Validation.enroll('','test', [[{:character => 'a', :seek_time => 0, :hold_time => 0}]]).should == false
  end
end

describe "Validation.validate" do
  before :each do
    @kaa = [[{:character => 'a', :seek_time => 0, :hold_time => 0}]]
    Validation.enroll('test','test', @kaa)
  end
  it "should login the user with valid credentials" do
    Validation.validate('test','test', @kaa).should == true
  end

  it "should not login unknown users" do
    Validation.validate('foobar','foobar', @kaa).should == false
  end

  it "should not login the user with invalid credentials" do
    Validation.validate('test','foobar', @kaa).should == false
  end

  it "should not login the user with valid credentials but bad keystroke data" do
    Validation.validate('test','test', [[{:character => 'a', :seek_time => 0, :hold_time => MAX_ALLOWED_DEVIATION/2}]]).should == false
  end

end

describe "Validation.validate" do
  it "should not login the user when the reference metric is missing" do
    `rm -rf #{KSD_DIR}`
    Validation.validate('test','test', [[{:character => 'a', :seek_time => 0, :hold_time => MAX_ALLOWED_DEVIATION/2}]]).should == false
  end

end
