namespace :svn do

  desc "Gets the current svn repository url."
  task :repository do
    SVN_BASE = `svn info | grep ^URL | awk '{print $2}'`
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
  task :ignores do
    svn_ignore 'log', '*'
    svn_ignore 'db', '*.sqlite*', 'schema.rb'

    svn_ignore 'tmp/cache', '*'
    svn_ignore 'tmp/pids', '*'
    svn_ignore 'tmp/sessions', '*'
    svn_ignore 'tmp/sockets', '*'

    svn_ignore 'public/stylesheets', '*.css'

    svn "update config/"
    svn "move config/database.yml config/database.example"
    svn "commit -m 'Moving database.yml to database.example to provide a template for anyone who checks out the code'"
    svn "update config/"

    svn_ignore 'config', 'database.yml'
  end

end

def svn(command)
  puts "", "svn #{command}"
  system "svn #{command}"
end

def svn_ignore(dir, *files)
  files.each do |f|
    svn "remove #{File.join(dir, f)}"
  end
  svn "commit -m 'Removing #{files.join(', ')} in #{dir} before ignoring it'"
  svn "update #{dir}"
  svn "propset svn:ignore '#{files.join(' ')}' #{dir}"
  svn "update #{dir}"
  svn "commit -m 'Ignoring #{files.join(', ')} in #{dir}'"
  svn "update #{dir}"
end
