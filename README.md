## csv2json

csv2json is a fast utility that converts CSV files into JSON line files.

*This is my first "hello, world" [Zig](https://ziglang.org) learning exercise. The program may be buggy and/or faulty. Use with caution.*


### Usage
```shell
# Intel(R) Core(TM) i7-10510U CPU @ 1.80GHz.
#
# 92 MB CSV file with 1 million rows. Sample:
# instrument_token,exchange_token,tradingsymbol,isin,name,last_price,expiry,strike,tick_size,lot_size,instrument_type,segment,exchange
# 272376070,1063969,"EURINR21DECFUT","","EURINR",0,"2021-12-29",0,0.0025,1,"FUT","BCD-FUT","BCD"
# ...

$ ./csv2json -i /tmp/1mil.csv > /tmp/1mil.json
Reading /tmp/1mil.csv ...
Processed 1000000 lines in 884.61 milliseconds (1000000.00 lines / second)

$ head -n /tmp/1mil.json
{"instrument_token": 272376070, "exchange_token": 1063969, "tradingsymbol": "EURINR21DECFUT", "isin": null, "name": "EURINR", "last_price": 0, "expiry": "2021-12-29", "strike": 0, "tick_size": "0.0025", "lot_size": 1, "instrument_type": "FUT", "segment": "BCD-FUT", "exchange": "BCD"}
{"instrument_token": 272086278, "exchange_token": 1062837, "tradingsymbol": "EURINR21NOVFUT", "isin": null, "name": "EURINR", "last_price": 0, "expiry": "2021-11-26", "strike": 0, "tick_size": "0.0025", "lot_size": 1, "instrument_type": "FUT", "segment": "BCD-FUT", "exchange": "BCD"}
```

### Download
Download the latest release from the [releases](https://github.com/knadh/csv2json/releases) page.

Or, to compile with Zig (tested with v0.11.0):
- `git clone git@github.com:knadh/csv2json.git`
- `cd csv2json && zig build`
- The binary will be in `zig-out/bin`


Licensed under the MIT license.
