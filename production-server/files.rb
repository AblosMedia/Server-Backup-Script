#!/usr/bin/env ruby

### Config: temporary directory
output_dir = "/kunden/homepages/4/d376755858/htdocs/sandbox/backup-script-test"

### Config: default exclude patters for `tar` command
excludes = [ ".git", "node_modules" ]

### Config: select directories to backup
d = Hash.new

d["FPSS"] = Hash.new
d["FPSS"]["slug"] = "fpss"
d["FPSS"]["directory"] = "/kunden/homepages/4/d376755858/htdocs/sites/arc-booking-system"
d["FPSS"]["excludes"] = [ "dbs" ]

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
puts "Initialising file backup"
puts "Checking file backup directory exists..."
success = system("mkdir -p #{output_dir}")
if(!success)
	puts ">>>> Error: Problem creating file backup directory <<<<"
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

# Loop over directories and backup
puts "Starting to backup files..."
d.each {
	|key, val|

	# Preparation
	current_output_dir = "#{output_dir}/#{val['slug']}/files"
	success = system("mkdir -p #{current_output_dir}")
	if(!success)
		puts ">>>> Error: Problem creating database backup directory <<<<"
	end

	# Create tarball from directory
	puts "Creating tarball for #{key}..."
	filename = "#{val["slug"]}--files--#{datestamp.strftime("%Y.%m.%d-%H.%M.%S")}"
	command = "tar -zcf"
	command = command + " #{current_output_dir}/#{filename}.tar.gz"
	if(val["excludes"])
		excludes = excludes.concat(val["excludes"]).uniq
	end
	excludes.each {
		|excl|
		command = command + " --exclude='#{excl}'"
	}
	command = command + " #{val["directory"]}"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem creating tarball for #{key}"
		puts ">>>>        filename: #{filename}"
		next
	end 
	puts "Finished creating tarball for #{key}"

}

# Finish
puts "Files backup complete."