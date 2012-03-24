\name{scpDownload}
\alias{scpDownload}
\title{Download a file from the remote host}
\usage{
  scpDownload(filenames, localDir = NULL,
    useRemoteCwd = TRUE, hostName = NULL, userName = NULL)
}
\arguments{
  \item{filenames}{Names of files to be downloaded
  (character array).  If useRemoteCwd == FALSE, these must
  be fully qualified path names.}

  \item{localDir}{Target local directory. If NULL, files
  are copied to the working directory of the local session
  (per getwd()).}

  \item{useRemoteCwd}{if TRUE and file names are not fully
  qualified pathnames, files are copied from the current
  working of the remote R session.}

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

