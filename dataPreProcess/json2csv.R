# setwd("Covid19predict")

library(rjson)
library (plyr)
library(data.table)
#library(reshape2) # library for reshaping data (tall-narrow <-> short-wide)
json_file = "https://api.covid19uk.live/historyfigures"
readData =  fromJSON(paste(readLines(json_file), collapse="", simplify=TRUE))

hisData = readData[["data"]]
for (item in 1:length(hisData)) {
  hisData[[item]] = unlist(as.character(hisData[[item]]), use.names = T)
}

dfData = as.data.frame( Reduce(rbind, hisData))
colnames(dfData) = names(readData[["data"]][[1]])
rownames(dfData) = NULL
dfData$confirmed  =as.numeric(as.character(dfData$confirmed))
dfData$newConfirmed = 0
for (item in 2:nrow(dfData)) {
  dfData$newConfirmed[item] = dfData$confirmed[item] - dfData$confirmed[item-1]
}

dfData$death = as.numeric(as.character(dfData$death))
dfData$newDeath = 0
for (item in 2:nrow(dfData)) {
  dfData$newDeath[item] = dfData$death[item] - dfData$death[item-1]
}
dfData$hospitalArea = NULL
write.csv(dfData, file = "data/UK_data.csv", row.names = F, quote = F)


# Read EU data
dfGlobalData = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", header = T)

dfEUData =  subset(dfGlobalData, Country.Region == "Spain"| Country.Region == "Italy" | Country.Region =="Germany", select = c(2, 5:length(dfGlobalData)))
dfEUData = transpose(dfEUData)
colnames(dfEUData) = dfEUData[1,1:3]
dfEUData = dfEUData[6:nrow(dfEUData),1:3]

dfEUData$Spain_new = 0; dfEUData$Italy_new = 0; dfEUData$Germany_new = 0
dfEUData$Spain = as.numeric(dfEUData$Spain); dfEUData$Italy = as.numeric(dfEUData$Italy); dfEUData$Germany = as.numeric(dfEUData$Germany)
for (item in 2:nrow(dfEUData)) {
  dfEUData$Spain_new[item] = dfEUData$Spain[item] - dfEUData$Spain[item-1]
  dfEUData$Italy_new[item] = dfEUData$Italy[item] - dfEUData$Italy[item-1]
  dfEUData$Germany_new[item] = dfEUData$Germany[item] - dfEUData$Germany[item-1]
}

write.csv(dfEUData, file = "data/EU_confirmed.csv", row.names = F, quote = F)


# Read curret data
json_file = "https://api.covid19uk.live/"
readData =  fromJSON(paste(readLines(json_file), collapse="", simplify=TRUE))
dfCurrent = readData[["data"]][[1]]
dfCurrent = as.data.frame(dfCurrent[5:18])
dfCurrent = dfCurrent[c(1:2,8:12,14)]
colnames(dfCurrent) = c("Confirmed", "Death", "Tested", "England", "Scotland", "Wales", "N.Ireland", "In hospital")

knitr::kable(head(dfCurrent))

library(formattable)
row.names(dfCurrent) = NULL
ftCurrent <- formattable(dfCurrent,row.names = F)
library("htmltools")
library("webshot")

export_formattable <- function(f, file, width = "80%", height = NULL, 
                               background = "white", delay = 0.2)
{
  w <- as.htmlwidget(f, width = width, height = height)
  path <- html_print(w, background = background, viewer = NULL)
  url <- paste0("file:///", gsub("\\\\", "/", normalizePath(path)))
  webshot(url,
          file = file,
          selector = ".formattable_widget",
          delay = delay)
}
export_formattable(ftCurrent,"plot/CurrentStat.png")
