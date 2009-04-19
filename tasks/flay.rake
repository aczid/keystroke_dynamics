desc "Flay /lib"
task :flay do
  puts `flay lib/**/*.rb`
end
