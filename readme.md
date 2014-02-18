# Amazon S3 backup script

## Setup

1. Install Amazon's AWS command line interface (http://aws.amazon.com/cli/)
2. Configure AWS credentials with `aws configure`
3. Give 755 permissions to `.rb` files
4. Edit the config variables at the top of `.rb` files
5. Set `.rb` files to run on a schedule with cron. By default the scripts will backup the current and previous daily, weekly, and monthly snapshots. If you want to manually define daily, weekly, and monthly backups with separate cron jobs you can also pass in the `--period` or `-p` option to specify which type of backup you're running. Eg. `ruby database.rb -p week`. The options are `day`, `week`, and `month`.