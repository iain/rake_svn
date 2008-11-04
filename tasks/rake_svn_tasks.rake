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
    system "svn remove log/*"
    system "svn commit -m 'removing all log files from subversion'"
    system 'svn propset svn:ignore "*.log" log/'
    system "svn update log/"
    system "svn commit -m 'Ignoring all files in /log/ ending in .log'"
    system 'svn propset svn:ignore "*.db" db/'
    system "svn update db/"
    system "svn commit -m 'Ignoring all files in /db/ ending in .db'"
    system "svn move config/database.yml config/database.example"
    system "svn commit -m 'Moving database.yml to database.example to provide a template for anyone who checks out the code'"
    system 'svn propset svn:ignore "database.yml" config/'
    system "svn update config/"
    system "svn commit -m 'Ignoring database.yml'"
    system "svn remove public/stylesheets/*.css"
    system "svn commit -m 'Removing stylesheets, in favor of sass'"
    system 'svn propset svn:ignore "*.css" public/stylesheets'
    system "svn commit -m 'Ignoring css files in favor of sass'"
    system 'svn propset svn:ignore "schema.rb" db/'
    system "svn commit -m 'Ignoring schema.rb'"
  end


end

