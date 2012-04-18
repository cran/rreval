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
import java.io.*;
import java.net.*;

/** Used by {@link ClientMessageHandler} (only) to handle command messages.
 *
 * @author Barnet Wagman
 */
public class ClientCmdHandler extends MessageWrangler{
    
    public static final String TERMINAL_PREFIX ="TERMINAL RRE APP ERROR:";
    
    enum Cmd {        
        connectToRReServer,
        closeConnection,      
        closeMessageHandler,        
        uploadFile,
        downloadFile,                       
        testCmdClientApp,
        testCmdServerApp,
        shutdown
    }
    
    ClientMessageHandler parent;
    
    SshWrangler sshWrangler;
    
    public ClientCmdHandler(ConnectionR conR, ClientMessageHandler parent) {
        setConR(conR);
        this.parent = parent;
    }
    
    /**
     * 
     * @param m a command message ({@link MessageType#cj}). It's
     *        object is a delimited text string.
     */
    public void handleCmd(Message m) {
    
        try {           
            AppCmd ac = new AppCmd(m.obj);
            Verbose.show("ClientCmdHandler app cmd=" + ac.toString());
            Cmd c = Cmd.valueOf(ac.cmdName);          
            
            switch(c) {
                case connectToRReServer:
                    connectToServer(ac);    
                    break;                
                case uploadFile:
                    uploadFile(ac);
                    break;
                case downloadFile:
                    downloadFile(ac);
                    break;
                case closeConnection:
                    closeConnection();
                    break;                
                case closeMessageHandler:
                    closeMessageHandler();
                    break;    
                case testCmdClientApp:
                    testCommandClient(ac);
                    break;
                case testCmdServerApp:
                    forwardMessage(m);
                    break;   
                case shutdown:
                    shutdown();
                    break;
                default:                
            }        
        }
        catch(Exception x) {
            Verbose.show("ClientCmdHandler.handleCmd(): ",x);
            sendErrMToR("ClientCmdHandler.handleCmd()",x);
        }
    }
    
        // --------- Cmd actions ---------------------------
    
    void forwardMessage (Message m) {
        try {
            conJ.writeMessage(m);                        
            conR.writeMessage((Message) conJ.readMessage());
        }
        catch(Exception x) {
            sendErrMToR("Error from forwarded message", x);
        }
    }
    
    void connectToServer(AppCmd ac) {
        
        try {
            ServerParams params = new ServerParams(ac);
            if ( !params.isFullySpecified() ) {
                Verbose.show("Params misspecified: " + params.getState());
                sendErrMToR(params.getState());
                return;
            }        
            Verbose.show("connectToServer Params ok");

            if ( parent.isConnectedToConduit() ) {
                Verbose.show("Already connected.");
                sendErrMToR("This connection is already connected to rreval " +
                           "server " + params.userName + "@" + params.hostName);
                return;
            }        
                   
                // Setup port forwarding and scp
            sshWrangler = new SshWrangler(params.hostName, params.userName, 
                                          params.pemFile, 
                                          params.portJJ, 
                                          params.portJJ);
            
            sshWrangler.startPortForwarding();
            
                // Connect to remote server app
            Socket socketJ = new Socket("localhost", params.portJJ);
                                        // ^ local because this is via pf
            Verbose.show("Connected to socket on " + params.hostName + "@" +
                          params.userName + ":" + params.portJJ +
                          " bound? " + socketJ.isBound());
         
            ConnectionJ cj = new ConnectionJ(socketJ,ConnectionJ.HostType.client);   
            Verbose.show("Connected to the server app");
            
                // Tell the server app to connect to RReserver
            try {
                cj.writeMessage(Message.createConnectToRReServerMessage());
                Verbose.show("... send connect cmd to the server app");
                Message reply = (Message) cj.readMessage();
                Verbose.show("Got reply from server app: " + reply.obj);
                if ( reply.isNotAvailableMessage() ) {
                    Verbose.show("Reply: not available, closing con to server app.");
                    closeConnectionToServerApp(cj);
                    Verbose.show("Closed con to server app");
                    sendErrMToR(reply.obj);
                    return;
                }
            }
            catch(Exception cx) {
                Verbose.show(cx);
                sendErrMToR(cx);
                closeConnectionToServerApp(cj) ;
                return;
            }
           
            parent.setConJs(cj);           
                    
            conR.writeMessage(new Message(MessageType.rj,
                    "Connected to " + params.hostName + "@" + params.userName +
                    ":" + Integer.toString(params.portJJ)));
            
            sshWrangler.setupScp();
        }
        catch(Exception x) {
            Verbose.show(x);
            String mess = TERMINAL_PREFIX + 
                          StringUtil.toString(x);
            sendErrMToR(mess); 
            parent.shutdown();
        }           
    }
    
    /** Close the connection to the server app, shutdown portforwarding
     *  and scp, close local connections and shutdown the parent message handler.
     *  If no other message handlers are running, the client app is shutdown.
     */
    void closeConnection(boolean callParentShutdown) {
        
            // Send a message to the server app, telling it to disconnect.
            // After this command, the server app will still be running and 
            // will be able to accept a connection from another client.
            // Note that the server app will not send a reply (other than
            // the ack).
        try {
            conJ.writeMessage(Message.createDisconnectFromClientMessage());                    
        }
        catch(Exception x) {
            System.err.println(StringUtil.toString(x));
        }
            
        closeConnectionToServerApp(conJ);
        
        try {
            conR.writeMessage(
                    new Message(MessageType.rj,
                            "Shutting down connection to rreval server"));
        }
        catch(Exception x) { System.err.println(StringUtil.toString(x)); }
        
        if ( callParentShutdown ) parent.shutdown();                    
    }    
    
    /** closeConnection(true)
     * 
     */
    void closeConnection() {
        closeConnection(true);
    }
    
    
    /** Closes all connections used by all handlers and then shuts down
     *  this app (using System.exit()).
     */
    void shutdown() {
        try {
            parent.parentApp.closeAllAndShutdown();
        }
        catch(Exception x) { System.exit(0); }
    }
    
    /** Closes socket, port forwarding and scp connections to the
     *  server app.  Note that this method does NOT notify the
     *  server and does not send a reply to the client - it is a
     *  component to be used by other methods that must handle
     *  notification.
     */
    void closeConnectionToServerApp(ConnectionJ jcon) {
            // Shutdown port forwarding and scp        
        try {
            if ( sshWrangler != null ) sshWrangler.shutdown();
        }
        catch(Exception x) {
            System.err.println(StringUtil.toString(x));
        }
        try {
            jcon.close();
        }
         catch(Exception x) {
            System.err.println(StringUtil.toString(x));
        }
    }
    
    /** Closes the parent message handler. If it is connected to a
     *  server, those connections are closed first.
     * 
     */
    void closeMessageHandler() {
        try {
            conR.writeMessage(
                    new Message(MessageType.rj,
                                "Closing message handler"));
        }
        catch(Exception x) { System.err.println(StringUtil.toString(x)); }
        parent.closeHandler();
     }
    
    void uploadFile(AppCmd ac) {
        if ( sshWrangler == null ) sendErrMToR("ssh/scp is not connected.");        
        else {
            try {
                sendMessageToR(sshWrangler.scpUpload(ac));
            }
            catch(Exception xxx) {
                sendErrMToR("Error uploading file", xxx);
            }
        }
    }
    
    void downloadFile(AppCmd ac) {
        if ( sshWrangler == null ) sendErrMToR("ssh/scp is not connected.");
        else {
            try {
                sendMessageToR(sshWrangler.scpDownload(ac));
            }
            catch(Exception xxx) {
                sendErrMToR("Error downloading file", xxx);
            }
        }
    }
    
    void testCommandClient(AppCmd ac) throws Exception {       
        Verbose.show("ClientCmdHandler got app cmd=" + ac.cmdName);
        conR.writeMessage(new Message(MessageType.rj,
                                  "Reply to test message from client app"));       
    }
        // -------------------------------------------------
    
    void unimplemented(Cmd cmd) {
        try {
            conR.writeMessage(
                new Message(MessageType.rj,
                            "Client app: Command " + cmd.toString() +
                            " is not implemented yet."));
        }
        catch(Exception z) { 
            Verbose.showStack("unimplemented", z);
            sendErrMToR("connectToServer()",z);            
       }   
    }
   
        // --------------------------------------------------
   
   class ServerParams {
        
        String hostName;
        String userName;
        int portRJ;
        int portJJ;
        File pemFile;
        
        ServerParams(AppCmd ac) {
            hostName = ac.getVal("hostName");
            userName = ac.getVal("userName");                        
            portRJ = getInt(ac.getVal("portRJ"));            
            portJJ = getInt(ac.getVal("portJJ")); 
            pemFile = new File(ac.getVal("pemFile"));
        }
        
        boolean isFullySpecified() {
            return( (hostName != null) || (userName != null) ||
                    (portRJ > 0)  || (portJJ > 0) &&
                    pemFile.exists() 
                  );
        }
        
        String getState() {
            if ( !isFullySpecified() ) {
                StringBuilder s = 
                    new StringBuilder("rreval server params are not fully " +
                                      " specified: ");
                if ( hostName == null ) s.append("<null hostName> ");
                if ( userName == null ) s.append("<null userName>");
                if ( portRJ < 0 ) s.append("<bad port number R <-> Java app> ");
                if ( portJJ < 0 ) s.append(
                                    "<bad remote port number Java app <-> Java > ");
                if ( !pemFile.exists() )
                    s.append("<pem file " + pemFile.getPath() +
                             " does not exist> ");
                return(s.toString());
            }
            else return("fully specified");
        }
        
        private int getInt(String s) {
            try { return(Integer.parseInt(s)); }
            catch(Exception x) { return(-1); }
        }    
    }
}
