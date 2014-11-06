require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
      return @columns if @columns
      @columns = DBConnection.execute2(<<-SQL).first.map { |sym| sym.to_sym }
      SELECT
        *
      FROM
        #{table_name}
        SQL
  end


  def self.finalize!
    self.columns.each do |name|
      define_method(name) do
        attributes[name]
      end

      define_method("#{name}=") do |val|
        attributes[name] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name
      @table_name
    else
      self.to_s.tableize
    end
  end

  def self.all
    # ...
    query = <<-SQL
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    results = DBConnection.execute(query)

    parse_all(results)
  end

  def self.parse_all(results)
    all_objects = []

    results.each do |params|
      all_objects << self.new(params)
    end

    all_objects
  end

  def self.find(id)
    #...That would be inefficient: we'd fetch all the records from the DB. Instead, write a new SQL query that will fetch at most one record.
    query = <<-SQL
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      id = #{id}
    SQL

    self.new(DBConnection.execute(query).first)
  end

  def initialize(params = {})
    column_array = self.class.columns
    params.each_pair do |attr_name, value|
      unless column_array.include?(attr_name.to_sym)
        raise "unknown attribute \'#{attr_name}\'"
      end
      attributes[attr_name.to_sym] = value
      # self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| self.send("#{col}") }
  end

  def insert
    col_names = self.class.columns.map { |col| col.to_s }
    question_array = Array.new(col_names.length, "?").join(', ')

    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names.join(', ')})
    VALUES
      (#{question_array})
    SQL

    DBConnection.execute(query, attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names_set = self.class.columns.map { |col| "#{col} = ?" }

    query = <<-SQL
    UPDATE
      #{self.class.table_name}
    SET
      #{col_names_set.join(', ')}
    WHERE
      id = ?
    SQL

    DBConnection.execute(query, attribute_values, self.id)
  end

  def save
    self.id.nil? ? insert : update 
  end
end
