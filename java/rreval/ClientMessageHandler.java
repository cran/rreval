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

import java.net.*;
import com.norbl.util.*;

/**
 *
 * @author moi
 */
public class ClientMessageHandler extends MessageWrangler
    implements Runnable {    
    
    protected Socket socketR;
    protected RReClientApp parentApp;   
    
    protected ClientCmdHandler cmdHandler;
    protected ConduitClientSide conduit;
    
    protected boolean keepRunning;
    
     public ClientMessageHandler(Socket socketR,RReClientApp parentApp) {        
        this.socketR = socketR;
        this.parentApp = parentApp;           
    }
     
    protected ClientMessageHandler() {} 
    
    public void run() {
        try {
            keepRunning = true;

            setConR(new ConnectionR(socketR));     
            cmdHandler = new ClientCmdHandler(conR,this);
            conduit = new ConduitClientSide(conR,this);
            
            Verbose.show("... ClientMessageHandler.run() " +
                         " ready to start reading messages.");
            
            while (keepRunning) {
                
                Message m = null;
                try {
                    m = conR.readMessage();
                }
                catch(Exception xx) {
                    if ( xx instanceof RReaderEOFException ) {
                        Verbose.show("Closing ClientMessageHandler",xx);
                        closeHandler();
                        return;
                    } 
                    // Else ignore, ack has been sent.
                } 
                if ( m != null ) {
                    Verbose.show("Got message=" + m);
                    if ( m.isAppCmd() ) {
                        Verbose.show("    is app cmd");
                        cmdHandler.handleCmd(m);
                    }
                    else if ( m.isMessageToR() || m.isRReServerCmd() ) {
                        Verbose.show("    is r message");
                        conduit.handleRMessage(m);                
                    }
                    else {
                        Verbose.show("    bad message type");
                        try {
                            conR.writeMessage(createWrongTypeErrorMessage(m));
                        }
                        catch(Exception z) {
                            System.err.println(StringUtil.toString(z));
                        }
                    }
                }               
            }        
        }
        catch(Exception iox) { 
            Verbose.show("ClientMessageHandler.run()",iox);
            throw new RuntimeException(iox);
        }   
    }        
    
    public void closeHandler() {
        Verbose.show("ClientMessageHandler.closeHandler()");
        keepRunning = false;
        if (conR != null) {
            conR.close();
            conR = null;
        }
        if (conJ != null) {
            conJ.close();
            conJ = null;
        }
        parentApp.remove(this);
        Verbose.show("ClientMessageHandler.closeHandler() n handlers " +
                     "after remove=" + parentApp.getNHandlers());
    }
    
    public void shutdown() {
        Verbose.show("ClientMessageHandler.shutdown() n handlers=" +
                      parentApp.getNHandlers());
        closeHandler();
        Verbose.show("ClientMessageHandler.shutdown() handler closed, " +
                      "n handlers=" +
                      parentApp.getNHandlers());
        if ( parentApp.getNHandlers() < 1 ) {
            parentApp.shutdown();
        }
    }
    
    public void closeAllConnections() {
        try {
            cmdHandler.closeConnection(false);
            closeHandler();
        }
        catch(Exception xxx) { System.err.println(StringUtil.toString(xxx)); }
    }
    
    public void setConJs(ConnectionJ conJ) {
        this.setConJ(conJ);
        if ( cmdHandler != null ) cmdHandler.setConJ(conJ);
        if ( conduit != null ) conduit.setConJ(conJ);
    }
    
    boolean isConnectedToConduit() {
        return( conJ != null );
    }
    
    boolean isConnectedToClient() {
        return(conR != null);
    }
    
    
    Message createErrorMessage(String mess) {
        return(new Message(MessageType.er, mess));
    }             
}
