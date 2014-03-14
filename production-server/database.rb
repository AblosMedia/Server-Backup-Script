#!/usr/bin/env ruby

### Config: temporary directory
output_dir = "/path/to/dir"

### Config: select databases to backup
d = Hash.new

d["MySiteName"] = Hash.new
d["MySiteName"]["slug"] = "myslug"
d["MySiteName"]["host"] = "myhost"
d["MySiteName"]["name"] = "myname"
d["MySiteName"]["user"] = "myuser"
d["MySiteName"]["pass"] = "mypass"

### END Config

## -------- Don't edit below this line -------- ##

# Parse options (eg. "ruby test.rb --period monthly")
require 'optparse'
require 'yaml'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-p', '--period PERIOD', 'Period') { |v| options[:period] = v }
end.parse!

# Preparation
puts "Initialising database backup"
puts "Checking database backup directory exists..."
success = system("mkdir -p #{output_dir}")
if(!success)
	puts ">>>> Error: Problem creating database backup directory <<<<"
end

# Datestamping
datestamp = Time.now
day = datestamp.strftime("%d")
dayofweek = datestamp.strftime("%A")
# If script has period option passed into it, use that
if( options[:period] and ( options[:period]=='month' or options[:period]=='week' or options[:period]=='day' ) )
	period = options[:period]
# Otherwise, automatically figure out the period of backup
else 
	if(day=="01")
		period = "month"
	elsif(dayofweek=="Sunday")
		period = "week"
	else
		period = "day"
	end
end
puts "Selected period: #{period}"

# Loop over databases and backup
puts "Starting to backup databases..."
d.each {
	|key, val|

	# Dump database file
	puts "Dumping #{key} (database name: #{val["name"]})..."
	filename = "#{val["slug"]}--#{datestamp.strftime("%Y.%m.%d-%H.%M.%S")}"
	command = "mysqldump --no-create-db=true -h #{val["host"]} -u #{val["user"]} -p#{val["pass"]} #{val["name"]} > #{output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem backing up database for #{key}"
		puts ">>>>        host: #{val["host"]}"
		puts ">>>>        name: #{val["name"]}"
		puts ">>>>        user: #{val["user"]}"
		puts ">>>>        pass: #{val["pass"]}"
		puts ">>>>        filename: #{filename}"
		next
	end 
	puts "Finished dumping #{key} (database name: #{val["name"]})"

	# Compress dump
	puts "Compressing #{key}..."
	command = "tar -zcf #{output_dir}/#{filename}.sql.tar.gz #{output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem compressing database dump file for #{key}"
		puts ">>>>        filename: #{filename}"
		next
	end
	puts "Finished compressing #{key}"

	# Remove un-compressed dump
	puts "Removing un-compressed #{key}..."
	command = "rm #{output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem removing un-compressed database dump file for #{key}"
		puts ">>>>        filename: #{filename}"
	end
	puts "Finished removing un-compressed #{key}"

}

# Finish
puts "Database backup complete."