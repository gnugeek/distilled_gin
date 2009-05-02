require 'distilled_gin.rb'

class ActiveRecord::Migration
  extend DistilledGin::MigrationExtensions
end

class ActiveRecord::Base
  extend DistilledGin::ActiveRecordExtensions
end
