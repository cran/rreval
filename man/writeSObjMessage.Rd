\name{writeSObjMessage}
\alias{writeSObjMessage}
\title{writeSObjMessage
This is a version of writeMessage that creates and sends a message
containing an object that has already been serialized (and tested)
using ascii serialization.}
\usage{
  writeSObjMessage(con, messageType, sobj, nMaxTries = 16,
    maxWaitForAckSecs = 2)
}
\arguments{
  \item{con}{}

  \item{messageType}{}

  \item{sobj}{return number of chars written.}
}
\description{
  writeSObjMessage This is a version of writeMessage that
  creates and sends a message containing an object that has
  already been serialized (and tested) using ascii
  serialization.
}
\author{
  Barnet Wagman
}
\keyword{internal}

