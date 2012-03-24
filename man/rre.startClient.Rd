\name{rre.startClient}
\alias{rre.startClient}
\title{Start rre client}
\usage{
  rre.startClient(hostName, userName, pemFile,
    portRJ = 4460, portJJ = 4464, timeout = 2,
    verbose = FALSE)
}
\arguments{
  \item{hostName}{the name of the host where the rre server
  is running.}

  \item{userName}{the name of user on remote host that is
  running rreServer; ssh will attempt to login as this
  user.}

  \item{pemFile}{RSA keypair file.  rre uses an rsa key
  (rather than a password) to access a remote system.  (The
  operations used are equivalent to ssh -i pemFile ...'
  and 'scp -i pemFile ...').}

  \item{portRJ}{number of the port used for communications
  with rreval.RReClientApp, the Java app that handles
  communications with the remote server
  (rreval.RReClientApp is launched by rre.startClient() if
  it is not already running.)}

  \item{portJJ}{number of the port used by the java app
  rreval.RReClientApp to communicate with the the
  rreval.RReServerApp, the server side java app.}

  \item{timeout}{socket timeout (in seconds).}

  \item{verbose}{for debugging.}
}
\description{
  rre.startClient creates a connection to a remote rreval
  server. The remote server must be running.
}
\details{
  Note that the connection (which is a socket connection)
  is not returned by rre.startClient() - it is stored in an
  environment dedicated to managing connections.  rreval
  functions retrieve connections based based on
  (hostName,userName) pairs; e.g. see re(). You do not need
  to use connection objects directly.

  The connection rre.startClient() creates is actually to
  locally running java app,rreval.RReClientApp.  If the app
  is not running, rre.startClient() will launch it.
}
\author{
  Barnet Wagman
}

