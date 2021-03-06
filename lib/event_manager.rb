require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def clean_telephone(telephone)
	new_num = telephone.to_s.split("").each {|num| num.gsub!(/[^0-9]/, '')}.join('')
	if new_num.length == 11
		if new_num[0].to_i == 1
			new_num = new_num[1..-1]
		end
	end
	new_num.to_i
end

def can_sign_for_text_service?(telephone)
	telephone.length == 10 ? true : false
end

def parse_date(date)
	DateTime.strptime(date, '%m/%d/%Y %H:%M')
end

def save_thank_you_letters(id,form_letter)
	Dir.mkdir("output") unless Dir.exists? ("output")

	filename = "output/thanks_#{id}.html"

	File.open(filename, 'w') do |file|
		file.puts form_letter
	end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours = Hash.new(0)
weekdays = Hash.new(0)

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	zipcode = clean_zipcode(row[:zipcode])
	legislators = legislators_by_zipcode(zipcode)
	telephone = clean_telephone(row[:homephone])
	text_service = can_sign_for_text_service?(telephone.to_s)
	hour_registered = parse_date(row[:regdate]).hour
	weekday_registered = parse_date(row[:regdate]).wday
	hours[hour_registered] += 1
	weekdays[weekday_registered] += 1

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id,form_letter)

end

sorted_hours = hours.sort_by {|key, value| value}.reverse.to_h
sorted_hours.each {|key, value| puts "#{key}: #{value}"}
puts
sorted_weekdays = weekdays.sort_by{|key, value| value}.reverse.to_h
sorted_weekdays.each {|key, value| puts "#{key}: #{value}"}