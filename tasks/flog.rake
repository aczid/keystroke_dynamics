desc "Flog /lib"
task :flog do
  puts `find lib -name \*.rb | xargs flog`
end

