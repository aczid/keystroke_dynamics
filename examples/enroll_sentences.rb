#!/usr/bin/env ruby
# == Summary
# This is an example enrollment application set up to collect keystroke dynamics data by letting the user type several sentences.
require 'rubygems'
require 'gtk2'
$:.unshift(File.dirname(__FILE__) + '/../lib')
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

mainbox.pack_start(Gtk::Label.new("Please type these sentences so I can learn your keystroke dynamics."), true, true, 20)

sentences = [
  Gtk::Label.new("Two driven jocks help fax my big quiz."),
  Gtk::Label.new("How quickly daft jumping zebras vex."),
  Gtk::Label.new("The five boxing wizards jump quickly."),
  Gtk::Label.new("Jackdaws love my big sphinx of quartz."),
  Gtk::Label.new("The quick brown fox jumps over the lazy dog.")
  ]
  
statsbox = Gtk::HBox.new
mean_hold_label = Gtk::Label.new
mean_seek_label = Gtk::Label.new
mean_kps_label = Gtk::Label.new
statsbox.pack_start(mean_hold_label, true, true, 0)
statsbox.pack_start(mean_seek_label, true, true, 0)
statsbox.pack_start(mean_kps_label, true, true, 0)

ksds = []
for i in (0..4)
  entry = Gtk::Entry.new
  entry.set_text("")
  entry.set_editable(true)
  ksds[i] = KeystrokeDynamics::Analysis.new
  ksds[i].analyze_keys(entry)
  mainbox.pack_start(sentences[i],true,true,0)
  entry.signal_connect_after("key-release-event", ksds[i]) do |w, e, analyzer|
    mean_hold_label.text = "Mean hold: #{analyzer.mean_hold}"
    mean_seek_label.text = "Mean seek: #{analyzer.mean_seek}"
    mean_kps_label.text = "Mean KPS: #{analyzer.mean_kps}"
    false
  end
  entry.show
  mainbox.pack_start(entry,true,true,0)
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
