#' Close Bulk API Job 
#' 
#' This function closes a Job in the Salesforce Bulk API
#'
#' @usage rforcecom.closeBulkJob(session, jobId)
#' @concept bulk job salesforce api
#' @references \url{https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/}
#' @param session a named character vector defining parameters of the api connection as returned by \link{rforcecom.login}
#' @param jobId a character string defining the salesforce id assigned to a submitted job as returned by \link{rforcecom.createBulkJob}
#' @return A \code{list} of parameters defining the now closed job
#' @examples
#' \dontrun{
#' job_close_info <- rforcecom.closeBulkJob(session, jobId=job_info$id)
#' }
#' @export
rforcecom.closeBulkJob <-
  function(session, jobId){

    # XML Body
    xmlBody <- '<?xml version="1.0" encoding="UTF-8"?>
                <jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
                <state>Closed</state>
                </jobInfo>'
    
    # Send request
    endpointPath <- rforcecom.api.getBulkEndpoint(session['apiVersion'])
    URL <- paste(session['instanceURL'], endpointPath, '/job/', jobId, sep="")
    OAuthString <- unname(session['sessionID'])
    httpHeader <- httr::add_headers("X-SFDC-Session"=OAuthString, "Accept"="application/xml", 'Content-Type'="application/xml")
    res <- httr::POST(url=URL, config=httpHeader, body=xmlBody)
    res.content = httr::content(res, as='text', encoding='UTF-8')
    
    # BEGIN DEBUG
    if(exists("rforcecom.debug") && rforcecom.debug){ message(URL) }
    if(exists("rforcecom.debug") && rforcecom.debug){ message(res.content) }
    # END DEBUG
    
    # Parse XML
    x.root <- xmlRoot(xmlTreeParse(res.content, asText=T))
    
    # Check whether it success or not
    errorcode <- NA
    errormessage <- NA
    try(errorcode <- iconv(xmlValue(x.root[['exceptionCode']]), from="UTF-8", to=""), TRUE)
    try(errormessage <- iconv(xmlValue(x.root[['exceptionMessage']]), from="UTF-8", to=""), TRUE)
    if(!is.na(errorcode) && !is.na(errormessage)){
      stop(paste(errorcode, errormessage, sep=": "))
    }
    
    # Return XML response as list
    return(xmlToList(x.root))
  }
