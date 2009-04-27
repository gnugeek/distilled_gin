module DistilledGinMigrations

  def add_gin_index(tsv_table, *tsv_cols)
    tsv_idx_col = create_tsv_idx_col_name(tsv_table)
    tsv_trigger = create_tsv_trigger_name(tsv_table)
    tsv_idx = create_tsv_idx_name(tsv_table)
    tsv_cols_coalesce = create_tsv_col_list(tsv_cols)
    tsv_cols_list = tsv_cols.join(',')

    exec_stmt add_tsv_column(tsv_table, tsv_idx_col)
    exec_stmt update_tsv_column(tsv_table, tsv_idx_col, tsv_cols_coalesce)
    exec_stmt create_gin_index(tsv_idx, tsv_table, tsv_idx_col)
    exec_stmt create_tsv_trigger(tsv_trigger, tsv_table, tsv_idx_col, tsv_cols_list)
  end

  def remove_gin_index(tsv_table)
    tsv_trigger = create_tsv_trigger_name(tsv_table)
    tsv_idx = create_tsv_idx_name(tsv_table)
    tsv_idx_col = create_tsv_idx_col_name(tsv_table)
    
    exec_stmt drop_tsv_trigger(tsv_trigger, tsv_table)
    exec_stmt drop_gin_index(tsv_idx)
    exec_stmt drop_tsv_column(tsv_table, tsv_idx_col)
  end

  private
  
  def create_tsv_idx_col_name(tsv_table)
    "#{tsv_table}_tsv_idx"
  end

  def create_tsv_trigger_name(tsv_table)
    "#{tsv_table}_tsv_trigger"
  end

  def create_tsv_idx_name(tsv_table)
    "#{tsv_table}_tsv_idx"
  end

  def create_tsv_col_list(columns)
    column_list = columns.map { |col| "coalesce(#{col},'')" }.join(' || ')
  end

  def add_tsv_column(tsv_table,tsv_idx_col)
    "ALTER TABLE #{tsv_table} ADD COLUMN #{tsv_idx_col} tsvector"
  end

  def drop_tsv_column(tsv_table, tsv_idx_col)
    "ALTER TABLE #{tsv_table} DROP COLUMN #{tsv_idx_col}"
  end

  def update_tsv_column(tsv_table, tsv_idx_col, tsv_cols_coalesce)
    "UPDATE #{tsv_table} SET #{tsv_idx_col} = to_tsvector('english', #{tsv_cols_coalesce})"
  end

  def create_gin_index(tsv_idx, tsv_table, tsv_idx_col)
    "CREATE INDEX #{tsv_idx} ON #{tsv_table} USING gin(#{tsv_idx_col})"
  end

  def drop_gin_index(tsv_idx)
    "DROP INDEX IF EXISTS #{tsv_idx}"
  end

  def create_tsv_trigger(tsv_trigger, tsv_table, tsv_idx_col, tsv_cols_list)
    "CREATE TRIGGER #{tsv_trigger} BEFORE INSERT OR UPDATE ON #{tsv_table} FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(#{tsv_idx_col}, 'pg_catalog.english', #{tsv_cols_list})" 
  end

  def drop_tsv_trigger(tsv_trigger, tsv_table)
    "DROP TRIGGER IF EXISTS #{tsv_trigger} ON #{tsv_table}"
  end

  def exec_stmt(stmt)
    execute stmt
  end
end
