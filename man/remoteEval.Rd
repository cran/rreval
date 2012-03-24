\name{remoteEval}
\alias{remoteEval}
\title{Evaluate an expression on a remote system.}
\usage{
  remoteEval(expr, maxBytesReturnable = 2^18,
    hostName = NULL, userName = NULL)
}
\arguments{
  \item{expr}{expression() or quote()}

  \item{maxBytesReturnable}{maximum size (in bytes) of an
  object that will returned to the client after the
  expression is evaluated.  If the returned object exceeds
  this value, NULL is returned. maxBytesReturnable must be
  in [0,Inf].}

  \item{hostName}{the name of the host where the rre server
  is running; usually NULL (the default).  If this param
  (or userName) is NULL, the function will attempt to
  retrieve a connection from the connection manager
  environment.  This param needs to be supplied only if you
  have connected to more than one rreval server in the
  current R session.}

  \item{userName}{the name of user on remote host that is
  running rreServer; usually NULL (the default). If this
  param (or hostName) is NULL, the function will attempt to
  retrieve a connection from the connection manager
  environment.  This param needs to be supplied only if you
  have connected to more than one rreval server in the
  current R session.}
}
\value{
  the result of the evaluation or NULL if the size of the
  result object exceeds maxBytesReturnable.
}
\description{
  remoteEval() evaluates an expression in the .GlobalEnv
  environment of a remote R session and returns the result.
  See re() for a more convenient version of this function.
}
\note{
  remoteEval() returns a result even if the expression
  includes an assignment. E.g. remoteEval(quote(a <- 2+2))
  returns 4 AND creates a variable 'a' in the remote
  session with value 4. Note that returning large objects
  can be quite time consuming.  By default, objects whose
  serialized size exceeds maxBytesReturnable are not
  returned - NULL is returned instead.  To retrieve large
  objects, use scpDownload().  See the note in
  uploadObject() or upo().
}
\author{
  Barnet Wagman
}

