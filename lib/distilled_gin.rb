module DistilledGin
  module ActiveRecordExtensions
    def is_distilled_gin(opts={})
      include DistilledGin::NamedScopes
    end
  end

  module NamedScopes
    def self.included(klass)
      klass.class_eval do
        named_scope :with_gin, lambda { |search_string|
          if search_string.blank?
          return {}
          else
            { :conditions => "#{table_name}_tsv_idx @@ to_tsquery('#{search_string}')" }
          end
        }
      end
    end
  end

  module MigrationExtensions

    def add_gin_index(opts={})
      raise ArgumentError unless opts[:table]
      raise ArgumentError unless opts[:columns]
      raise ArgumentError unless opts[:table].class == Symbol
      raise ArgumentError unless opts[:columns].class == Array
    
      table_name        = opts[:table]
      columns_array     = opts[:columns]
      index_column      = generate_index_column_name(table_name)
      trigger_name      = generate_trigger_name(table_name)
      index_name        = generate_index_name(table_name)
      columns_coalesced = generate_columns_coalesced(columns_array)
      columns_list      = columns_array.join(',')

      exec_stmt add_index_column(table_name, index_column)
      exec_stmt update_index_column(table_name, index_column, columns_coalesced)
      exec_stmt create_gin_index(table_name, index_name, index_column)
      exec_stmt create_trigger(table_name, trigger_name, index_column, columns_list)
    end

    def remove_gin_index(opts={})
      raise ArgumentError unless opts[:table]
   
      table_name = opts[:table]

      trigger_name = generate_trigger_name(table_name)
      index_name = generate_index_name(table_name)
      index_column = generate_index_column_name(table_name)
    
      exec_stmt drop_trigger(table_name, trigger_name)
      exec_stmt drop_gin_index(index_name)
      exec_stmt drop_index_column(table_name, index_column)
    end

    private

    def generate_index_column_name(table_name)
      "#{table_name}_tsv_idx"
    end

    def generate_trigger_name(table_name)
      "#{table_name}_tsv_trigger"
    end

    def generate_index_name(table_name)
      "#{table_name}_tsv_idx"
    end

    def generate_columns_coalesced(columns_array)
      columns_array.map { |col| "coalesce(#{col},'')" }.join(' || ')
    end

    def add_index_column(table_name, index_column)
      "ALTER TABLE #{table_name} ADD COLUMN #{index_column} tsvector"
    end

    def drop_index_column(table_name, index_column)
      "ALTER TABLE #{table_name} DROP COLUMN #{index_column}"
    end

    def update_index_column(table_name, index_column, columns_coalesced)
      "UPDATE #{table_name} SET #{index_column} = to_tsvector('english', #{columns_coalesced})"
    end

    def create_gin_index(table_name, index_name, index_column)
      "CREATE INDEX #{index_name} ON #{table_name} USING gin(#{index_column})"
    end

    def drop_gin_index(index_name)
      "DROP INDEX IF EXISTS #{index_name}"
    end

    def create_trigger(table_name, trigger_name, index_column, columns_list)
      "CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON #{table_name} FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(#{index_column}, 'pg_catalog.english', #{columns_list})" 
    end

    def drop_trigger(table_name, trigger_name)
      "DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name}"
    end

    def exec_stmt(stmt)
      execute stmt
    end
  end
end
