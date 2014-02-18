#!/usr/bin/env ruby

### Config: Amazon S3 credentials
s3bucket = "mys3bucket"

### Config: temporary directory
output_dir = "/path/to/dir"

### Config: default exclude patters for `tar` command
excludes = [ ".git", "node_modules" ]

### Config: select directories to backup
d = Hash.new

d["MySiteName"] = Hash.new
d["MySiteName"]["slug"] = "myslug"
d["MySiteName"]["directory"] = "/path/to/dir"
d["MySiteName"]["excludes"] = [ "myfirstexcludepattern", "mysecondexcludepattern" ]

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

	# Create tarball from directory
	puts "Creating tarball for #{key}..."
	filename = "#{val["slug"]}--#{datestamp.strftime("%Y.%m.%d-%H.%M.%S")}"
	command = "tar -zcf"
	command = command + " #{output_dir}/#{filename}.tar.gz"
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

	# Remove old S3 backups
	puts "Removing old backups for #{key} (2 #{period}s ago)..."
	command = "aws s3 rm --recursive s3://#{s3bucket}/#{val['slug']}_files_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove old backups for #{key} (2 #{period}s ago)"
	else
		puts "Old backup removed"
	end

	# Move previous backup into previous_ folder
	puts "Moving existing backup from past #{period} to previous folder..."
	command = "aws s3 mv --recursive s3://#{s3bucket}/#{val['slug']}_files_#{period} s3://#{s3bucket}/#{val['slug']}_files_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't move existing backup for #{key} (1 #{period}s ago)"
	else
		puts "Previous backup moved"
	end

	# Upload new backup
	puts "Uploading new backup for #{key} (filename: #{filename}.tar.gz)..."
	command = "aws s3 cp #{output_dir}/#{filename}.tar.gz s3://#{s3bucket}/#{val['slug']}_files_#{period}/#{filename}.tar.gz"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't upload new backup for #{key}"
	else
		puts "Uploaded new backup for #{key}"
	end

	# Remove local dumps
	puts "Removing local backup file for #{key} (filename: #{filename}.tar.gz)"
	command = "rm #{output_dir}/#{filename}.tar.gz"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove local backup file for #{key} (filename: #{filename}.tar.gz)"
	else
		puts "Finished removing local backup file #{key} (filename: #{filename}.tar.gz)"
	end

}

# Finish
puts "Files backup complete."