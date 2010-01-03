
set :rails_env, "production"

set :domain, '000000book.com' # FIXME; how can we get the hostname of the current server inside a cap task?
set :user, 'blackbook'
set :use_sudo, false
set :deploy_to, "/home/blackbook/blackbook"

role :web, '000000book.com', :primary => true
role :app, '000000book.com'
role :db, '000000book.com', :primary => true

# set (:deploy_to) { "/home/blackbook/blackbook" }
