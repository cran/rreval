\name{sendToRReServer}
\alias{sendToRReServer}
\title{Sends an rcsMessage from client to server. Sending a message
to the server always elicits a reply. This function does not return
until it receives a non-SINK.OUTPUT message (which it prints immediately)
or an error (which yields a stop).
if the reply is an error.}
\usage{
  sendToRReServer(con, rcsMessage, maxWaitSecs = -1)
}
\arguments{
  \item{con}{}

  \item{rcsMessage}{}

  \item{maxWaitSecs}{}
}
\value{
  value
}
\description{
  Sends an rcsMessage from client to server. Sending a
  message to the server always elicits a reply. This
  function does not return until it receives a
  non-SINK.OUTPUT message (which it prints immediately) or
  an error (which yields a stop). if the reply is an error.
}
\author{
  Barnet Wagman
}
\keyword{internal}

