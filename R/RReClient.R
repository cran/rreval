#
#    Copyright 2012 Northbranchlogic, Inc.
#
#    This file is part of Remote R Evaluator (rreval).
#
#    rreval is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    rreval is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with rreval.  If not, see <http://www.gnu.org/licenses/>.
#
#    ----------------------------------------------------------------------
# 
#    RReClient.R
#
#    ----------------------------------------------------------------------

#' Start rre client
#'
#' rre.startClient creates a connection to a remote rreval server. The remote
#' server must be running.
#'
#' Note that the connection (which is a socket connection) is not returned
#' by rre.startClient() - it is stored in an environment dedicated to 
#' managing connections.  rreval functions retrieve connections based
#' based on (hostName,userName) pairs; e.g. see re().  
#' You do not need to use connection objects directly.
#'
#' The connection rre.startClient() creates is actually to locally running 
#' java app,rreval.RReClientApp.  If the app is not running, rre.startClient() 
#' will launch it.
#'
#' @param hostName the name of the host where the rre server is running.
#' @param userName the name of user on remote host that is running rreServer; ssh will
#'        attempt to login as this user.
#' @param pemFile RSA keypair file.  rre uses an rsa key (rather than a password) to
#'        access a remote system.  (The operations used are equivalent to 
#'        ssh -i pemFile ...'  and 'scp -i pemFile ...').
#' @param portRJ number of the port used for communications with 
#' rreval.RReClientApp, the Java app that handles communications
#' with the remote server (rreval.RReClientApp is launched by rre.startClient()
#' if it is not already running.)
#' @param portJJ number of the port used by the java app rreval.RReClientApp
#' to communicate with the the rreval.RReServerApp, the server side java app.
#' @param timeout socket timeout (in seconds).
#' @param verbose for debugging.
#' @author Barnet Wagman
#' @export
rre.startClient <- function(hostName,
                            userName,
                            pemFile,
                            portRJ=4460,
                            portJJ=4464,
                            timeout=2,                      
                            verbose=FALSE
                      ) {
  hostName; userName; pemFile; # Check for required params before proceeding.
  assign(x="verbose",value=verbose,envir=.GlobalEnv);  
  defineMessageTypes();
  defineRcsMessageTypes();
  
  if ( !clientAppIsRunning(portRJ,timeout=timeout) ) {
    launchRReClientApp(portR=portRJ);
    if ( verboseOn() ) print(paste("launched RReServerApp, port=",
                               portRJ,sep=""));
  }
  else if (verboseOn()) print(paste("RReServerApp is running, port=",
                                portRJ,sep=""));
  
     # Connect to the app
  key <- NULL;
  conApp <- getOpenCon(hostName=hostName,userName=userName);
  if ( is.null(conApp) ) {
    if ( !is.null(hostName) && !is.null(userName) ) {
      conApp <- connectToClientApp(port=portRJ,timeout=timeout);
      key <- paste(hostName,userName,sep=".");
      putOpenCon(con=conApp,hostName=hostName,userName=userName,port=portRJ);
    }
    else {
      stop(simpleError(paste("There are no open connections to rreval servers; ",
                             "you must specify a host name and user name")));
    }
  }
  
  if ( verboseOn() ) print("Connected to the client side app.");
 
    # Command app to connect to the remote server app conduit.
  cmdC <- createAppConnectCommand(hostName=hostName,
                                  userName=userName,
                                  portRJ=portRJ,
                                  portJJ=portJJ,
                                  pemFile=pemFile);
  mr <- sendAppCmd(con=conApp,cmd=cmdC);  
  if ( containsString(s=mr,pattern="TERMINAL RRE APP ERROR:") ) {
    closeEh(conApp);
    if (!is.null(key) ) rm(list=c(key),envir=conManagerEnv);   
    print(substring(text=mr,first=24));   
  }
  else print(mr);  
}

#' Close the connection to a remote server.
#'
#' rre.closeClient() closes the connection to a remote server that was
#' created by rre.startClient().  After this function is called, the
#' remote server can accept a connection from another client. If this is the last
#' client connected to the client app, the app is shutdown. 
#'
#' @author Barnet Wagman
#' @export
#' @param hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment and close it.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment and close it.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
rre.closeClient <- function(hostName=NULL,
                            userName=NULL) {
  
  conObj <- getOpenConObj(hostName=hostName,userName=userName);
  if ( is.null(conObj) || !hasEl(x=conObj,name="cono") || 
       !isGoodCon(conObj$cono) ) {
    noConStop(hostName=hostName,userName=userName);
  }
  
    # Send close cmd to app
  cmda <- createAppCmd(cmdName="closeConnection");
  mr <- sendAppCmd(con=conObj$cono,cmd=cmda);
  if (verboseOn()) print(mr);
  
    # Close connections
  closeEh(conObj$cono);
  
  key <- paste(conObj$hostName,conObj$userName,sep=".");
  rm(list=c(key),envir=conManagerEnv);    
}
  
#' Show clients
#'
#' Displays a list of active clients in this R session, i.e. the
#' names of rre server hosts to which there are open connections. 
#'
#' @author Barnet Wagman
#' @export
#' @return (hostName,userName) pairs in a data.frame.
rre.showClients <- function() {
  if ( !exists("conManagerEnv",envir=.GlobalEnv) ) return(NULL);
  cns <- ls(envir=conManagerEnv);
  if ( length(cns) < 1 ) return(NULL);
  m <- c();
  for ( i in 1:length(cns) ) {
    cl <- get(x=cns[i],envir=conManagerEnv);
    if ( !is.null(cl$cono) ) {
      m <- rbind(m,
                 c(hostName=cl$hostName,userName=cl$userName));
    }
  }
  as.data.frame(m)      
}
 
#' Close all connections
#'
#' Closes all connections to rreval servers and terminates the
#' Java application that handles these connections (rreval.RReClientApp).
#' @author Barnet Wagman
#' @export
rre.closeAllConnections <- function() {
  if ( exists("conManagerEnv") ) {
    if ( verbose ) print("case a");
    keys <- ls(envir = conManagerEnv);
    if ( length(keys) < 1 ) {    
      rm(conManagerEnv,envir=.GlobalEnv);
      stop(simpleError("There are no open connections."));
    }
    else if ( length(keys) > 1 ) { # Close all but one connections    
      for ( i in 2:length(keys) ) {
        co <- getOpenConObjKey(key=keys[i]);
        rre.closeClient(hostName=co$hostName,userName=co$userName);
      }   
    }   
    # Now close the last one
    co <- getOpenConObjKey(key=keys[1]);   
    cmda <- createAppCmd(cmdName = "shutdown");
    mr <- sendAppCmd(con = co$cono, cmd = cmda)   
    if (verboseOn()) print(mr);  
    closeEh(co$cono);  
    rm(conManagerEnv,envir=.GlobalEnv);  
  }
  else stop(simpleError("There are no open connections."));
}

#' accessAppIsRunning
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param port
#' @param timeout
#' @return boolean
clientAppIsRunning <- function(port,timeout) {
    b <- tryCatch(con <- connectToApp(port=port,timeout=timeout),
                  error=function(e) { 
                    if (verboseOn()) print(e); return(FALSE); 
                  },
                  warning=function(e) { return(FALSE); }
                  );
    if ( is.logical(b) ) { return(FALSE); }
    else {
      closeEh(con);
      return(TRUE);
    }
}

#' launchRReServerAccessApp
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param portR
launchRReClientApp <- function(portR) {  
  
  cmd <- paste("java -classpath ",getJavaAppClassPath("rreval"),
               " rreval.RReClientApp",
               " portR=",portR,              
               sep=""
               );
  
  system(cmd,intern=FALSE,wait=FALSE,ignore.stderr=TRUE,ignore.stdout=TRUE);
  if ( verboseOn() ) print(paste("system:",cmd));
}

#' close server con
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
closeServerCon <- function(con) {
  cmd <- createAppCmd(cmdName="closeServerConnection");
  sendAppCmd(con=con,cmd=cmd)
}

#' accessAppIsRunning
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param messageRcs
#' @param maxWaitSecs
sendMessageToRReServer <- function(con,messageRcs,maxWaitSecs=-1) {
  writeMessage(con=con,messageType=mType$messageToR,obj=messageRcs);
  readMessage(con,maxWaitSecs=maxWaitSecs)
}

# ------------- Eval and obj upload ---------------------------------

#' Evaluate an expression on a remote system.  
#' 
#' remoteEval() evaluates an expression in the .GlobalEnv environment
#' of a remote R session and returns the result.
#' See re() for a more convenient version of this function.
#'
#' @note remoteEval() returns a result even if the expression includes an
#' assignment. E.g. remoteEval(quote(a <- 2+2)) returns 4 AND creates a 
#' variable 'a' in the remote session with value 4.
#' Note that returning large objects can be quite time consuming.  By 
#' default, objects whose serialized size exceeds maxBytesReturnable are
#' not returned - NULL is returned instead.  To retrieve large objects,
#' use scpDownload().  See the note in uploadObject() or upo().
#' @author Barnet Wagman
#' @export
#' @param expr expression() or quote()
#' @param maxBytesReturnable maximum size (in bytes) of an object 
#' that will returned to the client after the expression is evaluated.  If
#' the returned object exceeds this value, NULL is returned. maxBytesReturnable
#' must be in [0,Inf].
#' @param hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @return the result of the evaluation or NULL if the size of the result
#' object exceeds maxBytesReturnable.
remoteEval <- function(expr,
                       maxBytesReturnable=2^18,
                       hostName=NULL,userName=NULL) {
  
  con <- getOpenCon(hostName=hostName,userName=userName);
  if ( is.null(con) ) noConStop(hostName=hostName,userName=userName);
  
  # mr <- createRcsMessage(type=mTypeRcs$EXPR,val=expr);
  mr <- createExprMessage(expr=expr,maxBytesReturnable=maxBytesReturnable);
  writeMessage(con=con,messageType=mType$messageToR,obj=mr);
  
  m <- tryCatch(readMessage(con=con),
                  error=function(e) { stop(e); }
               );
  
  if ( !is.null(m) && isRcsMessage(m) ) {
    if ( hasEl(x=m,name="sinkOutput") && !is.null(m$sinkOutput) ) {
      #cat(m$sinkOutput);
      print(m$sinkOutput);
    }
    if ( isRcsType(m=m,type=mTypeRcs$EVAL.RESULT) ) {
        return(m$val);
    }
    else if ( isRcsType(m=m,type=mTypeRcs$ERR) ) {
      if ( containsString(s=m$val$message,pattern="RSERVER-SIDE SER TEST") ) {
           # ^ This is probably that bad object returned by mpi.bcast.Robj2slave(),
           #   which should return anything.  We'll ignore it.
        return(NULL);
      }
      else { return(m$val); }
    }
    else if ( isRcsType(m=m,type=mTypeRcs$OBJ.ACK) ) {
       print(m$val);
    }
    else {
      stop(paste("Unexpected return from eval: ",m$val));
    }
  }
  else { 
    stop(paste("Unexpected return from eval:",m));
  }  
}


#' Evaluate an expression on a remote system.  
#' 
#' re() evaluates an expression in the .GlobalEnv environment
#' of a remote R session and returns the result. 
#'
#' re() is a convenience function, really just a wrapper for 
#' remoteEval(as.expression(substitute(x)).
#'
#' @note re() returns a result even if the expression includes an
#' assignment. E.g. re(quote(a <- 2+2)) returns 4 AND creates a 
#' variable 'a' in the remote session with value 4.
#' Note that returning large objects can be quite time consuming.  By 
#' default, objects whose serialized size exceeds maxBytesReturnable are
#' not returned - NULL is returned instead.  To retrieve large objects,
#' use scpDownload().  See the note in uploadObject() or upo().
#' @author Barnet Wagman
#' @export
#' @param x e.g. re(1+1). re() converts its argument to an expression
#' so you do not need to supply it with an expression or quote()'d object
#' for x.
#' @param maxBytesReturnable maximum size (in bytes) of an object 
#' that will returned to the client after the expression is evaluated.  If
#' the returned object exceeds this value, NULL is returned. maxBytesReturnable
#' must be in [0,Inf].
#' @param hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @return the result of the evaluation or NULL if the size of the result
#' object exceeds maxBytesReturnable.
re <- function(x,
               maxBytesReturnable=2^18,
               hostName=NULL,userName=NULL) {
  remoteEval(as.expression(substitute(x)),
             maxBytesReturnable=maxBytesReturnable,
             hostName=hostName,
             userName=userName)
}

#' noConStop
#' @author Barnet Wagman
#' @export
#' @keywords internal
#' @param hostName
#' @param userName
noConStop <- function(hostName,userName) {
  if ( is.null(hostName) || is.null(userName) ) {
    s <- "There are no open connections to rreval servers.";
  }
  else {
    s <- paste("There is no open connection to an rreval server on ",
               hostName,"@",userName,sep="");    
  }
  stop(simpleError(s));
}

# --------- Object upload functions ------------------------------

#' Upload an object to the remote R session and assign it to
#' .Global.
#'
#' See upo() for a more convenient version of this function.
#'
#' @note rreval serializes object before transmitting them,
#' using serialize(ascii=TRUE,...). serialize() has a maximum object size of
#' 2^31 - 1 bytes. R objects can exceed this size.  Furthermore, the
#' serialized version of an object is larger than the object it represents.
#' To move large objects, rreval supports scp tranfers. E.g. use
#' save() to write an object to disk, scpUpload() or scpDownload() to tranfer
#' the object, then load() to restore it.  Note that for large objects
#' scp is considerably faster than uploadObject().
#'
#' @author Barnet Wagman
#' @export
#' @param objName the name of the object to be uploaded.  obj will be assigned
#' this name in the server session.
#' @param obj the object to be uploaded to the R session on the server.
#' @param hostName hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
uploadObject <- function(objName,obj,hostName=NULL,userName=NULL) {
  
  con <- getOpenCon(hostName=hostName,userName=userName);
  if ( is.null(con) ) noConStop(hostName=hostName,userName=userName);
  
  mr <- createRcsMessage(type=mTypeRcs$OBJ,
                         val=list(objName=objName,obj=obj));
  
  writeMessage(con=con,messageType=mType$messageToR,obj=mr);
  
  m <- tryCatch(readMessage(con=con),
                  error=function(e) { stop(e); }
               );
  if ( !is.null(m) && isRcsMessage(m) ) {
    if ( isRcsType(m=m,type=mTypeRcs$OBJ.ACK) ||
         isRcsType(m=m,type=mTypeRcs$ERR) ) {
        print(m$val);
    }
    else { stop(simpleError(paste("Unexpected return:",
                                  m$type,m$val)));
    }
  }
  else { stop(simpleError(paste("Unexpected return:",m))); }
}

#' Upload an object to the remote R session and assign it to
#' .Global.
#'
#' @note upo() is convenience function, equivalent to 
#' uploadObject(name=paste(substitute(obj)),obj=obj).
#' rreval serializes object before transmitting them,
#' using serialize(ascii=TRUE,...). serialize() has a maximum object size of
#' 2^31 - 1 bytes. R objects can exceed this size.  Furthermore, the
#' serialized version of an object is larger than the object it represents.
#' To move large objects, rreval supports scp tranfers. E.g. use
#' save() to write an object to disk, scpUpload() or scpDownload() to tranfer
#' the object, then load() to restore it.  Note that for large objects
#' scp is considerably faster than upo().
#'
#' @author Barnet Wagman
#' @export
#' @param obj the object to be uploaded to the R session on the server.
#' @param hostName hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
upo <- function(obj,hostName=NULL,userName=NULL) {
  uploadObject(objName=paste(substitute(obj)),obj=obj,
               hostName=hostName,userName=userName);
}

# --------- scp functions ----------------------------------------

#' Upload a file to the remote host
#'
#' This function returns after the transfer has been initiated. Use file.info()
#' to determine when the transfer is complete.
#'
#' @author Barnet Wagman
#' @export
#' @param filenames Names of files to be uploaded (character array).  If 
#' useLocalDir == FALSE, these must be fully qualified path names.
#' @param remoteDir Target directory on the remote host.  If NULL, files are copied
#' to the working directory of the remote session (per getwd()).
#' @param useLocalDir if TRUE and file names are not fully qualified
#' pathnames, files are copied from the current working of the local R session.
#' @param hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
scpUpload <- function(filenames,
                      remoteDir=NULL,
                      useLocalDir=TRUE,
                      hostName=NULL,
                      userName=NULL
                      ) {
  
  con <- getOpenCon(hostName=hostName,userName=userName);
  if ( is.null(con) ) noConStop(hostName=hostName,userName=userName);
  
  if ( useLocalDir ) localDir <- paste(getwd(),"/",sep="")
  else localDir <- "";
  
  if ( is.null(remoteDir) ) rd <- re(getwd())
  else rd <- remoteDir;
  
  for ( fn in filenames ) {            
      localPath <- paste(localDir,fn,sep="");
      ac <- createAppCmd(cmdName="uploadFile",
                         params=c(paste("localFile",localPath,sep="="),
                                  paste("remoteDir",rd,sep="="))
                         );
      print( sendAppCmd(con=con,cmd=ac) );
  } 
}

#' Download a file from the remote host
#'
#' This function returns after the transfer has been initiated. Use file.info()
#' to determine when the transfer is complete.
#'
#' @author Barnet Wagman
#' @export
#' @param filenames Names of files to be downloaded (character array).  If 
#'     useRemoteCwd == FALSE, these must be fully qualified path names.
#' @param localDir Target local directory. If NULL, files are copied 
#'     to the working directory of the local session (per getwd()).
#' @param useRemoteCwd if TRUE and file names are not fully qualified
#' pathnames, files are copied from the current working of the remote R session.
#' @param hostName the name of the host where the rre server is running;
#' usually NULL (the default).  If this param (or userName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
#' @param userName the name of user on remote host that is running rreServer;
#' usually NULL (the default). If this param (or hostName) is NULL, the
#' function will attempt to retrieve a connection from the connection 
#' manager environment.  This param needs to be supplied only
#' if you have connected to more than one rreval server in the current
#' R session.
scpDownload <- function(filenames,
                        localDir=NULL,
                        useRemoteCwd=TRUE,
                        hostName=NULL,
                        userName=NULL) {
  
  con <- getOpenCon(hostName=hostName,userName=userName);
  if ( is.null(con) ) noConStop(hostName=hostName,userName=userName);
  
  if ( useRemoteCwd ) remoteDir <- paste(re(getwd()),"/",sep="")
  else remoteDir <- "";
  
  if ( is.null(localDir) ) lod <- getwd()
  else lod <- localDir;
  
  for ( fn in filenames ) {
      remotePath <- paste(remoteDir,fn,sep="");
      ac <- createAppCmd(cmdName="downloadFile",
                         params=c(paste("remoteFile",remotePath,sep="="),
                                  paste("localDir",lod,sep="="))
                        );
      print( sendAppCmd(con=con,cmd=ac) );
  }  
}

# ------------- Cmd functions ---------------------------------

#' createAppCmd
#'
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param cmdName
#' @param params
#' @param delim
#' @return the command with delemited params.
createAppCmd <- function(cmdName,params=NULL,delim="&") {
  cmd <- paste("cmd=",cmdName,sep="");
  if ( !is.null(params) ) {
    for ( par in params ) {
      cmd <- paste(cmd,delim,par,sep="");
    }
  }
  cmd
}

#' sendAppCmd
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param cmd
#' @param maxWaitSecs
sendAppCmd <- function(con,cmd,maxWaitSecs=-1) {  
  writeMessage(con=con,messageType=mType$commandToJ,obj=cmd,nMaxTries=1);
  readMessage(con,maxWaitSecs=maxWaitSecs)  
}
  
#' sendAppCmd
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param hostName
#' @param userName
#' @param portRJ
#' @param portJJ
#' @param pemFile
#' return con
createAppConnectCommand <- function(hostName,userName,
                                    portRJ,portJJ,
                                    pemFile) {
  createAppCmd(cmdName="connectToRReServer",
                params=c(paste("hostName",hostName,sep="="),
                         paste("userName",userName,sep="="),
                         paste("portRJ",portRJ,sep="="),
                         paste("portJJ",portJJ,sep="="),
                         paste("pemFile",pemFile,sep="=")
                        )
  )
}

# ------------- Connection functions ----------------------------

#' connectToClientApp
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param port
#' @param timeout
#' @return con
connectToClientApp <- function(port,timeout) {  
  while(TRUE) {
    con <- tryCatch(connectToApp(port=port,timeout=timeout),
                    error=function(e) { return(NULL); },
                    warning=function(e) { return(NULL); }
                    );
    if ( isGoodCon(con) ) return(con);
    if (verboseOn() ) print("... waiting for client app.");
    Sys.sleep(1);
  }  
}

#' putOpenCon
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param hostName
#' @param userName
#' @param port
putOpenCon <- function(con,hostName,userName,port) {
  
  if ( !exists("conManagerEnv",envir=.GlobalEnv) ) {
    assign(x="conManagerEnv",value=new.env(),envir=.GlobalEnv);
  }
  assign(x=paste(hostName,userName,sep="."),
         value=list(hostName=hostName,userName=userName,port=port,
                    cono=con),
         envir=conManagerEnv);  
}

#' getOpenConObjKey
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param key
#' @return connection
getOpenConObjKey <- function(key) {  
  if (exists("conManagerEnv") && 
      exists(x=key,envir=conManagerEnv) ) {
      return( get(x=key,envir=conManagerEnv) );     
  }
  else { return(NULL); } 
}

#' getOpenConObj
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param key
#' @return connection
getOpenConObj <- function(hostName=NULL,userName=NULL) {
  if ( is.null(hostName) || is.null(userName) ) {
    return(getFirstOpenConObj());
  }
  else {
    key <- paste(hostName,userName,sep=".");
    getOpenConObjKey(key)
  }
}
  
#' getFirstOpenConObj
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @return connection
getFirstOpenConObj <- function() {
  if ( exists("conManagerEnv") &&
       (length(keys <- ls(envir=conManagerEnv)) > 0)
     ) {   
     return(getOpenConObjKey(keys[1]));
  }
  else { return(NULL); }     
}

#' getOpenCon
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param hostName
#' @param userName
#' @return connection
getOpenCon <- function(hostName=NULL,userName=NULL) {
  
  co <- getOpenConObj(hostName=hostName,userName=userName);
  if ( !is.null(co) && hasEl(x=co,name="cono") && isGoodCon(co$cono) ) {
      return(co$cono);
  }
  else { return(NULL); }
}
  
#' clearRReInput
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @return text
clearRReInput <- function(con) {
  
  n <- 0;
  s <- "";
  while (TRUE) {
    x <- readChar(con,1024);
    if ( length(x) < 1 ) {
      print(n);
      return(s);
    }
    else {
      n <- n + sum(nchar(x));
      s <- paste(s,x,sep="");
    }
  }
}