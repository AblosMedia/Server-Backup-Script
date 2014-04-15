#!/usr/bin/env ruby

### Config: alerts email
email = "your@email.com"

### Config: temporary directory
output_dir = "/path/to/scripts/fetched-files"

### Config: select file dumps to backup
d = Hash.new

d["Your Site Name"] = Hash.new
d["Your Site Name"]["slug"] = "yoursiteslug"
d["Your Site Name"]["remote_user"] = "username"
d["Your Site Name"]["remote_host"] = "ssh_or_ip"
d["Your Site Name"]["remote_dir"] = "/remote/path/to/output_files/yoursiteslug" # This will probably match your local slug, but not necessarily

### Config: Amazon S3 credentials
s3bucket = "your-s3-bucket-name"

### END Config

## -------- Don't edit below this line -------- ##

# Alert user
current_time = Time.now.strftime("%Y-%d-%m %H:%M")
#`echo 'Running backup (without S3 upload) of Stoneleigh files on #{current_time}' | mail -s 'Running backup (without S3 upload) of Stoneleigh files on #{current_time}' '#{email}'`

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

# Loop over files and backup
puts "Starting to backup files..."
d.each {
	|key, val|

	puts ""
	puts "★ Starting to backup: " + key

	# Check we have directories to move files around in
	success = system("mkdir -p #{output_dir}/#{val['slug']}_files_#{period}; touch #{output_dir}/#{val['slug']}_files_#{period}/keepfile")
	if(!success)
		puts ">>>> Error: Problem creating files current backup directory <<<<"
		`echo 'Error creating current backup directory for #{key}' | mail -s 'Error creating previous backup directory for #{key}' '#{email}'`
		next
	end
	success = system("mkdir -p #{output_dir}/#{val['slug']}_files_previous_#{period}; touch #{output_dir}/#{val['slug']}_files_previous_#{period}/keepfile")
	if(!success)
		puts ">>>> Error: Problem creating files previous backup directory <<<<"
		`echo 'Error creating previous backup directory for #{key}' | mail -s 'Error creating previous backup directory for #{key}' '#{email}'`
		next
	end

	# Remove old local backups
	puts "Removing old backups for #{key} (2 #{period}s ago)..."
	command = "rm -R #{output_dir}/#{val['slug']}_files_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove old backups for #{key} (2 #{period}s ago)"
		`echo 'Error moving old backups for #{key} (2 #{period}s ago)' | mail -s 'Error moving old backups for #{key} (2 #{period}s ago)' '#{email}'`
		next
	else
		puts "↪ Old backup removed"
	end

	# Move previous backup into previous_ folder
	puts "Moving existing backup from past #{period} to previous folder..."
	## Check we have a directory to move files into
	success = system("mkdir -p #{output_dir}/#{val['slug']}_files_previous_#{period}")
	if(!success)
		puts ">>>> Error: Problem creating files backup directory <<<<"
		`echo 'Error creating previous backup directory for #{key}' | mail -s 'Error creating previous backup directory for #{key}' '#{email}'`
		next
	end
	## Move files
	command = "mv #{output_dir}/#{val['slug']}_files_#{period}/* #{output_dir}/#{val['slug']}_files_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't move existing backup for #{key} (1 #{period}s ago)"
		`echo 'Error moving existing backup for #{key} (1 #{period}s ago)' | mail -s 'Error moving existing backup for #{key} (1 #{period}s ago)' '#{email}'`
		next
	else
		puts "↪ Existing backup moved to 'previous' folder"
	end

	# Fetch  backup files from remote server
	puts "Fetching file from remote server"
	## Find the latest file on the server
	output = `ssh -t #{val['remote_user']}@#{val['remote_host']} "cd #{val['remote_dir']}/files; ls -t | head -n1"` ;  result=$?.success?
	if(!result or output.length == 0)
		puts ">>>> Error: couldn't find any backup files on remote to fetch #{key}"
		`echo 'Error locating backup files on remote for #{key}' | mail -s 'Error locating backup files on remote for #{key}' '#{email}'`
		next
	else
		filename = output
		puts "↪ Backup file is " + filename
	end
	## Copy latest file to local directory
	command = "scp #{val['remote_user']}@#{val['remote_host']}:#{val['remote_dir']}/files/#{filename} #{output_dir}/#{val['slug']}_files_#{period}/#{filename}"
	command = command.gsub(/\r/," ")
	command = command.gsub(/\n/," ")
	result = system(command)
	if(!result)
		puts ">>>> Error: failed to copy backup file from remote for #{key}"
		`echo 'Error copying backup files from remote for #{key}' | mail -s 'Error copying backup files from remote for #{key}' '#{email}'`
		next
	else
		puts "↪ Copied backup file from server"
	end

	# # Find most recent (now local) backup files to upload
	# output = `ls -t #{output_dir}/#{val['slug']}/files | head -n1` ;  result=$?.success?
	# if(!result or output.length == 0)
	# 	puts ">>>> Error: couldn't find any local files ready to upload for #{key}"
	# 	`echo 'Error finding local files to upload for #{key}' | mail -s 'Error finding local files to upload for #{key}' '#{email}'`
	# 	next
	# else
	# 	filename = output
	# 	puts "file is " + filename
	# end

	# # Upload new backup
	# puts "Uploading new backup for #{key} (filename: #{filename})..."
	# command = "aws s3 cp #{output_dir}/#{val['slug']}/files/#{filename} s3://#{s3bucket}/#{val['slug']}_files_#{period}/#{filename}"
	# command = command.gsub(/\r/," ")
	# command = command.gsub(/\n/," ")
	# success = system(command)
	# if(!success)
	# 	puts ">>>> Error: couldn't upload new backup for #{key}"
	# 	`echo 'Error uploading backup files for #{key}' | mail -s 'Error uploading backup files for #{key}' '#{email}'`
	# 	next
	# else
	# 	puts "Uploaded new backup for #{key}"
	# end

	# # Remove local dumps
	# puts "Removing local backup file for #{key} (filename: #{filename})"
	# command = "rm #{output_dir}/#{val['slug']}/files/#{filename}"
	# success = system(command)
	# if(!success)
	# 	puts ">>>> Error: couldn't remove local backup file for #{key} (filename: #{filename})"
	# 	`echo 'Error removing local backup files for #{key}' | mail -s 'Error removing local backup files for #{key}' '#{email}'`
	# 	next
	# else
	# 	puts "Finished removing local backup file #{key} (filename: #{filename})"
	# end

	# Alert user
	puts "✔ File backup successfully taken (without S3 upload) for #{key} on #{current_time}. Filename: #{filename}"
	#`echo 'File backup successfully taken (without S3 upload) for #{key} on #{current_time}. Filename: #{filename}' | mail -s 'File backup successfully taken (without S3 upload) for #{key} on #{current_time}. Filename: #{filename}' '#{email}'`

}

puts ""