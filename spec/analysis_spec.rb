require File.dirname(__FILE__) + '/spec_helper.rb'
require 'gtk2'
include KeystrokeDynamics
# Time to add your specs!
# http://rspec.info/

class Gtk::Entry
  def press(key)
    self.signal_emit('key-press-event::detail', key)
  end
end

describe "Analysis#analyze_keys" do
  before :each do 
    @a = Analysis.new
  end

  it "should collect data from the GTK widget" do
    #@test_entry = Gtk::Entry.new
    #@a.analyze_keys(@test_entry)
    #@test_entry.press('a')
    violated "Need a way to mock signals in Gtk widgets"
  end
end


describe "Analysis#last_keystroke" do

  before :each do
    @a = Analysis.new
  end

  it "should return the last keystroke in the array when it has been depressed" do
    keystroke = {:character => 'a', :time_pressed => 0, :time_released => 1}
    @a.keystrokes = [keystroke]
    @a.last_keystroke.should == keystroke
  end

  it "should return the second to last keystroke in the array when it is still being pressed" do
    keystroke = {:character => 'b', :time_pressed => 0}
    @a.keystrokes = [keystroke, {:character => 'a', :time_pressed => 2, :time_released => 3}]
    @a.last_keystroke.should == keystroke
  end

end

describe "Analysis#mean_seek" do
  before :each do
    @a = Analysis.new
  end

  it "should return the mean of seek times for a single character" do
    @a.keystrokes = [ {:seek_time => 1, :character => 'a'}]
    @a.mean_seek.should == 1
  end
  it "should return the mean of seek times for two identical characters" do
    @a.keystrokes = [ {:seek_time => 1, :character => 'a'}, {:seek_time => 5, :character => 'a'}]
    @a.mean_seek.should == 3
  end  
  it "should return the mean of seek times for two different characters" do
    @a.keystrokes = [ {:seek_time => 1, :character => 'a'}, {:seek_time => 5, :character => 'b'}]
    @a.mean_seek.should == 3
  end

end

describe "Analysis#statistics" do
  before :each do
    @a = Analysis.new
    @a.keystrokes = [{:character => 'a', :seek_time => 5, :hold_time => 10}, {:character => 'a', :seek_time => 10, :hold_time => 20}]
  end

  it "should calculate averages for a 2-array of keystrokes" do
    stats = Analysis.statistics([@a.keystrokes])
    stats[:a][:seeks].should == 2
    stats[:a][:holds].should == 2
    stats[:a][:seek_total].should == 15
    stats[:a][:hold_total].should == 30
    stats[:a][:min_seek].should == 5
    stats[:a][:max_seek].should == 10
    stats[:a][:min_hold].should == 10
    stats[:a][:max_hold].should == 20
  end
end

describe "Analysis#metric" do
  before :each do
    @a = Analysis.new
    @a.keystrokes = [{:character => 'a', :seek_time => 10, :hold_time => 10}, {:character => 'a', :seek_time => 20, :hold_time => 40}]
  end

  it "should return a predictable metric for a 2-array of keystrokes" do
    metric = Analysis.metric([@a.keystrokes])
    metric[:a][:mean_seek].should == 15
    metric[:a][:mean_hold].should == 25
    metric[:a][:min_seek].should == 10
    metric[:a][:max_seek].should == 20
    metric[:a][:min_hold].should == 10
    metric[:a][:max_hold].should == 40
  end

end

