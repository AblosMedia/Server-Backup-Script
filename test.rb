# Config: select databases to backup

d = Hash.new

d["FPSS"] = Hash.new
d["FPSS"]["slug"] = "fpss"
d["FPSS"]["host"] = "localhost" 
d["FPSS"]["name"] = "fpss" 
d["FPSS"]["user"] = "root" 
d["FPSS"]["pass"] = "root"

d["Growing Schools"] = Hash.new
d["Growing Schools"]["slug"] = "grasslandmuck"
d["Growing Schools"]["host"] = "localhost" 
d["Growing Schools"]["name"] = "__grasslandmuck" 
d["Growing Schools"]["user"] = "root" 
d["Growing Schools"]["pass"] = "root"

# Preparation
puts "Starting database backup..."
output_dir = "/Users/harrison/Sites/server-backup-script/output"
puts "Checking database backup directory exists..."
success = system("mkdir -p #{output_dir}")
if(!success)
	puts ">>>> Error: Problem creating database backup directory <<<<"
end

# Loop over databases and backup
d.each {
	|key, val|
	puts "Dumping #{key} (database name: #{val["name"]})..."
	n = Time.now
	filename = "#{val["slug"]}--#{n.strftime("%Y.%m.%d-%H.%M.%S")}"
	command = "mysqldump --no-create-db=true -h #{val["host"]} -u #{val["user"]} -p#{val["pass"]} #{val["name"]} > #{output_dir}/#{filename}.sql"
	success = system(command)
	if(!success)
		puts ">>>> Error: Problem backing up database for #{key}"
		puts ">>>>        host: #{val["host"]}"
		puts ">>>>        name: #{val["name"]}"
		puts ">>>>        user: #{val["user"]}"
		puts ">>>>        pass: #{val["pass"]}"
		puts ">>>>        filename: #{filename}"
	else 
		puts "Compressing #{key}..."
		command = "tar czf #{output_dir}/#{filename}.sql.tar.gz #{output_dir}/#{filename}.sql"
		success = system(command)
		if(!success)
			puts ">>>> Error: Problem compressing database dump file for #{key}"
			puts ">>>>        filename: #{filename}"
		else
			command = "rm #{output_dir}/#{filename}.sql"
			success = system(command)
			if(!success)
				puts ">>>> Error: Problem removing un-compressed database dump file for #{key}"
				puts ">>>>        filename: #{filename}"
			end
		end
	end
	
}