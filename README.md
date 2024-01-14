# WealthsimpleRubyClient

## What is it and what does it?

This is a small Ruby library to download data about your Wealthsimple cash account. It supports both creation of a full XLSX file with all the data and a much more compact CSV with only settled transactions.
- The XLSX is helpful to get as much details as you can about what is going with your money. Examples: are my transactions settled? what did I spend and when? why am I wasting time trying to scroll the list through the app?
- The CSV is useful if you have a software to monitor your expenses (i.e.: Firefly III) and you want to import the data

**/rant mode ON**

## Why did you implement it?
Wealthsimple doesn't provide a way to export data, doesn't provide official APIs and doesn't disclose their GraphQL schema. This code is a terrible implementation of a semi-GraphQL client without knowing their schema. The reverse engineering could have been done in a better way but it works. If you have a better way and wish to improve the code you are the most welcome doing so!

If you try to contact support asking for at least an unofficial statement, -if you are lucky- you will get a PDF containing an incomplete history with a bunch of transactions showing only an internal ID. No descriptions. It could not be less useful and hard to obtain.

## Quirks and implementation challenges
The code implements a lot of workarounds (see lib/items.rb and generate_export method in lib/wealthsimple_ruby_client.rb) to be able to successfully reconstruct the correct transaction list. A lot of data is redundant or completely missing so I had implement ways to get a meaningful and consistent export.

In case you decide to improve the code, be aware that to generate a simple export at this stage this library needs to invoke **EIGHT different queries** against the GraphQL endpoint involving a lot of post-processing. I want to hope Wealthsimple has a -simple- way to do this internally but so far this is the only known way. Investigating the app traffic requires a considerable amount of setup and effort because of the restrictions in their code (e.g.: code scrambling, SSL certificate pinning)

UPDATE: It seems like finally Wealthsimple added a new GraphQL endpoint which returns all the transactions. Obviously it does not work for a full export but only for data including and after 2023-04-01. Unsurprisingly, all the other fixes that seem to still working without problems for older data don't work for more recent transactions.

### Disclaimer for Wealthsimple
If you are a Wealthsimple employee, save your time reading this horrible code and please provide a proper way to export the transactions like any other bank in the entire planet does. I'd be more than happy to remove this code and any reference to your app/apis/models/etc if you would allow so. The intent is not to get around legal limitations (i.e.: trading) but just providing a simple way to understand what and how we spend our own money with the cash account you provide.

Currently, the only way you allow to see this data is through the app. However, beside being extremely inconvenient and unusable after using the account for a while it has an incredible amount of BUGS. This is a list of things I noticed:
- cashback is reported in small text in each transaction. However, cashback over ~$2 is reported ALSO as a transaction in the list, any other cashback -for inexplicable reasons- doesn't appear in the list. Is this a lazy "fix" to remove non relevant transactions from the list?
- scrolling the transactions is a nightmare. The list keeps changing and "updating" making impossible to simply look at the events in chronological order
- every time a transaction is opened, when going back the app returns to the top of the list instead of where you left
- cashback within the same account (so not invested in TSFA or other accounts) is not reported as incoming transaction
- the total simply doesn't up. Some transactions are missing, other are reported but they shouldn't (see above), list keeps changing, etc.

Given the status of your GraphQL endpoint I understand why the app suffers of the above bugs and why you don't have an export. Please, fix your backend and give us a reason to trust we won't need to leverage on your "triple CIDC deposit protection".

**/rant mode OFF**
## How do I use it?
### Quick setup
Assuming you have Ruby working on your machine, it is simple as running the following commands:
1. clone this code
2. enter in the directory
3. install the dependencies as listed in the gemspec file (i.e.: ```gem install dotenv```)
4. spin up irb or pry
5. run:
```
require_relative 'lib/wealthsimple_ruby_client'

client = WealthSimpleClient.new(otp: '123456', username: 'user', password: 'pass')
client.generate_export
```
6. find the full.xlsx and export.csv in the folder
### Recommended setup
1. install dotenv and the other dependencies as listed in the gemspec file
```
gem install dotenv
```
2. create a .env file in the directory with the code with the following content:
```
use_cache=false
debug=true
user=YOUR_EMAIL
pass=YOUR_PASSWORD
generate_csv_export=true
generate_xls_report=true
```
3. spin up irb or pry
4. run:
```
require_relative 'lib/wealthsimple_ruby_client'
require 'dotenv/load' # use this because you have stored variables in a local .env file

client = WealthSimpleClient.new(otp: '123456', username: ENV['user'], password: ENV['pass'])
```
5. You will see your access_token, replace username and password leaving just the access token in your .env file:
```
use_cache=false
debug=false
access_token='THE VERY LONG STRING YOU GOT ABOVE'
generate_csv_export=true
generate_xls_report=true
```
6. Until expiration of the token, you can execute the code simply with:
```
require_relative 'lib/wealthsimple_ruby_client'
require 'dotenv/load' # use this because you have stored variables in a local .env file

client = WealthSimpleClient.new(access_token: ENV['access_token'])
client.generate_export
```
**NOTE**: unless you changed the code, the access token is authorised just to read data from your WS account but cannot perform any other operation (read: your money is safe if someone steals your token).
## Future

### Features that are not currently supported but that are planned:
- support for range of dates. Currently the gem always gets the entire list of transactions which is helpful to identify any change with the APIs during this early stage. Furthermore, I see a lot of changes happening over time that are breaking the logic and require implementation of more workarounds and adding new queries
- retrieve automatically Wealthsimple user ID for cross_product_account_details. Not really needed as we don't need that data to extract the cash account transactions

### Out of scope:
- non-cash related APIs and other features
