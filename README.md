# fingerprinting


## Current Notes
Must have FFmpeg and MySQL installed.

From the project directory, run `./createfingerprintdb.sh` and follow __all__ directions. This will generate a database and user, create the config file and provide the command that must be entered to create the login profile.

The database can then be added to and queried with the included scripts.

Current experiments store only the first hash of the `bagofwords` rough hashes and then use [hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) to search for matches.

## In the event of an error   

If you receive the error `Column count of mysql.user is wrong.`:  

It means you need to update MySQL. Run `mysql_upgrade -u root -p` and re-open your window if necessary. MySQL may need to be manually restarted as a system service.  
