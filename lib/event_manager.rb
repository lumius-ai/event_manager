require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

require 'algorithms'

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

  #Dicts for the day and hour stats
  hours = Hash.new(0)
  days = Hash.new(0)

  # Min heaps for the day and hour entries
  max_hours = Containers::MaxHeap.new()
  max_days = Containers::MaxHeap.new()
  
  content.each do |row|
    name = row[:first_name]
    id = row[0]

    # Zipcode handling
    zipcode = clean_zipcode_2(row[:zipcode])
    
    # Get legislators
    # legislators = legislators_by_zipcode(zipcode)

    # Generate and save form letter
    # form_letter = erb_template.result(binding)
    # save_thank_you_letter(id, form_letter)
    # ----------------------------------------

    # Phone number handling
    phone_number = clean_HomePhone(row[:homephone])

    # Add sign up day and hour to list
    days[get_date(row[:regdate])] += 1
    hours[get_time(row[:regdate]).hour.to_s] += 1
  end
  max_hours = max_heapify(hours)
  max_days = max_heapify(days)
  puts("The most frequent hour for sign ups is #{max_hours.pop}:00, the most frequent day of signups is #{max_days.pop}")
  puts("The most frequent hour for sign ups is #{hours.key(hours.values.max)}:00, the most frequent day of signups is #{days.key(days.values.max)}")
end

# Convert dictionary elements to max heap
def max_heapify(dict)
  max_heap = Containers::MaxHeap.new

  dict.each_pair do |string, number|
    max_heap.push(number, string)
  end
  return max_heap
end

# Creates a Time object out of a regdate reading
def get_time(regdate)
  time = Time.strptime(regdate, '%m/%d/%Y %k:%M')
  return time
end
# Creates a Date object out of a regdate readinf
def get_date(regdate)
  date = Date.strptime(regdate.split(" ")[0], '%m/%d/%Y')
  date = Date::DAYNAMES[date.wday]
  return date
end
# Cleans given phone number
def clean_HomePhone(phone_number)
  # Gives just digits
  pn = digits_only(phone_number.to_s)
  if pn.length > 11 or pn.length < 10
    return 'Invalid Number'
  elsif pn.length == 11
    pn[0] == '1' ? pn[1..11] : 'Invalid Number'
  else
    return pn
  end
end

# Returns only the digits of the number, no '-' or spaces
def digits_only(phone_number)
  number = phone_number.split('-')
  number = number.join()
  number = number.split(" ")
  number = number.join()
  return number
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