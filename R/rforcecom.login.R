#' Sign in to the Force.com (Salesforce.com)
#' 
#' This function retrives a session ID from Salesforce.com.
#'
#' @usage rforcecom.login(username, password, loginURL, apiVersion)
#' @param username Your username for login to the Salesforce.com. In many cases, username is your E-mail address.
#' @param password Your password for login to the Salesforce.com. Note: DO NOT FORGET your Security Token. (Ex.) If your password is "Pass1234" and your security token is "XYZXYZXYZXYZ", you should set "Pass1234XYZXYZXYZXYZ".
#' @param loginURL (optional) Login URL. If your environment is sandbox specify (ex:) "https://test.salesforce.com/".
#' @param apiVersion (optional) Version of the REST API and SOAP API that you want to use. (ex:) "35.0" Supported versions from v20.0 and up.
#' @return 
#' \item{sessionID}{Session ID.}
#' \item{instanceURL}{Instance URL.}
#' \item{apiVersion}{API Version.}
#' @examples
#' \dontrun{
#' # Sign in to the Force.com
#' username <- "yourname@@yourcompany.com"
#' password <- "YourPasswordSECURITY_TOKEN"
#' session <- rforcecom.login(username, password)
#' }
#' @seealso
#'  \code{\link{rforcecom.query}}
#'  \code{\link{rforcecom.search}}
#'  \code{\link{rforcecom.create}}
#'  \code{\link{rforcecom.delete}}
#'  \code{\link{rforcecom.retrieve}}
#'  \code{\link{rforcecom.update}}
#'  \code{\link{rforcecom.upsert}}
#'  \code{\link{rforcecom.getServerTimestamp}}
#'  \code{\link{rforcecom.getObjectDescription}}
#'  \code{\link{rforcecom.getObjectList}}
#'  \code{\link{rforcecom.queryMore}}
#' @keywords connection
#' @export
rforcecom.login <-
  function(username, password, loginURL="https://login.salesforce.com/", apiVersion="35.0"){
    
    if(as.numeric(apiVersion) < 20) stop("The earliest supported API version is 20.0")
    
    # Soap Body
    soapBody <- paste0('<?xml version="1.0" encoding="utf-8" ?> \
                       <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" \
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
                       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"> \
                       <env:Body> \
                       <n1:login xmlns:n1="urn:partner.soap.sforce.com">\n',
                       as(newXMLNode("username", username), "character"),
                       as(newXMLNode("password", password), "character"),
                       '</n1:login> \
                       </env:Body> \
                       </env:Envelope>\n\n')
    
    # HTTP POST
    URL <- paste(loginURL, rforcecom.api.getSoapEndpoint(apiVersion), sep="")
    httpHeader<-httr::add_headers("SOAPAction"="login","Content-Type"="text/xml")
    res <- httr::POST(url=URL, config=httpHeader, body=soapBody)
    res.content = httr::content(res, as='text', encoding='UTF-8')
    
    # BEGIN DEBUG
    if(exists("rforcecom.debug") && rforcecom.debug){ message(URL) }
    if(exists("rforcecom.debug") && rforcecom.debug){ message(res.content) }
    # END DEBUG
    
    # Parse XML
    x.root <- xmlRoot(xmlTreeParse(res.content, asText=T))

    # Check whether it success or not
    faultstring <- NA
    try(faultstring <- iconv(xmlValue(x.root[['Body']][['Fault']][['faultstring']]), from="UTF-8", to=""), TRUE)
    if(!is.na(faultstring)){
      stop(faultstring)
    }
    
    # Retrieve sessionID from XML
    sessionID <- xmlValue(x.root[['Body']][['loginResponse']][['result']][['sessionId']])
    instanceURL <- sub('(https://[^/]+/).*', '\\1', xmlValue(x.root[['Body']][['loginResponse']][['result']][['serverUrl']]))
    return(c(sessionID=sessionID, instanceURL=instanceURL, apiVersion=apiVersion))
  }
