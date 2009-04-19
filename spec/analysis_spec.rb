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
    @test_entry = Gtk::Entry.new
    @a.analyze_keys(@test_entry)
    #@test_entry.press('a')
    pending "Need a way to mock signals in Gtk widgets"
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

describe "Analysis#mean_kps" do
  before :each do
    @a = Analysis.new
  end

  it "should return 0 if the array is empty" do
    @a.mean_kps.should == 0
  end

  it "should return the mean keys per second for an array of characters" do
    @a.keystrokes = [ {:time_pressed => 0, :character => 'a'}, {:time_pressed => 1000, :character => 'a'}, {:time_pressed => 2000, :character => 'a'}]
    @a.mean_kps.should == 1
  end

  it "should return the mean keys per second for an array of characters" do
    @a.keystrokes = [ {:time_pressed => 0, :character => 'a'}, {:time_pressed => 500, :character => 'a'}]
    @a.mean_kps.should == 2
  end

  it "should return the mean keys per second for an array of characters" do
    @a.keystrokes = [ {:time_pressed => 1000, :character => 'a'}, {:time_pressed => 1500, :character => 'a'}, {:time_pressed => 1999, :character => 'a'}]
    @a.mean_kps.should == 3
  end

end

describe "Analysis#mean_hold" do
  before :each do
    @a = Analysis.new
  end

  it "should return 0 if the array is empty" do
    @a.mean_hold.should == 0
  end

  it "should return the mean of hold times for a single character" do
    @a.keystrokes = [ {:hold_time => 1, :character => 'a'}]
    @a.mean_hold.should == 1
  end
  it "should return the mean of hold times for two identical characters" do
    @a.keystrokes = [ {:hold_time => 1, :character => 'a'}, {:hold_time => 3, :character => 'a'}]
    @a.mean_hold.should == 2
  end  
  it "should return the mean of seek times for two different characters" do
    @a.keystrokes = [ {:hold_time => 1, :character => 'a'}, {:hold_time => 5, :character => 'b'}]
    @a.mean_hold.should == 3
  end

end

describe "Analysis#mean_seek" do
  before :each do
    @a = Analysis.new
  end

  it "should return 0 if the array is empty" do
    @a.mean_seek.should == 0
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

describe "Analysis.statistics" do
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

describe "Analysis.metric" do
  before :each do
    @a = Analysis.new
  end

  it "should return a predictable metric for a 2-array of keystrokes" do
    @a.keystrokes = [{:character => 'a', :seek_time => 10, :hold_time => 10}]
    metric = Analysis.metric([@a.keystrokes])
    metric[:a][:mean_seek].should == 10
    metric[:a][:mean_hold].should == 10
    metric[:a][:min_seek].should == 10
    metric[:a][:max_seek].should == 10
    metric[:a][:min_hold].should == 10
    metric[:a][:max_hold].should == 10
  end

  it "should return a predictable metric for a 2-array of keystrokes" do
    @a.keystrokes = [{:character => 'a', :seek_time => 10, :hold_time => 10}, {:character => 'a', :seek_time => 20, :hold_time => 40}]
    metric = Analysis.metric([@a.keystrokes])
    metric[:a][:mean_seek].should == 15
    metric[:a][:mean_hold].should == 25
    metric[:a][:min_seek].should == 10
    metric[:a][:max_seek].should == 20
    metric[:a][:min_hold].should == 10
    metric[:a][:max_hold].should == 40
  end

end

describe "Analysis.compare_metrics" do
  # deviations actually get counted twice.

  it "should return 1 for identical arrays" do
    keystrokes = [{:character => 'a', :seek_time => 0, :hold_time => 10}]
    Analysis.compare_metrics(Analysis.metric([keystrokes]), Analysis.metric([keystrokes])).should == 1
  end

  it "should return 0 for deviations of over #{MAX_ALLOWED_DEVIATION}" do
    keystrokes_1 = [{:character => 'a', :seek_time => 0, :hold_time => 5}]
    keystrokes_2 = [{:character => 'a', :seek_time => MAX_ALLOWED_DEVIATION/2+1, :hold_time => 5}]
    Analysis.compare_metrics(Analysis.metric([keystrokes_1]), Analysis.metric([keystrokes_2])).should == 0
  end

  it "should return 0 for deviations of #{MAX_ALLOWED_DEVIATION}" do
    keystrokes_1 = [{:character => 'a', :seek_time => 0, :hold_time => 5}]
    keystrokes_2 = [{:character => 'a', :seek_time => MAX_ALLOWED_DEVIATION/2, :hold_time => 5}]
    Analysis.compare_metrics(Analysis.metric([keystrokes_1]), Analysis.metric([keystrokes_2])).should == 0

    keystrokes_1 = [{:character => 'a', :hold_time => 0, :seek_time => 5}]
    keystrokes_2 = [{:character => 'a', :hold_time => MAX_ALLOWED_DEVIATION/2, :seek_time => 5}]
    Analysis.compare_metrics(Analysis.metric([keystrokes_1]), Analysis.metric([keystrokes_2])).should == 0
  end

  it "should return 0.5 for deviations of #{MAX_ALLOWED_DEVIATION/2}" do
    keystrokes_1 = [{:character => 'a', :seek_time => MAX_ALLOWED_DEVIATION/4, :hold_time => 5}]
    keystrokes_2 = [{:character => 'a', :seek_time => 0, :hold_time => 5}]
    Analysis.compare_metrics(Analysis.metric([keystrokes_1]), Analysis.metric([keystrokes_2])).should == 0.5

    keystrokes_1 = [{:character => 'a', :hold_time => MAX_ALLOWED_DEVIATION/4, :seek_time => 5}]
    keystrokes_2 = [{:character => 'a', :hold_time => 0, :seek_time => 5}]
    Analysis.compare_metrics(Analysis.metric([keystrokes_1]), Analysis.metric([keystrokes_2])).should == 0.5
  end

end

