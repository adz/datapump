#
# TabularData
# Purpose: Provide generated data
#
# Field
# Purpose: Define a field: name, type and so forth.
#
class Field

  KNOWN_DATA_TYPES = [:integer, :date, :time, :string]

  attr_accessor :name
  attr_reader :data_type

  def initialize(name, opts={})
    self.name = name
    self.data_type = opts[:as]
  end

  def data_type=(data_type)
    raise "Unknown data type '#{data_type}'" unless KNOWN_DATA_TYPES.include?(data_type)
    self.data_type = data_type
  end
  
end

# Data Pump
#
# Generates tabular data in a configurable way.
# Inherit this class to define your own data pump.
# 
# Define a :generate method which generates your data, and a series of
# fields which will be used.
#
# Possible configuration:
# - Fields
#
# Can we automate filtering, sorting and grouping? (in SQL)
#
class DataPump
  class << self

    # Array of field definitions
    attr_accessor :fields

    def field(field_name, opts={})
      self.fields << Field.new(field_name, opts)
    end

    def fields(field_names, opts={})
      field_names.each{|f| field(f, opts)}
    end

    def generating_array_as(field_names)
      self.generating_array_as = field_names
    end
  end

  def generate
    raise "Implement generate method in your class!"
  end
end


class FerryCarriesDataPump < DataPump
  field :travel_date, :as => :date
  field :travel_time, :as => :time
  
  fields :number_of_passengers, :number_of_vehicles, :length_of_vehicles, :as => :integer

  def generate
    generating_array_as(:age, :gender, :count)
    Item.all(
      :select => 'COUNT(*) AS count, age, gender',
      :group  => 'age, gender'
    ).map{|i| [i.age, i.gender, i.count.to_i]}
  end
end

# Report
#
# Configuration for a data pump, saved in an active record.
# You generate the data by calling the :run method.
# 
# The run method take a hash of parameter values -- which are optional values
# you can defined if your report is to be re-used but wants to run slightly
# differently.
# 
# The parameters can be referenced by config :options and :filters.
#
# Configuration includes:
#
#   data_pump => class name of data pump to use
#
#   fields    => fields to display
#
#   options   => hash of arbitrary options
#                is passed to the data pump, using it to change it's operation
#
#   filters   => array filters to apply to data pump
#
#   groups    => multiple levels of grouping to generate
#
#   sort      => array of sort fields
#
# Values used by options and filters are defined as either:
# - an arbitrary constant (like "20")
# - an interpretted value (like "Today" or "> 10")
# - a parameter that is passed to report on :run
# - a list of values (inline, or generated by another data pump?)
#
# Parameters are designed for end user usage and need to know:
# - their type (like Field.data_type)
# - their name
# - their possible values (for data_types :select/:list, generated by a query, etc)
#
class Report
  def initialize(data_pump)
    @data_pump = data_pump
  end

  # set groupings? filters? sorts?
  # then it calls @data_pump.generate
end



r = Report.new
r.data_pump = FerryCarriesDataPump.new
r.group_on
r.