namespace :jruby do
  desc "Create war file"
  task :warble do
    system("warble executable war")
  end
end