desc "Heckle each module and class in turn"
task :heckle => :verify_rcov do
  root_module = "KeystrokeDynamics"
  spec_files = FileList['spec/**/*_spec.rb']

  current_module, current_method = nil, nil
  heckle_caught_modules = Hash.new { |hash, key| hash[key] = [] }
  unhandled_mutations = 0

  IO.popen("spec --heckle #{root_module} #{spec_files}") do |pipe|
    while line = pipe.gets
      line = line.chomp

      if line =~ /^\*\*\*  ((?:\w+(?:::)?)+)#(\w+)/
        current_module, current_method = $1, $2
      elsif line == "The following mutations didn't cause test failures:"
        heckle_caught_modules[current_module] << current_method
      elsif line == "+++ mutation"
        unhandled_mutations += 1 
      end

      puts line
    end
  end

  if unhandled_mutations > 0
    error_message_lines = ["*************\n"]

    error_message_lines << "Heckle found #{unhandled_mutations} " + "mutation#{"s" unless unhandled_mutations == 1} " + "that didn't cause spec violations\n"

    heckle_caught_modules.each do |mod, methods|
      error_message_lines << "#{mod} contains the following poorly-specified methods:"
      methods.each do |m| 
        error_message_lines << " - #{m}"
      end
      error_message_lines << ""
    end

    error_message_lines << "Get your act together and come back " + "when your specs are doing their job!"
    puts "*************"
    raise error_message_lines.join("\n")
  else
    puts "Well done! Your code withstood a heckling."
  end
end

