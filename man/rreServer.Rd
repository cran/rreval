\name{rreServer}
\alias{rreServer}
\title{rre server}
\usage{
  rreServer(portRJ = 4463, portJJ = 4464,
    workingDir = NULL, timeout = 2, verbose = FALSE,
    launchApp = TRUE)
}
\arguments{
  \item{portRJ}{number of the port used for communications
  with rreval.RReServerApp, the java app that handles
  communications with the remote client
  (rreval.RReServerApp is launched by rreServer()).}

  \item{portJJ}{number of the port used by the java app
  rreval.RReServerApp to communicate with the the
  rreval.RReClientApp, the client side java app.}

  \item{workingDir}{the local directory to be used as the
  working directory; if not NULL, rreServer() calls
  setwd(workingDir).}

  \item{timeout}{socket timeout (in seconds).}

  \item{verbose}{for debugging.}

  \item{launchApp}{if TRUE (the default), rreServer()
  launches the java app, rreval.RReServerApp.  Otherwise
  the app is assumed to already be running.
  (launchApp=FALSE is primarily for debugging.)}
}
\description{
  The server evaluates expressions received from a 'client'
  remote R session (sent using the re() function.)
  Expressions are evaluated in .GlobalEnv. The server can
  also receive objects sent by the client using the upo()
  function; objects are assigned to the specified name in
  .GlobalEnv.
}
\details{
  The rreServer handles commands from one client at time.
  Once a client has connected to the server (using
  rre.startClient(), it has exclusive use of the server
  until it disconnects (using rre.closeClient()). Once
  invoked, rreServer() runs forever.
}
\author{
  Barnet Wagman
}

