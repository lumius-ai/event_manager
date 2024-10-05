require 'csv'

# CSVs we're working with
small = "event_attendees.csv"
large = "event_attendees_full.csv"

# Iteration 0, manually reading through a csv file
def zero_iteration(infile)
  File.exist?(infile) ? content = File.read(infile) : puts("File #{infile} not found in this directory") && return

  lines = File.readlines(infile)
  lines.each_with_index do |line, index|
    next if index == 0
    columns = line.split(',')
    p columns
  end
end

# Iteration 1, parsing csv using the CSV library
def one_iteration(infile)
  content = CSV.open(infile, 
  headers: true,
  header_converters: :symbol
  )
  content.each do |row|
    name = row[:first_name]
    puts name
  end
end

one_iteration(small)