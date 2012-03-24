\name{re}
\alias{re}
\title{Evaluate an expression on a remote system.}
\usage{
  re(x, maxBytesReturnable = 2^18, hostName = NULL,
    userName = NULL)
}
\arguments{
  \item{x}{e.g. re(1+1). re() converts its argument to an
  expression so you do not need to supply it with an
  expression or quote()'d object for x.}

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
  re() evaluates an expression in the .GlobalEnv
  environment of a remote R session and returns the result.
}
\details{
  re() is a convenience function, really just a wrapper for
  remoteEval(as.expression(substitute(x)).
}
\note{
  re() returns a result even if the expression includes an
  assignment. E.g. re(quote(a <- 2+2)) returns 4 AND
  creates a variable 'a' in the remote session with value
  4. Note that returning large objects can be quite time
  consuming.  By default, objects whose serialized size
  exceeds maxBytesReturnable are not returned - NULL is
  returned instead.  To retrieve large objects, use
  scpDownload().  See the note in uploadObject() or upo().
}
\author{
  Barnet Wagman
}

