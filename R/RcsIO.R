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

#    RcsIO.R
#
#    Function that handle rreval client-server communitions.
#
#    Objects exchanged between the rreval client and server are rcsMessages
#    which are lists. Note that these are actually transmitted wrapped
#    in messages as specified in MessageNio.R.  
#
#    At a minimum, an rcsMessage has elements "rcsM", "type" and "val"
#
#    ---------------------------------------------------------------------

#' defineRcsMessageTypes
#' @keywords internal
#' @export
#' @author Barnet Wagman
defineRcsMessageTypes <- function() {
  
  assign(x="mTypeRcs",value=new.env(),envir=.GlobalEnv);
  
  assign(x="EXPR",value="EXPR",envir=mTypeRcs);
  assign(x="EVAL.RESULT",value="EVAL.RESULT",envir=mTypeRcs);
  assign(x="OBJ",value="OBJ",envir=mTypeRcs);
  assign(x="SINK.OUTPUT",value="SINK.OUTPUT",envir=mTypeRcs);
  assign(x="ERR",value="ERR",envir=mTypeRcs);
  assign(x="OBJ.ACK",value="OBJ.ACK",envir=mTypeRcs);
}

#' Sends an rcsMessage from client to server. Sending a message
#' to the server always elicits a reply. This function does not return
#' until it receives a non-SINK.OUTPUT message (which it prints immediately)
#' or an error (which yields a stop).
#' if the reply is an error. 
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param con
#' @param rcsMessage
#' @param maxWaitSecs
#' @return value
sendToRReServer <- function(con,rcsMessage,maxWaitSecs=-1) {
  
  if ( !isRcsMessage(rcsMessage) ) {
    stop(simpleError("Not an rcs message: ", rcsMessage));
  }
  
  writeMessage(con=con,messageType=mType$messageToR,obj=rcsMessage);
  
  obj <- readMessage(con=con,maxWaitSecs=maxWaitSecs);
  
  while (TRUE) { # The loop is used to print sink output while waiting for
                 # the operation to finish.
    if ( isRcsMessage(obj) ) {
      if ( isRcsType(m=obj,type=mTypeRcs$SINK.OUTPUT) ) {
        print(obj$val);
      }
      else if ( isRcsType(m=obj,type=mTypeRcs$EVAL.RESULT) ) {
        return(m$val);  
      }
      else if ( isRcsType(m=obj,type=mTypeRcs$OBJ) ) {
        return(m$val);  
      }
      else if ( isRcsType(m=obj,type=mTypeRcs$ERR) ) {
        stop(simpleError(m$val));    
      }
      else {
        stop(simpleError(paste("Received rcs message with undefined type=",
                               obj$type," val=",obj$val,sep="")));
      }
    }
    else { # It is and error from the app, in text.
        stop(simpleError(obj));
    }
  }
}

#' createRcsMessage
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param type
#' @param val
#' @return message
createRcsMessage <- function(type,val) {
  list(rcsMessage=TRUE,
       type=type,
       val=val)
}

#' Creates an rcs message that contains an expression for remote
#' evaluation.  Note that the message createe by this funtion 
#' includes maxBytesReturnable element.
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param type
#' @param maxBytesReturnable
#' @return message
createExprMessage <- function(expr,
                              maxBytesReturnable=NULL) {
    l <- createRcsMessage(type=mTypeRcs$EXPR,val=expr);
    l$maxBytesReturnable <- maxBytesReturnable;
    l
}

#' createRcsObjMessage
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param objName
#' @param obj
#' @return message
createRcsObjMessage <- function(objName,obj) {
  createRcsMessage(type=mTypeRcs$OBJ,
                   val=list(objName=objName,obj=obj)
                   )
}

#' isRcsMessage
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param x
#' @return boolean
isRcsMessage <- function(x) {
  hasEl(x=x,name="rcsMessage")  &&
  hasEl(x=x,name="type") &&
  hasEl(x=x,name="val")
}

#' isRcsType
#' @keywords internal
#' @export
#' @author Barnet Wagman
#' @param m
#' @param type
#' @return boolean
isRcsType <- function(m,type) {
  m$type == type
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
