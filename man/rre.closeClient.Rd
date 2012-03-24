\name{rre.closeClient}
\alias{rre.closeClient}
\title{Close the connection to a remote server.}
\usage{
  rre.closeClient(hostName = NULL, userName = NULL)
}
\arguments{
  \item{hostName}{the name of the host where the rre server
  is running; usually NULL (the default).  If this param
  (or userName) is NULL, the function will attempt to
  retrieve a connection from the connection manager
  environment and close it.  This param needs to be
  supplied only if you have connected to more than one
  rreval server in the current R session.}

  \item{userName}{the name of user on remote host that is
  running rreServer; usually NULL (the default). If this
  param (or hostName) is NULL, the function will attempt to
  retrieve a connection from the connection manager
  environment and close it.  This param needs to be
  supplied only if you have connected to more than one
  rreval server in the current R session.}
}
\description{
  rre.closeClient() closes the connection to a remote
  server that was created by rre.startClient().  After this
  function is called, the remote server can accept a
  connection from another client. If this is the last
  client connected to the client app, the app is shutdown.
}
\author{
  Barnet Wagman
}

