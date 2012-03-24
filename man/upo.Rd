\name{upo}
\alias{upo}
\title{Upload an object to the remote R session and assign it to
.Global.}
\usage{
  upo(obj, hostName = NULL, userName = NULL)
}
\arguments{
  \item{obj}{the object to be uploaded to the R session on
  the server.}

  \item{hostName}{hostName the name of the host where the
  rre server is running; usually NULL (the default).  If
  this param (or userName) is NULL, the function will
  attempt to retrieve a connection from the connection
  manager environment.  This param needs to be supplied
  only if you have connected to more than one rreval server
  in the current R session.}

  \item{userName}{userName the name of user on remote host
  that is running rreServer; usually NULL (the default). If
  this param (or hostName) is NULL, the function will
  attempt to retrieve a connection from the connection
  manager environment.  This param needs to be supplied
  only if you have connected to more than one rreval server
  in the current R session.}
}
\description{
  Upload an object to the remote R session and assign it to
  .Global.
}
\note{
  upo() is convenience function, equivalent to
  uploadObject(name=paste(substitute(obj)),obj=obj). rreval
  serializes object before transmitting them, using
  serialize(ascii=TRUE,...). serialize() has a maximum
  object size of 2^31 - 1 bytes. R objects can exceed this
  size.  Furthermore, the serialized version of an object
  is larger than the object it represents. To move large
  objects, rreval supports scp tranfers. E.g. use save() to
  write an object to disk, scpUpload() or scpDownload() to
  tranfer the object, then load() to restore it.  Note that
  for large objects scp is considerably faster than upo().
}
\author{
  Barnet Wagman
}

