namespace :svn do

  desc "Gets the current svn repository url."
  task :repository do
    SVN_BASE = `svn info | grep ^URL | awk '{print $2}'`.sub(/trunk$/,'').strip
    puts "Using repository #{SVN_BASE}"
  end

  desc "Tag current trunk.  Use VERSION to provide a version number."
  task :tag => :repository do
    version = ENV['VERSION'] or raise 'Provide a VERSION-number, e.g. rake svn:tag VERSION=0.1.3'
    trunk, tag = SVN_BASE + "trunk", SVN_BASE + "tags/#{version}"
    system *(%w(svn copy -m) << "Tagged release number #{version} as a copy from trunk." << trunk << tag)
  end
  
  desc "List all tags."
  task :tags => :repository do
    system *(%w(svn list -v) << "#{SVN_BASE}tags")
  end

  desc "Add all new files to repository"
  task :add => :repository do
    system "svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add --force"
  end

  desc "Deletes all missing files from the repository"
  task :rm => :repository do
    system "svn status | grep '^\!' | sed -e 's/! *//' | sed -e 's/ /\ /g' | xargs svn rm --force"
  end

  desc "Perfom both add and rm"
  task :both => [:add, :rm]

  desc "Configure Subversion for Rails"
  task :init_rails do
    svn_ignore 'log', '*'
    svn_ignore 'db', '*.sqlite*', 'schema.rb'

    svn_ignore 'tmp/cache', '*'
    svn_ignore 'tmp/pids', '*'
    svn_ignore 'tmp/sessions', '*'
    svn_ignore 'tmp/sockets', '*'

    svn_ignore 'public/stylesheets', '*.css'

    svn "update config/", :verbose => false
    database_files = Dir.glob("#{File.dirname(__FILE__)}/../database-files/*.yml")
    FileUtils.cp database_files, "config/", :verbose => true
    database_files.each do |file|
      svn "add config/#{File.basename(file)}"
    end
    svn "commit -m 'Added example database configurations'"

    svn_ignore 'config', 'database.yml'
  end

  desc "Adds an ignore. Use DIR='log' and IGNORE='foo;log' (semicolon separated)"
  task :ignore do
    raise "You must specify an existing directory, e.g. DIR='log'" unless File.directory?(ENV['DIR'])
    raise "You must specify which file(-pattern) to ignore, e.g. IGNORE='*.log'" unless ENV['IGNORE'].blank?
    svn_ignore ENV['DIR'], *ENV['IGNORE'].split(";")
  end

end

def svn(command, options = {})
  puts "", "svn #{command.gsub("\r","\n")}" unless !options[:verbose]
  system "svn #{command}"
end

def svn_ignore(dir, *files)

  # updating that dir to make sure no conflicts appear
  svn "update #{dir}", :verbose => false

  # append any files to already ignored files
  files += `svn pg svn:ignore #{ENV['dir']}`.split("\n")
  files = files.compact.uniq.collect(&:strip)

  # delete existing files first
  unless (existing_files = files.reject { |it| File.exist?(it) }).empty?
    existing_files.each do |f|
      svn "remove #{File.join(dir, f)}"
    end
    svn "commit -m 'Removing #{existing_files.join(', ')} in #{dir} before ignoring it'"
    svn "update #{dir}", :verbose => false
  end

  # finally we can ignore the files
  svn "propset svn:ignore '#{files.join("\r")}' #{dir}"
  svn "update #{dir}", :verbose => false
  svn "commit -m 'Ignoring #{files.join(', ')} in #{dir}'"
  svn "update #{dir}", :verbose => false

end
