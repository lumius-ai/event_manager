require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

# CSVs we're working with
small = "event_attendees.csv"
large = "event_attendees_full.csv"



# Iteration 1, parsing csv using the CSV library
def one_iteration(infile)

  content = CSV.open(infile, 
  headers: true,
  header_converters: :symbol
  )

  # ERB template
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new(template_letter)

  content.each do |row|
    name = row[:first_name]
    id = row[0]

    # Zipcode handling
    zipcode = clean_zipcode_2(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    # Generate and save form letter
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
    # Creating specific letter
    # personal_letter = template_letter.gsub('FIRST_NAME', name)
    # personal_letter = personal_letter.gsub!('LEGISLATORS', legislators)
  end
end

# Generate a thank you letter
def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  file_name = "output/thanks_#{id}.html"

  File.open(file_name, 'w') do |file|
    file.puts(form_letter)
  end
end

# Return string of legislators given a zip code
def legislators_by_zipcode(zipcode)
  # Civic info API
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new()
  civic_info.key = File.read('secret.key').strip

  begin
    # Get each person's local representative
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    # This is an array?
    legislators = legislators.officials

    legislator_names = legislators.map(&:name)
    legislator_string = legislator_names.join(", ")
  rescue
    return 'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials\n'
  end
  return legislator_string
end
# Zipcode cleaning method 
def clean_zipcode(zipcode)
  # Handling incorrect length
  if zipcode.nil?
    zipcode = '00000'
  elsif zipcode.length < 5
    zipcode = zipcode.rjust(5, '0')
  elsif zipcode.length > 5
    zipcode = zipcode[0..4]
  end
  return zipcode
end

# Zipcode cleaner 2 (more succinct) coercion over questions
def clean_zipcode_2(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

# Iteration 0, manually reading through a csv file
def zero_iteration(infile)
  # Basic file opening
  # File.exist?(infile) ? content = File.read(infile) : puts("File #{infile} not found in this directory") && return

  File.exist?(infile) ? lines = File.readlines(infile): puts("File #{infile} not found in this directory") && return
  lines.each_with_index do |line, index|
    next if index == 0
    columns = line.split(',')
    p columns
  end
end


one_iteration(small)