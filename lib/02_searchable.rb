require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?" }

    query = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line.join(' AND ')}
    SQL

    return_objects = []
    DBConnection.execute(query, params.values).each do |obj|
      return_objects << self.new(obj)
    end
    return_objects
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
