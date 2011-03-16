# MongoDB Test Application for AppCloud

This is an update of the ToDo List application that Ryan Bates creates in Railscasts [[Episode 194|http://railscasts.com/episodes/194-mongodb-and-mongomapper]]. Where the application in that episode is Rails 2.3.5, this is updated to Rails 3.0.3.

The purpose of this application is to have a simple application that uses MongoDB and MongoMapper to test how to setup MongoDB on Engine Yard's AppCloud. We will be using custom Chef recipes to deploy the application. You can find the recipes at [[https://github.com/engineyard/ey-cloud-recipes]] and documentation about how to use it on AppCloud at [[http://docs.engineyard.com/appcloud/howtos/customizations/custom-chef-recipes]].


## Getting Started in AppCloud

1. Boot up a Cluster of Instances.

2. Boot up a Utility Instance. MongoDB will be installed here so as not to conflict with MySQL.
    * Name the Utility Instance `mongodb_master`. This will be important for the custom Chef recipe.

3. Deploy the `mongo_todo` application without running any migrations.

4. Fork and clone the `ey-cloud-recipes` that were mentioned above. There is one for MongoDB included.

5. Turn on the **MongoDB** cookbook.
    * Open the `cookbooks/main/recipes/default.rb` file.
    * This file contains a series of lines commented out that describe or require a given recipe. Uncomment out `require_recipe "mongodb"`.
    * Save your changes and commit the file to the repository
    
    $ git commit -am "activated mongodb"

6. If you haven't already, install the `engineyard` gem.

    gem install engineyard
    
7. The application will need to have a configuration file to make the connection to MongoDB. Since this is on a separate Utility instance, we need to create something like (of course, replacing the variables in CAPS with the proper values):

    #config/initializers/mongo_config.rb
    MongoMapper.connection = Mongo::Connection.new("UTIL_HOSTNAME", UTIL_PORT)
    MongoMapper.database = "DB_NAME"
    MongoMapper.database.authenticate("USERNAME", "PASSWORD")
    
    * UTIL_HOSTNAME is the hostname for the Utility instance. This looks like 'ec2-0-0-0-0.us-east-1.compute.amazonaws.com'.
    * UTIL_PORT is 27017.
    * DB_NAME is assigned by the Chef recipe as "#{app_name}_#{node[:environment][:framework_env]}".
    * USERNAME is deploy.
    * PASSWORD is the same password that is created in the 'config/database.yml' file.
    
**NOTE:** If you terminate this instance, the UTIL_HOSTNAME variable will change and you must change this. One way to solve this is to update the custom Chef recipe to write this file for you.
    
    # ey-cloud-recipes/cookbooks/mongodb/recipes/default.rb
    if ['app_master', 'app'].include?(node[:instance_role])
      template "/data/#{node.engineyard.apps.first.name}/current/config/initializers/mongo_config.rb" do
        owner node.engineyard.environment.ssh_username
        group node.engineyard.environment.ssh_username
        mode 0655
        backup 0
        source "mongo_config.erb"
        variables({
          :m_hostname => node.engineyard.environment.instances[2].public_hostname,
          :m_port => 27017,
          :m_appname => node.engineyard.apps.first.name,
          :m_framework_env => node.environment[:framework_env],
          :m_username => "deploy",
          :m_password => node.users[0][:password],
        })
        action :create
      end
    end
    
    # ey-cloud-recipes/cookbooks/mongodb/templates/default/mongo_config.erb
    MongoMapper.connection = Mongo::Connection.new("<%= @m_hostname %>", <%= @m_port %>)
    MongoMapper.database = "<%= @m_appname %>_<%= @m_framework_env %>"
    MongoMapper.database.authenticate("<%= @m_username %>", "<%= @m_password %>")

8. Invoke your custom Chef recipes. Go to your local copy of the ey-cloud-recipes where you have been modifying them, and enter:

    From the root of your recipes repository run:
    $ ey recipes upload -e <environment_name>
    
    Then run them with:
    $ ey recipes apply -e <environment_name>
    
**NOTE:** Occasionally the first attempt at applying the Chef recipe will fail with:

    ERROR: execute[create-mongodb-root-user] (/etc/chef-custom/recipes/cookbooks/mongodb/recipes/default.rb line 115) had an error:
    /usr/bin/mongo admin --eval 'db.addUser("root","sssssssss")' returned 255, expected 0
    ---- Begin output of /usr/bin/mongo admin --eval 'db.addUser("root","sssssssss")' ----
    STDOUT: MongoDB shell version: 1.4.4
    url: admin
    connecting to: admin
    Wed Mar 16 16:15:24 JS Error: Error: couldn't connect: couldn't connect to server 127.0.0.1 127.0.0.1:27017 (anon):952
    Wed Mar 16 16:15:24 User Exception 12513:connect failed
    STDERR: exception: connect failed
    
  * If this occurs, then apply the recipes again. Sometimes MongoDB has not finished starting before this runs - causing it to fail.
  
9. Hit the "HTTP" button and test it out.       