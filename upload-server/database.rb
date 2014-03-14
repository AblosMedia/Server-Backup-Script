#!/usr/bin/env ruby

### Config: Amazon S3 credentials
s3bucket = "mys3bucket"

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

	# Upload new backup
	puts "Uploading new backup for #{key} (filename: #{filename}.sql.tar.gz)..."
	command = "aws s3 cp #{output_dir}/#{filename}.sql.tar.gz s3://#{s3bucket}/#{val['slug']}_database_#{period}/#{filename}.sql.tar.gz"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't upload new backup for #{key}"
	else
		puts "Uploaded new backup for #{key}"
	end

	# Remove local dumps
	puts "Removing local backup file for #{key} (filename: #{filename}.sql.tar.gz)"
	command = "rm #{output_dir}/#{filename}.sql.tar.gz"
	success = system(command)
	if(!success)
		puts ">>>> Error: couldn't remove local backup file for #{key} (filename: #{filename}.sql.tar.gz)"
	else
		puts "Finished removing local backup file #{key} (filename: #{filename}.sql.tar.gz)"
	end