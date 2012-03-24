#
#    Copyright 2012 Northbranchlogic, Inc.
#
#    This file is part of rreval.
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

#    MessageNio.R
#
#    Functions for communications between rreva client, server and
#    supporting java apps.  All communications are contained in 'messages',
#    which can be handled by the java apps. Messages have types, defined
#    in defineMessageTypes().
#
#    Note that objects exchanged by the rreval client and server 
#    are of types 'messageToR' ("mr").  The 'obj' component of
#    these messages is itself a rcsMessage (a list) - see RcsIO.R.

#' defineMessageTypes
#' @keywords internal
#' @export
#' @author Barnet Wagman
defineMessageTypes <- function() {
  
    # mTypes
  assign(x="mType",value=new.env(),envir=.GlobalEnv);
  
  assign(x="commandToJ",value="cj",envir=mType);
  assign(x="commandToR",value="cr",envir=mType);
  assign(x="messageToR",value="mr",envir=mType);
  assign(x="replyFromJ",value="rj",envir=mType);
  assign(x="error",value="er",envir=mType);
  assign(x="ppeManagerCmd",value="pc",envir=mType);  
}


  # ----------- Basic IO ------------------------------------------
#' writeString
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param s
#' @param messageType
#' @param maxWaitForAcks
#' @return the number of chars written, if successful, else an error 
#'         is thrown.
writeString <- function(con,s,messageType,maxWaitForAckSecs=3) {
  
  n <- nchar(s);
  md5 <- digest(object=s,algo="md5",serialize=FALSE,ascii=TRUE);
  
    # Send the message type
  writeChar(con=con,object=messageType,nchars=nchar(messageType));
    
    # Send the obj length as a left padded 32 char string.            
  writeChar(object=padLeft(paste(n),32),con=con,nchars=32);
  
    # Send the obj
  writeChar(object=s,con=con,nchars=n);
  
    # Send the md5
  writeChar(object=md5,con=con,nchars=32);
 
  if ( verboseOn() ) print(paste("writeString ... awaiting ack."));
  ack <- readAck(con,maxWaitSecs=maxWaitForAckSecs);
  if ( verboseOn() ) print(paste("writeString got ack=",ack));
                  
  if ( ack == "y" ) return(n)
  else stop(simpleError(paste("Write failed (ack=",ack,")")));
}

#' readAck
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param maxWaitSecs
readAck <- function(con,maxWaitSecs=2) {
  
  tmFin <- Sys.time() + maxWaitSecs;
  
  while ( Sys.time() <= tmFin ) {
    x <- readChar(con=con,nchars=1);
    if ( length(x) == 1 ) { # Rem: this means one string received, not one char
      return(x);
    }
  }
    
  sx <- "readAck() ";
  if ( exists("x") ) sx <- paste(sx,"len=",length(x),sep="");
  stop(createTimeoutException(sx));  
}

#' writeMessage
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param messageType
#' @param obj
#' return number of chars written.
writeMessage <- function(con, messageType, obj, 
                         nMaxTries=16, maxWaitForAckSecs=2) {
  
  if ( messageType == mType$messageToR ) { # Serialize the obj
    s <- serializeToString(obj);
    #unserializeFromString(s=s);
    testSerialization(s);
    # ^ Test for bad serialization
  }
  else { # The obj is (well should be) plain text, so
    s <- obj;
  }
  
  nt <- nMaxTries - 1;
  if ( nt > 0 ) {
    for ( i in 1:nMaxTries ) {
        n <- tryCatch( writeString(con=con,s=s,messageType=messageType,
                                   maxWaitForAckSecs=maxWaitForAckSecs),
                       error=function(e) { return(-1); }
                      );
        if ( n > 0 ) return(n);
    }
  }
  writeString(con=con,s=s,messageType=messageType,
              maxWaitForAckSecs=maxWaitForAckSecs)  
}

#' writeSObjMessage
#' This is a version of writeMessage that creates and sends a message
#' containing an object that has already been serialized (and tested)
#' using ascii serialization.
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param messageType
#' @param sobj
#' return number of chars written.
writeSObjMessage <- function(con, messageType, sobj, 
                             nMaxTries=16, maxWaitForAckSecs=2) {
  nt <- nMaxTries - 1;
  if ( nt > 0 ) {
    for ( i in 1:nMaxTries ) {
        n <- tryCatch( writeString(con=con,s=sobj,messageType=messageType,
                                   maxWaitForAckSecs=maxWaitForAckSecs),
                       error=function(e) { return(-1); }
                      );
        if ( n > 0 ) return(n);
    }
  }
  writeString(con=con,s=sobj,messageType=messageType,
              maxWaitForAckSecs=maxWaitForAckSecs)
}


#' testSerialization
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param s
testSerialization <- function(s) {
  tryCatch(unserialize(connection=charToRaw(s)),
           error=function(e) {
             stop((simpleError(paste("RSERVER-SIDE SER TEST ERROR",
                                     e$message))));
           });
}

#' Reads a message, waiting the specified time, possibly forever.
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param maxWaitSecs
#' @return the message obj.
readMessage <- function(con,maxWaitSecs=-1) {
  
  tmFin <- Sys.time() + maxWaitSecs;
  if ( verboseOn() ) print("readMessage() about to readM()");
  while ( (maxWaitSecs < 0) || (Sys.time() <= tmFin) ) {
    
    m <- tryCatch(readM(con),
                  error=function(e) {
                    if ( isTimeoutException(e) ) {
                      return("TIMEOUT_FLAG");
                    }
                    else { 
                      if (verboseOn()) print(e);  
                      return(NULL); }
                  }
                  );
    if ( !is.null(m) ) { # It's either a good obj or a timeout
      if ( (length(m) == 1) && (m == "TIMEOUT_FLAG") ) {
        if ( verboseOn() ) print(m);
      }
      else {
        if ( verboseOn() ) print("readMessage() back from readM() sending ack y");
        sendAck(con,"y");
        if ( verboseOn() ) print("readMessage() back from sending ack y");
        return(m);
      }
    }
    else { # Error
      if ( verboseOn() ) print("readMessage() NULL m sending ack n");
      sendAck(con,"n"); 
      if ( verboseOn() ) print("readMessage() back from sending ack n");
    }    
  }
  stop(simpleError(paste("Timed out reading message.")));          
}

#' sendAck
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param ack
sendAck <- function(con,ack) {
  writeChar(object=ack,con=con,nchars=1);
}

#' readM
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @return message
readM <- function(con) {
  
      # Read the type
    mt <- readChar(con=con,nchars=2);
    if ( length(mt) != 1 ) { # Timout. This is not necessarily an error
      stop(createTimeoutException());    
    } 
    else if (nchar(mt) != 2 ){
        if ( verboseOn() ) print(paste("readM() Bad mt=",mt));
        eatLeftovers(con);
        stop(simpleError(paste("Bad mt=",mt)));
    }
    
        # Read the obj length
    len <- as.numeric(readChar(con=con,nchars=32));
    if ( !is.numeric(len) || (len < 1) ) {
      if ( verboseOn() ) print(paste("Bad len=",len));
      eatLeftovers(con);
      stop(simpleError(paste("Bad len=",len)));
    }
    
     # Read the obj
    obj <- readChar(con=con,nchars=len);
    if ( (length(obj) != 1) || (nchar(obj) != len) ) {
      if ( verboseOn() ) print(paste("Bad obj"));
      eatLeftovers(con);
      stop(simpleError(paste("Bad obj")));
    }
    
    if ( mt == mType$messageToR ) { # "mr" The message is from R and needs to be deserialized
      return(unserializeFromString(obj));
    }
    else if ( (mt == mType$replyFromJ) || (mt == mType$error) ||
              (mt == mType$commandToR) ) {
        return(obj); # obj is plain text
    }    
    else { 
      stop(paste("Undefined message type=",mt," obj=",obj,sep=""));
    }
}

#' eatLeftovers
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param maxBites
eatLeftovers <- function(con,maxBites=2*1024) {
  
  for ( i in 1:maxBites ) {
    x <- readChar(con=con,nchars=16 * 1024);
    if ( length(x) < 1 ) return;
  }
}

  # ----------- Utils ------------------------------------------

#' padLeft
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param s
#' @param padLen
#' @param padChar
#' @return string
padLeft <- function(s,padLen,padChar=" ") {
  n <- padLen - nchar(s);
  if ( n <= 0 ) { return(s); }
  else {
    for ( i in 1:n ) {
      s <- paste(padChar,s,sep="");
    }
    return(s);
  }
}

#' serializeToString
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param obj
#' @return string
serializeToString <- function(obj) {
  rawToChar(serialize(object=obj,connection=NULL,ascii=TRUE))
}

#' unserializeFromString
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param s
#' @return object
unserializeFromString <- function(s) {  
  unserialize(connection=charToRaw(s))
}

#' create timeout exception
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param message
#' @return exception
createTimeoutException <- function(message=NULL) {
  s <- "Timeout EXCEPTION";
  if ( !is.null(message) ) s <- paste(s,message);
  simpleError("Timeout EXCEPTION")
}

#' isTimeoutException
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param x
#' @return boolean
isTimeoutException <- function(x) {
  is.list(x) &&
  hasEl(x=x,name="message") &&
  containsString(s=x$message,pattern="Timeout EXCEPTION")
  #(x$message == "Timeout EXCEPTION")
}

#' Test for list with specfied named element,
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param x
#' @param name
#' @return boolean
hasEl <- function(x,name) {  
  !is.null(name) && !is.null(x) &&
  is.list(x) &&
  (sum(names(x) == name) > 0)    
}

#' containsString
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param s
#' @param pattern
#' @return boolean
containsString <- function(s,pattern) {
  length(grep(pattern=pattern,x=s)) > 0
}

#' setVerbose
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param vb
setVerbose <- function(vb=FALSE) {
  assign(x="verbose",value=vb,envir=.GlobalEnv);
}


#' verboseOn
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @return boolean
verboseOn <- function () {  
  if ( !exists(x="verbose",envir=.GlobalEnv) ) {
    return(FALSE);
  }
  else {
    return(get(x="verbose",envir=.GlobalEnv));
  }  
}

#' getRRevalJavaAppClassPath
#' This function gets the names of all jars in the 'jars' directory 
#' of the specified package
#' @param packageName
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @return Java classpath as character.
getJavaAppClassPath <- function(packageName) {
  # TEST ONLY  
  #return(paste("/home/moi/h/ppe/projects/rreval_201202/dist/rreval_201202.jar",
  #             "/home/moi/h/ppe/foreign/ganymed-ssh2-build251beta1/ganymed-ssh2-build251beta1.jar",
  #             "/home/moi/h/ppe/projects/utilssh/dist/utilssh.jar",
  #             "/home/moi/h/sw_projects/utilj_2011_05/dist/utilj_2011_05.jar",
  #             "/home/moi/h/ppe/projects/cloudrmpi_201201/dist/cloudrmpi_201201.jar",
  #             "/home/moi/h/ppe/projects/ppe_201201/dist/ppe_201201.jar",
  #             sep=":"));
      
  jarDir <- paste(.find.package(packageName),"/jars",sep="");
  jarNames <- list.files(path=jarDir,pattern=".jar");
  
  cp <- "";
  for ( i in 1:length(jarNames) ) {
    cp <- paste(cp,jarDir,"/",jarNames[i],sep="");
    if ( i < length(jarNames) ) cp <- paste(cp,":",sep="");
  }
  cp
}


  # ------------ Connection functions ---------------------------

#' connectToApp
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param port
#' @param timeout
#' @return connections
connectToApp <- function(port,timeout) {
    socketConnection(port=port,
                     server=FALSE,
                     blocking=TRUE,
                     open="a+",
                     timeout=timeout)
}

#' isGoodCon
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' return boolean
isGoodCon <- function(con) {
  !is.null(con) && isOpenEh(con)
}

#' isOpen() sometimes throws 'invalid connection' error: this wrapper
#' returns FALSE when an error occurs.
#'
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @return boolean
isOpenEh <- function(con) {
  tryCatch(isOpen(con),
           error=function(e) { return(FALSE); },
           finally={}
           )
}


#' closeEh
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @return NULL
closeEh <- function(con) {
  tryCatch(close(con),
           error=function(e) {
             print(e);
             return(NULL);
           })
}

#' trim
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @return string
trim <- function(s) {
  gsub("(^ +)|( +$)", "",s)
}
