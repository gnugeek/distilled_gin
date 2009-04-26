module DistilledGinMigrations

  def add_gin_index(tsv_table, *tsv_cols)
    tsv_idx_col = create_tsv_idx_col_name(tsv_table)
    tsv_trigger = create_tsv_trigger_name(tsv_table)
    tsv_idx = create_tsv_idx_name(tsv_table)
    tsv_cols_coalesce = create_tsv_col_list(tsv_cols)
    tsv_cols_list = tsv_cols.join(',')

    exec_stmt alter_table_add_column(tsv_table, tsv_idx_col)
    exec_stmt update_table_set_column(tsv_table, tsv_idx_col, tsv_cols_coalesce)
    exec_stmt create_gin_index(tsv_idx, tsv_table, tsv_idx_col)
    exec_stmt create_tsvector_update_trigger(tsv_trigger, tsv_table, tsv_idx_col, tsv_cols_list)
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

  def alter_table_add_column(tsv_table,tsv_idx_col)
    "ALTER TABLE #{tsv_table} ADD COLUMN #{tsv_idx_col} tsvector"
  end

  def update_table_set_column(tsv_table, tsv_idx_col, tsv_cols_coalesce)
    "UPDATE #{tsv_table} SET #{tsv_idx_col} = to_tsvector('english', #{tsv_cols_coalesce})"
  end

  def create_gin_index(tsv_idx, tsv_table, tsv_idx_col)
    "CREATE INDEX #{tsv_idx} ON #{tsv_table} USING gin(#{tsv_idx_col})"
  end

  def create_tsvector_update_trigger(tsv_trigger, tsv_table, tsv_idx_col, tsv_cols_list)
    "CREATE TRIGGER #{tsv_trigger} BEFORE INSERT OR UPDATE ON #{tsv_table} FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger(#{tsv_idx_col}, 'pg_catalog.english', #{tsv_cols_list})" 
  end

  def exec_stmt(stmt)
    execute stmt
  end
end
