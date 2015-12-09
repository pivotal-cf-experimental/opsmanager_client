desc 'bump and release patch version, create and push gem to Gemfury'
task :release_patch => [:bump_patch, :build, :push]

desc 'bump and release minor version, create and push gem to Gemfury'
task :release_minor => [:bump_minor, :build, :push]

desc 'bump and release major version, create and push gem to Gemfury'
task :release_major => [:bump_major, :build, :push]

desc 'build gem'
task :build do
  gemspec = Dir["*.gemspec"].first
  raise "No .gemspec could be found!" unless gemspec
  sh "gem build #{gemspec}"
end

desc 'push latest gem'
task :push do
  new_gem = Dir["*.gem"].sort_by { |file| File.stat(file).ctime }.last
  raise "Could not find newly created gem!" unless new_gem
  sh "gem push #{new_gem}"
end

desc 'bump patch'
task :bump_patch => [:rebase] do
  sh "gem bump " +
    "--version patch " +
    "--commit " +
    "--tag " +
    "--push"
end

desc 'bump minor'
task :bump_minor => [:rebase] do
  sh "gem bump " +
    "--version minor " +
    "--commit " +
    "--tag " +
    "--push"
end

desc 'bump major'
task :bump_major => [:rebase] do
  sh "gem bump " +
    "--version major " +
    "--commit " +
    "--tag " +
    "--push"
end

task :rebase do
  sh "git pull --rebase"
end

