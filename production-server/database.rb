#!/usr/bin/env ruby

### Config: temporary directory
output_dir = "/kunden/homepages/4/d376755858/htdocs/sandbox/backup-script-test"

### Config: select databases to backup
d = Hash.new

d["FPSS"] = Hash.new
d["FPSS"]["slug"] = "fpss"
d["FPSS"]["host"] = "db463948363.db.1and1.com"
d["FPSS"]["name"] = "db463948363"
d["FPSS"]["user"] = "dbo463948363"
d["FPSS"]["pass"] = "hom4gaig"

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

	# Preparation
	current_output_dir = "#{output_dir}/#{val['slug']}/db"
	success = system("mkdir -p #{current_output_dir}")
	if(!success)
		puts ">>>> Error: Problem creating database backup directory <<<<"
	end

	# Remove old database backup files
	puts "Removing old database backup files..."
	success = system("rm -r #{output_dir}/#{val['slug']}/db/*")
	if(!success)
		puts ">>>> Error: Problem removing old database backup files <<<<"
	end

	# Dump database file
	puts "Dumping #{key} (database name: #{val["name"]})..."
	filename = "#{val["slug"]}--dbs--#{datestamp.strftime("%Y.%m.%d-%H.%M.%S")}"
	command = "mysqldump --no-create-db=true -h #{val["host"]} -u #{val["user"]} -p#{val["pass"]} #{val["name"]} > #{current_output_dir}/#{filename}.sql"
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
	command = "tar -zcf #{current_output_dir}/#{filename}.sql.tar.gz #{current_output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem compressing database dump file for #{key}"
		puts ">>>>        filename: #{filename}"
		next
	end
	puts "Finished compressing #{key}"

	# Remove un-compressed dump
	puts "Removing un-compressed #{key}..."
	command = "rm #{current_output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem removing un-compressed database dump file for #{key}"
		puts ">>>>        filename: #{filename}"
	end
	puts "Finished removing un-compressed #{key}"

}

# Finish
puts "Database backup complete."