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
#    along with ppe.  If not, see <http://www.gnu.org/licenses/>.
#
#    ----------------------------------------------------------------------
#
#    RReServer.R
# 
#    ----------------------------------------------------------------------

#' rre server
#'
#' The server evaluates expressions received from a 'client' remote R session
#' (sent using the re() function.)  Expressions are evaluated in
#' .GlobalEnv. The server can also receive objects sent by the
#' client using the upo() function; objects are assigned to the specified name
#' in .GlobalEnv.
#' 
#' The rreServer handles commands from one client at time.  Once a client has
#' connected to the server (using rre.startClient(), it has exclusive use of 
#' the server until it disconnects (using rre.closeClient()).
#' Once invoked, rreServer() runs forever.
#'
#' @export
#' @author Barnet Wagman
#' @param portRJ number of the port used for communications with 
#' rreval.RReServerApp, the java app that handles communications
#' with the remote client (rreval.RReServerApp is launched by rreServer()).
#' @param portJJ number of the port used by the java app rreval.RReServerApp
#' to communicate with the the rreval.RReClientApp, the client side java app.
#' @param workingDir the local directory to be used as the working directory;
#' if not NULL, rreServer() calls setwd(workingDir).
#' @param timeout socket timeout (in seconds).
#' @param verbose for debugging.
#' @param launchApp if TRUE (the default), rreServer() launches the
#' java app, rreval.RReServerApp.  Otherwise the app is assumed to already
#' be running. (launchApp=FALSE is primarily for debugging.)
rreServer <- function(portRJ=4463,
                      portJJ=4464,
                      workingDir=NULL,
                      timeout=2,                      
                      verbose=FALSE,
                      launchApp=TRUE
                      ) {
  assign(x="verbose",value=verbose,envir=.GlobalEnv);   
  defineMessageTypes();
  defineRcsMessageTypes();
      
  if ( !is.null(workingDir) ) setWorkingDir(workingDir=workingDir);
  
    # Launch the app
  if ( launchApp ) {
    launchRReServerApp(portRJ=portRJ,portJJ=portJJ);
    if ( verboseOn() ) print(paste("launched RReServerApp"));
  }
  
     # Connect to the conduit
  con <- connectToServerApp(port=portRJ,timeout=timeout);
  if (verboseOn()) print(paste("Connected to app on port=",portRJ));
  
    # Setup 
  
  while (TRUE) {
    
    obj <- tryCatch(readMessage(con=con),
                  error=function(e) {
                    if ( verboseOn() ) print(e);
                    return(NULL);
                  });
    if ( !is.null(obj) ) {
      if (verboseOn()) print("Got non-null obj");
      if ( isRcsMessage(obj) ) {
        if (verboseOn()) print("    Got rcs message");
        if ( isRcsType(m=obj,type=mTypeRcs$EXPR) ) {
          if (verboseOn()) print("    got expression");
          handleExpression(con=con,obj=obj);
        }    
        else if ( isRcsType(m=obj,type=mTypeRcs$OBJ) ) {
          if (verboseOn()) print("    got obj");
          handleObject(con=con,obj=obj);
        }
        else {
          sendUnexpectedMessageError(con=con,obj=obj);
        }
      }      
      else {
          sendUnexpectedMessageError(con=con,obj=obj);
      }
    }
    else { # NULL implies timeout
      Sys.sleep(0.25);
    }
  }
}

#' handleExpression
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param obj
handleExpression <- function(con,obj) {  
  tryCatch(evalExpression(con=con,
                          expr=obj$val,
                          maxBytesReturnable=getMaxBytesReturnable(obj)),
           error=function(e) {
                    sendEvalError(con=con,val=e);
                 }
          );
}

#' getMaxBytesReturnable
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param m rcs message of type EXPR
#' @return maximum size (in bytes) of a returnable object.
getMaxBytesReturnable <- function(m,
                                  maxBytesReturnableDefault=2^16) {
  if ( hasEl(x=m,name="maxBytesReturnable") ) {
    mb <- m$maxBytesReturnable;
    if ( mb >= 0 ) { return(mb); }
    else { return(maxBytesReturnableDefault); }
  }  
  else { return(maxBytesReturnableDefault); }
}

#' handleObject
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param obj
handleObject <- function(con,obj) {
  tryCatch(assignAndReply(con=con,val=obj$val),
           error=function(e) {
                    sendEvalError(con=con,val=e);
                 }
  );
}

#' sendUnexpectedMessageError
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param obj
sendUnexpectedMessageError <- function(con,obj) {
  writeMessage(con=con,
               messageType=mType$error,
               obj=paste("RReServer received unexpected message ",
                         "containing obj=",obj,sep="")
               );
}

#' evalExpression
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param expr
#' @param maxBytesReturnable
#' @return value
evalExpression <- function(con,expr,maxBytesReturnable) {
  
  sinkStart();
  
  x <- tryCatch(result <- eval(expr=expr,envir=.GlobalEnv),
                error=function(e) { 
                  sink(NULL);
                  return(e); 
                  }
                );
  sink(NULL);
  so <- getSinkOutput();
  
  if ( exists("result") ) { # Evaluation was successful, return the result
      sendEvalResult(con=con,
                     val=result,
                     maxBytesReturnable=maxBytesReturnable,
                     so=so);
  }
  else if ( exists("x") ) { # error
      sendEvalError(con=con,val=x,so=so);
  }
  else {
     sendEvalError(con=con,
                   val="eval(",paste(expr),") failed but no error was thrown.",
                   so=so
                   );                   
  }  
}

#' assignAndReply
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param value
assignAndReply <- function(con,val) {
  
  assign(x=val$objName,value=val$obj,envir=.GlobalEnv);
  
  mr <- createRcsMessage(type=mTypeRcs$OBJ.ACK,
                         val=paste("assigned",val$objName)
                         );
  writeMessage(con=con,messageType=mType$messageToR,obj=mr);    
}

#' sendEvalResults
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param val
#' @param maxBytesReturnable
#' @param so
sendEvalResult <- function(con,
                           val,
                           maxBytesReturnable,
                           so=NULL) {  
  sendEvm(con=con,
          type=mTypeRcs$EVAL.RESULT,
          val=val,
          maxBytesReturnable=maxBytesReturnable,
          so=so);
}

#' sendEvalErro
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param val
#' @param so
sendEvalError <- function(con,val,so=NULL) {  
  sendEvm(con=con,
          type=mTypeRcs$ERR,
          val=val,
          maxBytesReturnable=Inf,
          so=so);
}

#' sendEvm
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param type
#' @param val
#' @param maxBytesReturnable
#' @param so
sendEvm <- function(con,type,val,maxBytesReturnable,so) {
  
    # First try message with val and sink obj
  sm <- createSerializedMessage(type=type,val=val,so=so);
  
  if ( nchar(sm) > maxBytesReturnable ) { # Try it without the val
    sm <- createSerializedMessage(type=type,val=NULL,so=so);
    if ( nchar(sm) > maxBytesReturnable ) { # Omit so as well
      sm <- createSerializedMessage(type=type,val=NULL,so=NULL);
    }
  }
  
    # Test the serialization
  testSerialization(sm);
  
  if (verbose) print(paste("RReServer.sendEvm() len(sm)=",
                           nchar(sm)," max=",maxBytesReturnable));
  
  writeSObjMessage(con=con,messageType=mType$messageToR,sobj=sm);
}

#' sendEvm.v0
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param val
#' @param maxBytesReturnable
#' @param so
sendEvm.v0 <- function(con,type,val,maxBytesReturnable,so) {
  
  mr <- createRcsMessage(type=type,val=val);
  mr$sinkOutput <- so;
  
  # Test the the size of the object to be returned.  This
  # requires serializing mr
  sobj <- serializeToString(mr);
  testSerialization(sobj);      
        
  if (verbose) print(paste("RReServer.sendEvm() len(sobj)=",
                           nchar(sobj)," max=",maxBytesReturnable));
  
  if ( nchar(sobj) <= maxBytesReturnable ) { # We can return the obj  
    writeSObjMessage(con=con,messageType=mType$messageToR,sobj=sobj);
  }
  else { # Return a message with NULL for the returned val
    mr <- createRcsMessage(type=type,val=NULL);
    mr$sinkOutput <- so;
    writeMessage(con=con,messageType=mType$messageToR,obj=mr);
  }
}


#' Create serialized message
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param type
#' @param val
#' @param maxBytesReturnable
#' @return serialized message
createSerializedMessage <- function(type,val,so) {
  mr <- createRcsMessage(type=type,val=val);
  mr$sinkOutput <- so;
  serializeToString(mr)
}

# -------------------------------------------------------------

#' launchRReServerAccessApp
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param portRJ
#' @param portJJ
launchRReServerApp <- function(portRJ=4463,portJJ=4464) {  
  
  cmd <- paste("java -classpath ",getJavaAppClassPath("rreval"),
               " rreval.RReServerApp",
               " portRJ=",portRJ,
               " portJJ=",portJJ,
               sep=""
               );
  
  system(cmd,intern=FALSE,wait=FALSE,ignore.stderr=TRUE,ignore.stdout=TRUE);
}

#' connectToServerApp
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param port
#' @param timeout
#' @return connection
connectToServerApp <- function(port,timeout) {  
  while(TRUE) {
    con <- tryCatch(connectToApp(port=port,timeout=timeout),
                    error=function(e) { return(NULL); },
                    warning=function(e) { return(NULL); }
                    );
    if ( isGoodCon(con) ) return(con);
    if (verboseOn() ) print("... waiting for server app.");
    Sys.sleep(1);
  }  
}

#' sinkStart
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param filename
sinkStart <- function(filename="/tmp/rre_server_tmp_sink_file.txt") {
    sink(file=filename,append=FALSE,type="output",split=TRUE);
}

#' getSinkOutput
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param filename
#' @return text
getSinkOutput <- function(filename="/tmp/rre_server_tmp_sink_file.txt") {
  if ( file.exists(filename) ) {
    con <- file(filename);     
    txt <- tryCatch(readLines(con),
                    error=function(e) { return(NULL); },
                    warning=function(w) { return(NULL); }
                    );
    tryCatch(close(con),
             error=function(e){return()},
             warning=function(w){return()}
             );    
    
    if ( length(txt) > 0 ) return(txt)
    else return(NULL);    
  }
  else { return(NULL); }
}

#' setWorkingDir
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param workingDir
setWorkingDir <- function(workingDir) {
  
  if ( file.exists(workingDir) ) {
    tryCatch(setwd(dir=workingDir),
             error=function(e) { print(e$message) }
            );
  } 
}
