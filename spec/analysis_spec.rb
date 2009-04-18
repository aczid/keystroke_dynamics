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

describe Analysis do
  before :each do 
    @a = Analysis.new
    @test_entry = Gtk::Entry.new
    @a.analyze_keys(@test_entry)
  end

  it "Should collect data from the GTK widget" do
    @test_entry.press("foo")

  end

  it "should do stuff" do
    violated "foo"
  end

  it "should do foo" do
    violated "bar"
  end
  
end

