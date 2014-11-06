require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # ...
    @class_name.to_s.camelcase.constantize
  end

  def table_name
    # ...
    "#{@class_name.to_s.downcase}s"
  end
end

#String#camelcase,String#singularize, String#underscore

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    # ...
    @foreign_key = (options[:foreign_key] || "#{name}_id".to_sym)
    @primary_key = (options[:primary_key] || :id)
    @class_name = (options[:class_name] || "#{name.to_s.singularize.camelcase}")
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # ...
    @foreign_key = (options[:foreign_key] || "#{self_class_name.downcase.underscore}_id".to_sym)
    @primary_key = (options[:primary_key] || :id)
    @class_name = (options[:class_name] || "#{name.singularize.camelcase}")
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    table = options.table_name

    define_method(name) do
      p self
      query =<<-SQL
      SELECT *
      FROM #{table}
      WHERE #{self.send(options.foreign_key)} = #{id}
      SQL
      options.class_name.constantize.new(DBConnection.execute(query).first)

    end

  end

  def has_many(name, options = {})
    # # ...

    options = HasManyOptions.new(name.to_s, self.to_s, options)
    table = options.table_name

    define_method(name) do
      p self
      p table
      query =<<-SQL
        SELECT * --cats
        FROM #{table} --from cats
        WHERE #{options.foreign_key} = #{self.id}
      SQL
      Cat.new(DBConnection.execute(query))
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
