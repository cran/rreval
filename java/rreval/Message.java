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

import java.io.*;
import java.math.*;

/**
 *
 * @author Barnet Wagman
 */
public class Message implements Serializable {
    static final long serialVersionUID = 1L;
   
    public static String CONNECT_TO_RRESERVER = "connect to RReServer";
    public static String HAS_CONNECTED = "has connected to RReServer";
    public static String RRESERVER_NOT_AVAILABLE = 
                                    "The RReServer is not available";
    public static String DISCONNECT_FROM_CLIENT_APP = 
                                     "disconnect from client app";
    
    public MessageType type;
    public String obj;
    public BigInteger md5;
    
    public Message(MessageType type, String obj,BigInteger md5) {
        this.type = type;
        this.obj = obj;
        this.md5 = md5;
    }
    
    public Message(MessageType type, String obj) {
        this.type = type;
        this.obj = obj;
        this.md5 = MD5Util.calcMD5(obj);
    }
    
    public String toString() {
        return("type=" + type + " md5=" + md5.toString(16) + 
                " length=" + obj.length() + " " + toShortString(obj));                
    }
    
    public boolean isMessageToR() {
        return( MessageType.mr.equals(type) );
    }
    
    public boolean isAppCmd() {
        return( MessageType.cj.equals(type) );
    }
    
    public boolean isRReServerCmd() {
        return( MessageType.cr.equals(type) );
    }  
    
    private String toShortString(String s) {
        return( s.substring(0,Math.min(s.length()-1,64)) );
    }
   
        // -----------------------------------------------------
    
    public boolean isConnectedMessage() {
        return( MessageType.rj.equals(type) &&
                HAS_CONNECTED.equals(obj)
              );
    }
    
    public boolean isNotAvailableMessage() {
        return( MessageType.rj.equals(type) &&
                RRESERVER_NOT_AVAILABLE.equals(obj)
              );
    }
     
    public boolean isConnectCmdMessage() {
        return( MessageType.cj.equals(type) &&
                HAS_CONNECTED.equals(obj)
              );
    } 
    
    public boolean isDisonnectCmdMessage() {
        return( MessageType.cj.equals(type) &&
                DISCONNECT_FROM_CLIENT_APP.equals(obj)
              );
    } 
     
        // -----------------------------------------------------
     
    public static Message createConnectToRReServerMessage() {
        return( new Message(MessageType.cj,CONNECT_TO_RRESERVER) );
    } 
    
    public static Message createRReServerNotAvailableMessage() {
        return( new Message(MessageType.rj,RRESERVER_NOT_AVAILABLE) );
    } 
    
    public static Message createConnectedToRReServerMessage() {
        return( new Message(MessageType.rj,CONNECT_TO_RRESERVER) );
    } 
    
    public static Message createDisconnectFromClientMessage() {
        return( new Message(MessageType.cj,DISCONNECT_FROM_CLIENT_APP) );
    }
}
