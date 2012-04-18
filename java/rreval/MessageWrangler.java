/*
    Copyright 2012 Northbranchlogic, Inc.

    This file is part of Remove R Evaluator (rreval).

    rreval is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    rreval is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with rreval.  If not, see <http://www.gnu.org/licenses/>.
 */
package rreval;

import com.norbl.util.*;

/**
 *
 * @author moi
 */
public class MessageWrangler {
    
    protected ConnectionR conR;
    protected ConnectionJ conJ;
    
    public MessageWrangler() {}
    
    public void setConR(ConnectionR conR) { this.conR = conR; }
    public void setConJ(ConnectionJ conJ) { this.conJ = conJ; }
    
    protected Message createWrongTypeErrorMessage(Message m) {
        
        String typeS;
        if ( m != null ) {
            if ( m.type != null ) typeS = m.type.toString();
            else typeS = "null type";
        }
        else typeS = "null message";
        
        return( new Message(MessageType.er,
                            "Error: undefined or inapproriate message type=" + 
                            typeS) );
    }            
    
   protected void sendErrMToR(String m) {
       try {
           conR.writeMessage(new Message(MessageType.er,m));
           Verbose.show("ClientCmdHandler sending error message to " +
                        "client failed: " + m);
       }
       catch(Exception z) { 
            System.err.println(StringUtil.toString(z));
       }
   }  
    
   protected void sendErrMToR(Exception x) {
       sendErrMToR(StringUtil.getExceptionMessage(x));
   }
   
   protected void sendErrMToR(String prefix, Exception x) {
       sendErrMToR(prefix + ": " + 
                   StringUtil.getExceptionMessage(x) + "\n" +
                   StringUtil.exceptionStackToString(x));
   } 
    
   protected void sendMessageToR(String m) {
       try {
           if ( (m == null) || (m.length() < 1) ) m = " ";
           conR.writeMessage(new Message(MessageType.rj,m));          
       }
       catch(Exception z) { 
            System.err.println(StringUtil.toString(z));
       }
   }    
}
