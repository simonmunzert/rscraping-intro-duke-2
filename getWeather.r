# build wrapper function
getWeather <- function(place = "New York", ask = "current", temp = "c") {
  if (!ask %in% c("current","forecast")) {
    stop("Wrong ask parameter. Choose either 'current' or 'forecast'.")
  }
  if (!temp %in%  c("c", "f")) {
    stop("Wrong temp parameter. Choose either 'c' for Celsius or 'f' for Fahrenheit.")
  }	
  ## get woeid
  base_url <- "http://where.yahooapis.com/v1/places.q('%s')"
  woeid_url <- sprintf(base_url, URLencode(place))
  parsed_woeid <- xmlParse((getForm(woeid_url, appid = getOption("yahooid"))))
  woeid <- xpathSApply(parsed_woeid, "//*[local-name()='locality1']", xmlAttrs)[2,]
  ## get weather feed
  feed_url <- "http://weather.yahooapis.com/forecastrss"
  parsed_feed <- xmlParse(getForm(feed_url, .params = list(w = woeid, u = temp)))
  ## get current conditions
  if (ask == "current") {
    xpath <- "//yweather:location|//yweather:condition"
    conds <- data.frame(t(unlist(xpathSApply(parsed_feed, xpath, xmlAttrs))))
    message(sprintf("The weather in %s, %s, %s is %s. Current temperature is %s°%s.", conds$city, conds$region, conds$country, tolower(conds$text), conds$temp, toupper(temp)))
  }
  ## get forecast	
  if (ask == "forecast") {
    location <- data.frame(t(xpathSApply(parsed_feed, "//yweather:location", xmlAttrs)))
    forecasts <- data.frame(t(xpathSApply(parsed_feed, "//yweather:forecast", xmlAttrs)))
    message(sprintf("Weather forecast for %s, %s, %s:", location$city, location$region, location$country))
    return(forecasts)
  }
}
