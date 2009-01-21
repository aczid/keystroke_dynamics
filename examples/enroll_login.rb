#!/usr/bin/env ruby
# == Summary
# This is an example enrollment application set up to collect keystroke dynamics data by letting the user type his username and password several times.

require 'gtk2'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'keystroke_dynamics'
KeystrokeDynamics::Validation::KSD_DIR = './keystroke_dynamics/'
KeystrokeDynamics::Validation::PH_FILE = './passwd'

window = Gtk::Window.new
window.title = "Keystroke dynamics enrollment test application"
window.signal_connect("destroy") { Gtk.main_quit }
window.signal_connect("delete_event") { Gtk.main_quit }

mainbox = Gtk::VBox.new(false,0)
window.add(mainbox)
mainbox.show

user = Gtk::Entry.new
user.set_text("username")
user.set_editable(true)
pass = Gtk::Entry.new
pass.set_text("pass")
pass.set_editable(true)
pass.set_invisible_char(42) # 42 is "*" in unicode
pass.set_visibility(false)

loginbox = Gtk::VBox.new
loginbox.pack_start(Gtk::Label.new("Choose you login details"), true, true, 0)
loginbox.pack_start(user, true, true, 0)
loginbox.pack_start(pass, true, true, 0)

mainbox.pack_start(loginbox, true, true,0)
mainbox.show

mainbox.pack_start(Gtk::Label.new("Please type your login details 10 times so I can learn your keystroke dynamics."), true, true, 20)

statsbox = Gtk::HBox.new
mean_hold_label = Gtk::Label.new
mean_seek_label = Gtk::Label.new
mean_kps_label = Gtk::Label.new
statsbox.pack_start(mean_hold_label, true, true, 0)
statsbox.pack_start(mean_seek_label, true, true, 0)
statsbox.pack_start(mean_kps_label, true, true, 0)

ksds = []
for i in (0..9)
  loginbox = Gtk::HBox.new
  login = Gtk::Entry.new
  login.select_region(0,-1)
  login.set_editable(true)
  pass = Gtk::Entry.new
  pass.set_editable(true)
  pass.set_invisible_char(42) # 42 is "*" in unicode
  pass.set_visibility(false)
  loginbox.pack_start(login, true, true, 0)
  loginbox.pack_start(pass, true, true, 0)
  ksds[i] = KeystrokeDynamics::Analysis.new
  ksds[i].analyze_keys([login, pass])
  loginbox.signal_connect_after("key-release-event", ksds[i]) do |w, e, analyzer|
    mean_hold_label.text = "Mean hold: #{analyzer.mean_hold}"
    mean_seek_label.text = "Mean seek: #{analyzer.mean_seek}"
    mean_kps_label.text = "Mean KPS: #{analyzer.mean_kps}"
    false
  end
  loginbox.show
  mainbox.pack_start(loginbox,true,true,0)
end

mainbox.pack_start(statsbox,true,true,20)
statsbox.show

button = Gtk::Button.new("Enroll")
button.signal_connect("clicked") do |w|
  keystroke_array_array = []
  ksds.each do |ksd|
    keystroke_array_array << ksd.keystrokes
  end
  if KeystrokeDynamics::Validation.enroll(user.text, pass.text, keystroke_array_array)
    Gtk.main_quit
  end
end
button.show
mainbox.pack_start(button, true, true,0)

window.set_default_size(100, 100).show_all

window.show

Gtk.main
exit
