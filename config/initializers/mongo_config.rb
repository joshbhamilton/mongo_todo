MongoMapper.connection = Mongo::Connection.new('ec2-204-236-177-224.us-west-1.compute.amazonaws.com', 27017)
MongoMapper.database = "#{app_name}_#{node[:environment][:framework_env]}"
MongoMapper.database.authenticate("root", "#{user[:password]}")