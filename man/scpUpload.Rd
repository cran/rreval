\name{scpUpload}
\alias{scpUpload}
\title{Upload a file to the remote host}
\usage{
  scpUpload(filenames, remoteDir = NULL,
    useLocalDir = TRUE, hostName = NULL, userName = NULL)
}
\arguments{
  \item{filenames}{Names of files to be uploaded (character
  array).  If useLocalDir == FALSE, these must be fully
  qualified path names.}

  \item{remoteDir}{Target directory on the remote host.  If
  NULL, files are copied to the working directory of the
  remote session (per getwd()).}

  \item{useLocalDir}{if TRUE and file names are not fully
  qualified pathnames, files are copied from the current
  working of the local R session.}

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
\description{
  This function returns after the transfer has been
  initiated. Use file.info() to determine when the transfer
  is complete.
}
\author{
  Barnet Wagman
}

