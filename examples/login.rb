#!/usr/bin/env ruby
# == Summary
# This is an example login application set up to validate keystroke dynamics data.

require 'rubygems'
require 'gtk2'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'keystroke_dynamics'
KeystrokeDynamics::Validation::KSD_DIR = './keystroke_dynamics/'
KeystrokeDynamics::Validation::PH_FILE = './passwd'
KeystrokeDynamics::Validation::ACCURACY_THRESHOLD = 0.5


window = Gtk::Window.new
window.title = "Keystroke dynamics login test application"
window.signal_connect("destroy") { Gtk.main_quit }
window.signal_connect("delete_event") { Gtk.main_quit }

mainbox = Gtk::VBox.new(false,0)
window.add(mainbox)
mainbox.show

mainbox.pack_start(Gtk::Label.new("Try to log in!"), true, true, 20)

login = Gtk::Entry.new
login.select_region(0,-1)
login.set_editable(true)
pass = Gtk::Entry.new
pass.set_editable(true)
pass.set_invisible_char(42) # 42 is "*" in unicode
pass.set_visibility(false)

ksd = KeystrokeDynamics::Analysis.new
ksd.analyze_keys([login, pass])

button = Gtk::Button.new("Log in")
button.signal_connect("clicked") do |w|
  if(KeystrokeDynamics::Validation.validate(login.text, pass.text, [ksd.keystrokes]))
    puts "Logged in successfully!"
    Gtk.main_quit
  end
  # reset entry fields and identified keys to allow several login attempts, avoid the risk of comparing empty keys
  login.text=""
  pass.text=""
  ksd.keystrokes = []
end

button.show

mainbox.pack_start(login, true, true,0)
mainbox.pack_start(pass, true, true,0)
mainbox.pack_start(button, true, true,20)

login.show
pass.show

window.set_default_size(100, 100).show_all

window.show

Gtk.main
exit

