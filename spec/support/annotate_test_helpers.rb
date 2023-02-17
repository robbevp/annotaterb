# frozen_string_literal: true

module AnnotateTestHelpers

  # This method is used to debug flakes/test pollution due to relying on ENV
  # Can remove after the dependency on ENV is removed
  def self.print_annotate_env_values
    keys = Annotate::Constants::ALL_ANNOTATE_OPTIONS.flatten.map(&:to_s)
    pp ENV.to_h.slice(*keys)
  end

  def annotate_one_file(options = {})
    Annotate.instance_variable_set('@has_set_defaults', false)
    Annotate.set_defaults(options)
    options = Annotate.setup_options(options)
    AnnotateModels.annotate_one_file(@model_file_name, @schema_info, :position_in_class, options)

    # Wipe settings so the next call will pick up new values...
    Annotate.instance_variable_set('@has_set_defaults', false)
    Annotate::Constants::POSITION_OPTIONS.each { |key| ENV[key.to_s] = nil }
    Annotate::Constants::FLAG_OPTIONS.each { |key| ENV[key.to_s] = nil }
    Annotate::Constants::PATH_OPTIONS.each { |key| ENV[key.to_s] = nil }
  end

  def write_model(file_name, file_content)
    fname = File.join(@model_dir, file_name)
    FileUtils.mkdir_p(File.dirname(fname))
    File.open(fname, 'wb') { |f| f.write file_content }

    [fname, file_content]
  end

  def mock_index(name, params = {})
    double('IndexKeyDefinition',
           name: name,
           columns: params[:columns] || [],
           unique: params[:unique] || false,
           orders: params[:orders] || {},
           where: params[:where],
           using: params[:using])
  end

  def mock_foreign_key(name, from_column, to_table, to_column = 'id', constraints = {})
    double('ForeignKeyDefinition',
           name: name,
           column: from_column,
           to_table: to_table,
           primary_key: to_column,
           on_delete: constraints[:on_delete],
           on_update: constraints[:on_update])
  end

  def mock_connection(indexes = [], foreign_keys = [])
    double('Conn',
           indexes: indexes,
           foreign_keys: foreign_keys,
           supports_foreign_keys?: true)
  end

  def mock_class(table_name, primary_key, columns, indexes = [], foreign_keys = [])
    options = {
      connection: mock_connection(indexes, foreign_keys),
      table_exists?: true,
      table_name: table_name,
      primary_key: primary_key,
      column_names: columns.map { |col| col.name.to_s },
      columns: columns,
      column_defaults: Hash[columns.map { |col| [col.name, col.default] }],
      table_name_prefix: ''
    }

    double('An ActiveRecord class', options)
  end

  def mock_column(name, type, options = {})
    default_options = {
      limit: nil,
      null: false,
      default: nil,
      sql_type: type
    }

    stubs = default_options.dup
    stubs.merge!(options)
    stubs[:name] = name
    stubs[:type] = type

    double('Column', stubs)
  end
end