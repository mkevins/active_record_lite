require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    .first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    self.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
  end

  def self.parse_all(results)
    results.map { |record| self.new(record)}
  end

  def self.find(id)
    self.parse_all(DBConnection.execute(<<-SQL, id)).first
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    columns = self.class.columns
    column_names = columns.join(", ")
    question_marks = columns.map { "?" }.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{column_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
