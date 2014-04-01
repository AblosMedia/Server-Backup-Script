#!/usr/bin/env ruby

### Config: temporary directory
output_dir = "/Users/Harrison/Sites/Server-Remote-Uploader-Backup-Script/upload-server/fetched-files"

### Config: select databases to backup
d = Hash.new

d["FPSS"] = Hash.new
d["FPSS"]["slug"] = "fpss"
d["FPSS"]["remote_user"] = "u64583749"
d["FPSS"]["remote_host"] = "s376755885.websitehome.co.uk"
d["FPSS"]["remote_dir"] = "/kunden/homepages/4/d376755858/htdocs/sandbox/backup-script-test/fpss"

### Config: Amazon S3 credentials
s3bucket = "stoneleigh-multi-server-test"

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
	# Remove old S3 backups
	puts "Removing old backups for #{key} (2 #{period}s ago)..."
	command = "aws s3 rm --recursive s3://#{s3bucket}/#{val['slug']}_database_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove old backups for #{key} (2 #{period}s ago)"
	else
		puts "Old backup removed"
	end

	# Move previous backup into previous_ folder
	puts "Moving existing backup from past #{period} to previous folder..."
	command = "aws s3 mv --recursive s3://#{s3bucket}/#{val['slug']}_database_#{period} s3://#{s3bucket}/#{val['slug']}_database_previous_#{period}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't move existing backup for #{key} (1 #{period}s ago)"
	else
		puts "Previous backup moved"
	end

	# Fetch  backup files from remote server
	## Check we have a directory to work into
	success = system("mkdir -p #{output_dir}/#{val['slug']}/db")
	if(!success)
		puts ">>>> Error: Problem creating database backup directory <<<<"
		next
	end
	## Find the latest file on the server
	output = `ssh -t #{val['remote_user']}@#{val['remote_host']} "cd #{val['remote_dir']}/db; ls -t | head -n1"` ;  result=$?.success?
	if(!result or output.length == 0)
		puts ">>>> Error: couldn't find any local files ready to upload for #{key}"
		next
	else
		filename = output
		puts "file is " + filename
	end
	## Copy latest file to local directory
	command = "scp #{val['remote_user']}@#{val['remote_host']}:#{val['remote_dir']}/db/#{filename} #{output_dir}/#{val['slug']}/db/#{filename}"
	command = command.gsub(/\r/," ")
	command = command.gsub(/\n/," ")
	result = system(command)
	if(!result)
		puts ">>>> Error: failed to copy backup file from remote for #{key}"
		next
	else
		puts "Copied backup from server"
	end

	# Find most recent (now local) backup files to upload
	output = `ls -t #{output_dir}/#{val['slug']}/db | head -n1` ;  result=$?.success?
	if(!result or output.length == 0)
		puts ">>>> Error: couldn't find any local files ready to upload for #{key}"
		next
	else
		filename = output
		puts "file is " + filename
	end

	# Upload new backup
	puts "Uploading new backup for #{key} (filename: #{filename})..."
	command = "aws s3 cp #{output_dir}/#{val['slug']}/db/#{filename} s3://#{s3bucket}/#{val['slug']}_database_#{period}/#{filename}"
	command = command.gsub(/\r/," ")
	command = command.gsub(/\n/," ")
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't upload new backup for #{key}"
		next
	else
		puts "Uploaded new backup for #{key}"
	end

	# Remove local dumps
	puts "Removing local backup file for #{key} (filename: #{filename})"
	command = "rm #{output_dir}/#{val['slug']}/db/#{filename}"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove local backup file for #{key} (filename: #{filename})"
		next
	else
		puts "Finished removing local backup file #{key} (filename: #{filename})"
	end

}