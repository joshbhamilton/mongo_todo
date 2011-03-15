class Project
  include MongoMapper::Document
  
  key :name, String
  key :priority, Integer
  validates_presence_of :name
end
