$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "keystroke_dynamics/analysis"
require "keystroke_dynamics/validation"

# == Simple keystroke dynamics analyzer/validator written in Ruby-GTK
# Copyright (c) 2008 Aram Verstegen <aram@aczid.nl>
#
# == Summary
# The three included Ruby-GTK examples demonstrate the principle of biometric authentication based on keystroke dynamics. For experimentational purposes, I have created two different examples which establish a metric from a users typing. The first, enroll_sentences.rb, lets you type in 5 pangrams (sentences that hold every letter of the alphabet) to establish your metric. The other, enroll_login.rb, lets you type your login details 10 times. I leave it as an excercise to the user to see which method works best for him or her.
# The login.rb example lets you try out your newly created username, password and keystroke metric on a login screen.
#
# === Libraries
# The logic in analyzer.rb and validation.rb can be used by other Ruby-GTK applications, as Analysis instances have methods to attach signal handlers for any Instantiable GTK widget.
#
# ==== Analysis
# This class holds logic to extract simple biometric information from GTK widgets.
#
# ==== Validation
# This class holds logic to manage user enrollment, validation and cryptographic functions.
#
# === Dependencies
# To run the Ruby-GTK examples you will need libgtk2-ruby.
# The validation functions require libopenssl-ruby.
module KeystrokeDynamics
  VERSION = '0.0.3'
end
