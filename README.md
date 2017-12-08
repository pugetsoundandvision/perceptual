# fingerprinting


## Current Notes
Split each rough hash component into 9 chunks 27 characters long -> Convert each chunk to decimal -> store decimal chunks in database.

Query for hamming distance SELECT BITE_COUNT(QueryChunkDecimal1 ^ HashChunkDecimal1) + BITE_COUNT(QueryChunkDecimal2 ^ HashChunkDecimal2) ...


Useful Link about [speed](https://stackoverflow.com/questions/9606492/hamming-distance-similarity-searches-in-a-database)
