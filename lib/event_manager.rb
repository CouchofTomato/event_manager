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
	telephone.split("").each {|num| num.gsub!(/[^0-9]/, '')}.join('').to_i
end

def can_sign_for_text_service?(telephone)
	return true if telephone.length == 10
	return true if telephone.length == 11 && telephone.split("")[0].to_i == 1
	return false
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

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	zipcode = clean_zipcode(row[:zipcode])
	legislators = legislators_by_zipcode(zipcode)
	telephone = clean_telephone(row[:homephone])
	text_service = can_sign_for_text_service?(telephone.to_s)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id,form_letter)

end