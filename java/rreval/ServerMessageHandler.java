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
 * @author Barnet Wagman
 */

public class ServerMessageHandler implements Runnable {
    
    public static final String CLOSE_CON = "closeServerConnection";
    public static final String CMD_TEST = "testCmdServerApp";
    
    RReServerApp parentApp;   
    ConnectionR conR;
    ConnectionJ conJ;    
    boolean handleMessages;
   
    boolean keepRunning;   
    
    public ServerMessageHandler(RReServerApp parentApp,
                                ConnectionR conR,ConnectionJ conJ,
                                boolean handleMessages) {
        this.parentApp = parentApp;
        this.conR = conR;
        this.conJ = conJ;  
        this.handleMessages = handleMessages;
    }
    
    public void run() {
        
        keepRunning = true;
        
        while ( keepRunning ) {               
            try {
                Verbose.show("... waiting for message");
                Message m = (Message) conJ.readMessage();
                if ( handleMessages ) {
                    if ( m.isMessageToR() || m.isRReServerCmd() ) {
                        try {
                            sendMessageToRRevalServer(m);
                        } 
                        catch(Exception x) { sendErrorMessageJ(x); }                    
                    }
                    else if ( m.isAppCmd() ) {
                        try {
                            handleCommand(m);
                        }
                        catch(Exception x) { sendErrorMessageJ(x); }
                    }
                    else {                    
                        conJ.writeMessage(createWrongTypeErrorMessage(m));                  
                    }
                }
                else { // There is already some one connected so shutdown.
                    if ( m.isConnectCmdMessage() ) {
                        try {
                            conJ.writeMessage(
                                Message.createRReServerNotAvailableMessage());                         
                            conJ.close();                        
                        }
                        catch(Exception nx) {
                            System.err.println(StringUtil.toString(nx));
                           
                        }
                        keepRunning = false;
                    }
                    else {
                        conJ.writeMessage(
                            new Message(MessageType.rj,
                               "RReServerApp received unexpected message: " +
                                m.obj.toString()));
                    }
                }
            }
            catch(Exception xxx) { 
                Verbose.show("ServerSideConduit.run(): ",xxx);                    
            }  
        }
    }
    
    /** Handles messages from the remote conduit. All message
     *  sequences originate on the client side and elicit a response
     *  message. This function reads them and handles them, either passing
     *  then on to the local R client or handling them internally.
     */
//    public void launch_v0(Socket socketR, Socket socketJ,
//                       RReServerApp parentApp) {
//        try {
//            conR = new ConnectionR(socketR);
//            conJ = new ConnectionJ(socketJ,ConnectionJ.HostType.server);
//            this.parentApp = parentApp;
//                       
//            keepRunning = true;
//            Verbose.show("ServerMessageHandler.launch() connected to r & j," +
//                          " starting to read message");
//            while ( keepRunning ) {               
//                Message m = (Message) conJ.readMessage();
//                Verbose.show("ServerMessageHandler loop: read message " +
//                             m.toString());
//                if ( m.isMessageToR() || m.isRReServerCmd() ) {
//                    try {
//                        sendMessageToRRevalServer(m);
//                    } 
//                    catch(Exception x) { sendErrorMessageJ(x); }                    
//                }
//                else if ( m.isAppCmd() ) {
//                    try {
//                        handleCommand(m);
//                    }
//                    catch(Exception x) { sendErrorMessageJ(x); }
//                }
//                else {                    
//                    conJ.writeMessage(createWrongTypeErrorMessage(m));                  
//                }
//            }           
//            Verbose.show("server...leaving read message loop");
//        }
//        catch(Exception xxx) { 
//            Verbose.show("ServerSideConduit.run(): ",xxx);                    
//        }        
//    }
 
    void handleCommand(Message m) throws Exception {
        
        Verbose.show("server...handleCommand() m=" + m);
        AppCmd ac = new AppCmd(m.obj);
        
        if ( m.isConnectCmdMessage() ) {
            parentApp.connectedToClient = true;
            conJ.writeMessage(Message.createConnectedToRReServerMessage());
        }
        else if ( m.isDisonnectCmdMessage() ) {
            keepRunning = false;
            conJ.close();  
            parentApp.connectedToClient = false;
        }
        else {
            conJ.writeMessage(
                new Message(MessageType.rj,
                        "RReServer received unexpected message=" + 
                        m.obj.toString()));
        }
    }
    
//    void handleCommand_v0(Message m) throws Exception {
//        Verbose.show("server...handleCommand() m=" + m);
//        AppCmd ac = new AppCmd(m.obj);
//        if ( CLOSE_CON.equals(ac.cmdName) ) {
//            
//            Message ccc = new Message(MessageType.cr,"CLOSE_CON_CMD");
//            conR.writeMessage(ccc);
//            Verbose.show("server...handleCommand() send client 'close con' cmd");
//            
//            conR.close();
//            Verbose.show("server...handleCommand() conR closed.");
//            conJ.writeMessage(
//                new Message(MessageType.rj,
//                            "Closed connection to rreval server."));
//            try { Thread.sleep(500L); } catch(InterruptedException ix) {}
//            conJ.close();
//            Verbose.show("server...handleCommand() conJ closed.");
//            this.keepRunning = false;
//        }
//        else if ( CMD_TEST.equals(ac.cmdName) ) {
//            Verbose.show("Received test message: " + m.obj);
//            conJ.writeMessage(new Message(MessageType.rj,
//                                    "Reply to " + m.obj));
//        }
//        else {
//            conJ.writeMessage(
//                new Message(MessageType.rj,
//                            "Server app: Not implemented yet: " + m.obj));
//        }
//    }
    
    /** Send a message to rrevalServer, get its reply and sends it back to
     *  the client via the conduit.
     * @param m 
     */
    void sendMessageToRRevalServer(Message m) throws Exception {
        
        try { conR.writeMessage(m); }
        catch(Exception x) { throw writeEx("Error writing to rrevalServer: ",x); }
        Verbose.show("ServerMessageHandler sent message to R server.");            
        
        Message r = conR.readMessage();
        
        try { conJ.writeMessage(r); }
        catch(Exception x) { throw writeEx("Error writing to conduit: ",x); }               
        Verbose.show("ServerMessageHandler sent server reply back to conduit.");
    }
    
    public void close() {
        if ( conJ != null ) conJ.close();
        if ( conR != null ) conR.close();
        keepRunning = false;
    }
    
        // ---------- Errors -----------------------------------
    
    WriteException writeEx(String s, Exception x) {
        return( new WriteException(s + " " + StringUtil.getExceptionMessage(x)) );
    }

    void sendErrorMessageJ(Exception x) {
        try {
            Verbose.show("Sending err m from ServerSideConduit: ",x);          
            conJ.writeMessage(new Message(MessageType.er,
                                          StringUtil.getExceptionMessage(x)));            
        }
        catch(Exception z) {
            System.out.println(StringUtil.getExceptionMessage(z));
        }
    }
    
    Message createWrongTypeErrorMessage(Message m) {
        
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
}
