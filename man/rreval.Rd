\docType{package}
\name{rreval}
\alias{rreval}
\alias{rreval-package}
\title{Remote R Evaluation (rreval)}
\description{
  Remote R Evaluation (rreval)
}
\details{
  \tabular{ll}{ Package: \tab rreval\cr Type: \tab
  Package\cr Version: \tab 1.1--\cr Date: \tab
  2012-04-18\cr License: \tab GPL (>= 3)\cr }

  rreval is a means for using R on a remote system from
  within a local R session.  Any R expression can be
  evaluated on the remote server. All non-graphical results
  are returned to the local R session: this includes the
  results of remote evaluations and all textual output,
  including errors and warnings.  rreval uses socket level
  communication via ssh port forwarding. It supports
  uploading and downloading R objects and scp file
  tranfers.
}
\author{
  Barnet Wagman \email{bw@norbl.com}
}
\keyword{package}

