### ----------------------------------------------------------
### Workshop: An introduction to web scraping with R, II
### Simon Munzert
### Duke University, October 2014
### ----------------------------------------------------------


### preparations ---------------------------------------------

# clear workspace
rm(list=ls(all=TRUE))

# install and load packages
pkgs <- c("RCurl", "XML", "stringr", "httr", "plyr", "ggplot2", "RSelenium", "jsonlite")
# install.packages(pkgs)
lapply(pkgs, library, character.only=T)



### wrap-up of last session ----------------------------------

# we can use R to scrape data from static homepages

# SelectorGadget is great

# useful packages
  # library(XML) --> XML/HTML parsing, extraction with XPath
  # library(RCurl) --> R as HTTP client
  # library(stringr) --> toolbox for text manipulation, regular expressions

# the web scraping workflow
  # 1. identify information and page structure
  # 2. develop download strategy for needed files (write your own functions!)
  # 3. extract info from downloaded files (parsing --> extracting --> tidying)
  # 4. keep functions robust and save server traffic!



### today's schedule -----------------------------------------

# 1. how to scrape data from dynamic (i.e., JavaScript-enriched) web sites
# 2. how to access APIs
# 3. how to behave nicely on the Web



### last session's homework assignment -----------------------

# 1. Visit http://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1992 and extract the table containing the elected MPs int the United Kingdom general election of 1992. Which party has most 'Sirs'?

url <- "http://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1992"
browseURL(url)
mps_table <- readHTMLTable(url, which = 4)
head(mps_table)
names(mps_table) <- c("district", "mp", "party")
mps_table <- mps_table[!is.na(mps_table$mp),]
mps_table <- mps_table[-1,]
mps_table$sir <- str_detect(mps_table$mp, "^Sir ")
View(mps_table[mps_table$sir == TRUE,])
table(mps_table$party, mps_table$sir)

# 2. The XML file potus.xml contains biographical information on US presidents. Parse the file into an object of the R session. This works with the xmlParse() function from the XML package.

potus <- xmlParse("potus.xml")
class(potus)

# (a) Extract the names of all presidents!
names <- xpathSApply(potus, "//name", xmlValue)
head(names)

# (b) Extract the value of the <occupation> node for all Republican presidents.
occupation <- xpathSApply(potus, "//occupation[preceding-sibling::party[text()='Republican']]", xmlValue) 
occupation 

# (c) Extract information from the <education> nodes.
education <- xpathSApply(potus, "//education", xmlValue)
head(education)
str_detect(education, "Duke")

# (d) Convert the parsed XML data into a common data.frame. 
potus_df <- xmlToDataFrame(potus)
# NOTE: there is no generalized XML-to-data.frame function!

# 3. Describe the types of strings that conform to the following regular expressions and construct an example that is matched by the regular expression.
# (a) [0-9]+\\$
str_extract_all("Phone 150$, PC 690$", "[0-9]+\\$")

# (b) \\b[a-z]{1,4}\\b
str_extract_all("This is a sentence with shorter and longer words", "\\b[a-z]{1,4}\\b")

# (c) .*?\\.txt$
str_extract_all(c("session.RData", "log.txt", ".txt"), ".*?\\.txt$")

# (d) \\d{2}/\\d{2}/\\d{4}
str_extract("14/07/1983", "\\d{2}/\\d{2}/\\d{4}")

# (e) <(.+?)>.+?</\\1>
str_extract("blah <body>this is an HTML element</body> blah", "<(.+?)>.+?</\\1>")



### source code inspection tools -----------------------------

# Chrome, Firefox:
  # right-click on element, then "Inspect Element"

# Safari:
  # Settings --> Advanced --> Show Develop menu in menu bar
  # Web inspector tools visible in menu bar - the console is most useful

# Internet Explorer:
  # go to google.com/chrome/ or mozilla.org/en-US/firefox/new/ and download Chrome/Firefox
  # next: see above

browseURL("http://www.washingtonpost.com/blogs/monkey-cage/")


### scraping dynamic information with RSelenium --------------

# classic HTML/HTTP mainly for display of static content
# AJAX (Asynchronous JavaScript and XML) is a set of technologies which provide means for asynchronous (not merely action-reaction-style) communication with servers
# JavaScript/jQuery: scripting language with excellent bindings to web technologies
# modern browsers can `speak' JavaScript

# practical problems for web scrapers
  # the HTML tree changes dynamically
  # content changes, URL remains the same
  # content is only embedded in the live HTML tree

# solution: Selenium 
  # http://docs.seleniumhq.org/projects/webdriver/
  # a testing framework for web applications
  # automates browsing via scripts
  # Selenium WebDriver: a Java-based server which passes commands to a browser, retrieves responses and thereby makes the live tree accessible

# several R bindings to Selenium Webdriver
  # Rwebdriver | Christian Rubba | https://github.com/crubba/Rwebdriver
  # RSelenium | John Harrison | CRAN


# time to get started...

# running example
browseURL("http://www.iea.org/policiesandmeasures/renewableenergy/")
parsed_url <- htmlParse("http://www.iea.org/policiesandmeasures/renewableenergy/")

# set up connection via RSelenium package
# documentation: http://cran.r-project.org/web/packages/RSelenium/RSelenium.pdf
library(RSelenium)

# retrieve Selenium Server binary if necessary
checkForServer()

# start server
startServer() 

# connect to server
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4444, browserName = "firefox") 

# open connection; Firefox window should pop up
remDr$open() 

# navigate to data request page
remDr$navigate("http://www.iea.org/policiesandmeasures/renewableenergy/") 

# open regions menu
xpath <- '//*[@id="advancedSearch"]/div[1]/div[1]/ul/li[1]/span'
regionsElem <- remDr$findElement(using = 'xpath', value = xpath)
openRegions <- regionsElem$clickElement() # click on button

# selection "European Union"
xpath <- '//*[@id="advancedSearch"]/div[1]/div[1]/ul/li[1]/ul/li[2]/label/input'
euElem <- remDr$findElement(using = 'xpath', value = xpath)
selectEU <- euElem$clickElement() # click on button

# set time frame
xpath <- '//*[@id="advancedSearch"]/div[2]/div[1]/select[1]'
fromDrop <- remDr$findElement(using = 'xpath', value = xpath) 
clickFrom <- fromDrop$clickElement() # click on drop-down menu
writeFrom <- fromDrop$sendKeysToElement(list("2000")) # enter start year

xpath <- '//*[@id="advancedSearch"]/div[2]/div[1]/select[2]'
toDrop <- remDr$findElement(using = 'xpath', value = xpath) 
clickTo <- toDrop$clickElement() # click on drop-down menu
writeTo <- toDrop$sendKeysToElement(list("2010")) # enter end year

# click on search button
xpath <- '//button[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]'
searchElem <- remDr$findElement(using = 'xpath', value = xpath)
resultsPage <- searchElem$clickElement() # click on button

# store index page
output <- remDr$getPageSource(header = TRUE)
write(output[[1]], file = "iea-renewables.html")

# close connection
remDr$closeServer()

# parse index table
parsed_table <- readHTMLTable("iea-renewables.html") # Windows users beware: encoding problems!
head(parsed_table[[4]])
parsed_table <- parsed_table[[4]]
View(parsed_table)
names(parsed_table) <- c("title", "country", "year", "status", "type", "target")


### a little refresher: R and 2048 ---------------------------
source("rselenium-2048.r") # by Mark T. Patterson
grand.play()




### retrieving data from APIs --------------------------------

# example 1: yahoo weather API
browseURL("https://developer.yahoo.com/weather/documentation.html")
# woeid resolver: 
browseURL("http://woeid.rosselliot.co.nz/lookup")

# access api manually
browseURL("http://weather.yahooapis.com/forecastrss?w=2394734&u=c")

# access api with getForm()
feed_url <- "http://weather.yahooapis.com/forecastrss"
feed <- getForm(feed_url , .params = list(w = "2394734", u = "c"))
(parsed_feed <- xmlParse(feed))

# get current conditions
xpath <- "//yweather:location|//yweather:wind|//yweather:condition"
(conditions <- unlist(xpathSApply(parsed_feed, xpath, xmlAttrs)))

# automate the procedure
load("yahooid.Rdata")
options(yahooid = yahooid)
source("getWeather.r")
getWeather(place = "Durham, NC", ask = "current", temp = "c")
getWeather(place = "Durham, UK", ask = "current", temp = "c")
getWeather(place = "North Pole", ask = "forecast", temp = "c")
getWeather(place = "Hell", ask = "current", temp = "f")
getWeather(place = "Heaven", ask = "forecast", temp = "f")



# example 2: arxiv.org API
# overview: 
browseURL("http://arxiv.org/help/api/index")
# documentation: 
browseURL("http://arxiv.org/help/api/user-manual")

# access api manually:
browseURL("http://export.arxiv.org/api/query?search_query=all:forecast")

library(XML)
forecast <- xmlParse("http://export.arxiv.org/api/query?search_query=all:forecast")
xpathSApply(forecast, "//x:author", fun = xmlValue,  namespaces = c(x = "http://www.w3.org/2005/Atom"))

# install aRxiv API wrapper
# documentation at 
browseURL("http://ropensci.org/tutorials/arxiv_tutorial.html")
#install.packages("devtools")
library(devtools)
#install_github("ropensci/aRxiv")
library(aRxiv)
ls("package:aRxiv")
lsf.str("package:aRxiv")

# access with wrapper
arxiv_df <- arxiv_search(query = "forecast", limit = 10, output_format = "data.frame")
View(arxiv_df)

arxiv_count('au:"Gary King"')

query_terms

arxiv_count('abs:"political" AND submittedDate:[2010 TO 2014]')
polsci_articles <- arxiv_search('abs:"political" AND submittedDate:[2010 TO 2014]', limit = 1000)



### working with Twitter's APIs ------------------------------

# two APIs types of interest:
  # REST APIs --> reading/writing/following/etc., "Twitter remote control"
  # Streaming APIs --> low latency access to 1% of global stream - public, user and site streams
# authentication via OAuth
# documentation at https://dev.twitter.com/overview/documentation

# how to get started
  # 1. register as a developer at https://dev.twitter.com/ - it's free
  # 2. create a new app at https://apps.twitter.com/ - choose a random name, e.g., MyTwitterToRApp
  # 3. go to "Keys and Access Tokens" and keep the displayed information ready
  # 4. paste your consumer key and secret into the following code and execute it:

library(ROAuth)
library(RCurl)
requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"
consumerKey <- "xxxxxyyyyyzzzzzz"
consumerSecret <- "xxxxxxyyyyyzzzzzzz111111222222"
twitCred <- OAuthFactory$new(consumerKey = consumerKey, consumerSecret = consumerSecret,
                             requestURL = requestURL, accessURL = accessURL, authURL = authURL)
twitCred$handshake(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
# stop here, copy URL into browser, enter PIN into console and press enter. then continue.
save(twitCred, file = "twitter_auth.Rdata")

  # 5. the twitCred object stores credentials which have to be passed to the API to get access. once you have stored this information, you do not have to execute the code above again in later sessions. just load the twitter_auth.Rdata file and execute registerTwitterOAuth(twitCred) from the twitteR package


### working with the twitteR package ---------------------------
library(twitteR)

# negotiate credentials
load("twitter_auth.Rdata")
registerTwitterOAuth(twitCred)
cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")

# search tweets on twitter
tweets <- searchTwitter(searchString = "Ebola", n=25, lang=NULL, since=NULL, until=NULL, locale=NULL, geocode=NULL, sinceID=NULL, retryOnRateLimit=120, cainfo=cainfo)
tweets_df <- twListToDF(tweets)
head(tweets_df)
names(tweets_df)

# get information about users
user <- getUser("RDataCollection", cainfo=cainfo)
user$name
user$lastStatus
user$followersCount
user$statusesCount
user_followers <- user$getFollowers(cainfo=cainfo)
user_friends <- user$getFriends(cainfo=cainfo) 
user_timeline <- userTimeline(user, n=20, cainfo=cainfo)
timeline_df <- twListToDF(user_timeline)

# check rate limits
getCurRateLimitInfo(cainfo=cainfo)


### working with the streamR package ---------------------------
library(streamR)

filterStream("tweets_ebola.json", track = c("Ebola"), timeout = 5, oauth = twitCred)
tweets <- parseTweets("tweets_ebola.json", simplify = TRUE)
names(tweets)
cat(tweets$text[1])



### working with JSON data -------------------------------------

# JavaScript Object Notation is a lightweight data interchange format
# ultimately compatible with virtually all modern programming languages
# most popular output from modern web APIs

# JSON and R
  # rjson --> old
  # RJSONIO --> newer
  # jsonlite --> newest, best

library(jsonlite)

# import and parse JSON data
govtrack_list <- fromJSON("govtrack108.json")
govtrack_list
names(govtrack_list)

# extract voting records
names(govtrack_list$votes)
govtrackYes <- govtrack_list$votes$Aye
govtrackNo <- govtrack_list$votes$No
govtrackNV <- govtrack_list$votes$`Not Voting`
govtrackYes$vote <- "YES"
govtrackNo$vote <- "NO"
govtrackNV$vote <- "NV"

# create data frame
govtrackDF <- rbind(govtrackYes, govtrackNo, govtrackNV)
class(govtrackDF)
sapply(govtrackDF, class)
with(govtrackDF, table(party, vote))

# expand data frame
govtrackDF$congress <- govtrack_list$bill$congress
View(govtrackDF)



### finally: please behave nicely on the Web! ------------------

# 1. use APIs, if available, and follow the terms of use
# 2. get into contact with the data providers (especially for small websites)
# 3. obey robots.txt (consider it at least)
# 4. stay identifiable! the RCurl package helps you set up an adequate HTTP communication strategy
# 5. keep traffic at a minimum: download content only once, update only if necessary
# 6. don't violate any property rights

# ... and get inspired!
browseURL("http://www.programmableweb.com/apis")
browseURL("http://stats.grok.se/")
browseURL("http://www.freebase.com/")
browseURL("http://www.enigma.io/")
browseURL("http://www.r-bloggers.com/")


# don't hesitate to email me if you've got any further questions:
# simon.munzert@uni.kn