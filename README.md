# fingerprinting

For instructions, check out this [cool blog post](https://privatezero.github.io/weaverblog/2017/12/12/Return-to-perceptual-hashing.html)!

## Current Notes
Must have FFmpeg and MySQL installed.

From the project directory, run `./createfingerprintdb.sh` and follow __all__ directions. This will generate a database and user, create the config file and provide the command that must be entered to create the login profile.

The database can then be added to and queried with the included scripts.

Current experiments store only the first hash of the `bagofwords` rough hashes and then use [hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) to search for matches.
