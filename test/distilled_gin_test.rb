require File.dirname(__FILE__) + '/../lib/distilled_gin.rb'
require 'test/unit'
require 'rubygems'

module DistilledGin::MigrationExtensions
  def exec_stmt(stmt)
    stmt
  end
end

class PostGinTest < Test::Unit::TestCase
  include DistilledGin::MigrationExtensions

  def test_add_gin_index
    assert_raise ArgumentError do 
      add_gin_index 
    end
    
    assert_raise ArgumentError do
      add_gin_index :table => :test_table
    end
    
    assert_raise ArgumentError do 
      add_gin_index :columns => [:test_col1, :test_col2] 
    end

    assert_nothing_raised { add_gin_index :table => :test_table, :columns => [:test_col1, :test_col2] }
  end

  def test_remove_gin_index
    assert_raise ArgumentError do
      remove_gin_index
    end

    assert_nothing_raised { remove_gin_index :table => :test_table }
  end

  def test_generate_index_column_name
    assert_equal "test_table_tsv_idx", generate_index_column_name(:test_table)
  end

  def test_generate_trigger_name
    assert_equal "test_table_tsv_trigger", generate_trigger_name(:test_table)
  end

  def test_generate_index_name(tsv_table)
    assert_equal "test_table_tsv_idx", generate_index_name(:test_table)
  end

  def test_generate_columns_coalesced
    assert_equal "coalesce(test_col1,'') || coalesce(test_col2,'') || coalesce(test_col3,'')",
      generate_columns_coalesced([:test_col1, :test_col2, :test_col3])
  end

  def test_add_index_column
    assert_equal "ALTER TABLE test_table ADD COLUMN test_col tsvector",
      add_index_column(:test_table, :test_col)
  end

  def test_update_index_column
    assert_equal "UPDATE test_table SET idx_col = to_tsvector('english', coalesce(test_col1,'') || coalesce(test_col2,''))",
      update_index_column(:test_table, :idx_col, generate_columns_coalesced([:test_col1, :test_col2]))
  end

  def test_create_gin_index
    assert_equal "CREATE INDEX test_idx_name ON test_table USING gin(test_col)",
      create_gin_index(:test_table, :test_idx_name, :test_col)
  end

  def test_create_trigger
    assert_equal "CREATE TRIGGER test_trigger_name BEFORE INSERT OR UPDATE ON test_table_name FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(test_idx_col, 'pg_catalog.english', coalesce(test_col1,'') || coalesce(test_col2,''))",
    create_trigger(:test_table_name, :test_trigger_name, :test_idx_col,  generate_columns_coalesced([:test_col1, :test_col2]))
  end

  def test_drop_trigger
    assert_equal "DROP TRIGGER IF EXISTS test_trigger_name ON test_table_name", drop_trigger(:test_table_name, :test_trigger_name)
  end
  
  def test_drop_gin_index
    assert_equal "DROP INDEX IF EXISTS test_idx_name", drop_gin_index(:test_idx_name)
  end

  def test_drop_index_column
    assert_equal "ALTER TABLE test_table DROP COLUMN test_idx_col", drop_index_column(:test_table, :test_idx_col)
  end

end
