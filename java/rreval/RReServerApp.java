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
import java.net.*;
import com.norbl.util.*;

/** 
 *
 * @author Barnet Wagman
 */
public class RReServerApp {
    
    public static final int SERVER_PORT_RJ_DEFAULT = 4463;
    public static final int SERVER_PORT_JJ_DEFAULT = 4464;
    
    int portRJ; 
    int portJJ;
    boolean keepRunning;
    ServerMessageHandler handler;
    
    boolean connectedToClient;
    
    /**
     * 
     * @param portRJ port for communications between rreServer (R) and 
     *               {@link RReServerApp}
     * @param portJJ port for communications between {@link RReServerApp}
     *               and {@link RReClientApp}.
     */
    public RReServerApp(int portRJ,int portJJ) {        
        this.portRJ = portRJ;      
        this.portJJ = portJJ;                      
    }
    
    public void launch() {
        
        try { 
            
            connectedToClient = false;
            
            // First wait for a connection from RReServer (an R function
            // that runs in a local R session.
            ServerSocket serverRJ = new ServerSocket(portRJ);

            Verbose.show("... waiting for RReServer to connect");
            Socket socketR = serverRJ.accept();
            ConnectionR conR = new ConnectionR(socketR);
            Verbose.show("RReServer has connected.");

                // Accept connections from client apps forever.
            ServerSocket serverJJ = new ServerSocket(portJJ);        
            for (;;) {
                Verbose.show("... waiting for the client app to connect.");
                Socket s = serverJJ.accept();
                Verbose.show("... client has socket, waiting for connection.");
                ConnectionJ conJ = new ConnectionJ(s, 
                                                   ConnectionJ.HostType.server);
                Verbose.show("A client app has connected.");
                
                    // If no client is connected, we signal the handler
                    // to handle messages.  Otherwise it will kill itself
                    // off when the 'connect' command arrives.                
                if ( !connectedToClient ) {
                    handler = new ServerMessageHandler(this,conR,conJ,true);
                    (new Thread(handler)).start();
                }                                                              
                else {
                    ServerMessageHandler h = 
                            new ServerMessageHandler(this,conR,conJ,false);
                    (new Thread(h)).start();
                }
            }
        }
        catch(Exception iox) {
            Verbose.show("Terminal exception",iox);
            System.exit(0);
        }
    }
    
    
//    public void launch_v0() {
//        
//        keepRunning = true;
//        while (keepRunning) {           
//            try {
//                ServerThread stR = new ServerThread(portRJ);
//                ServerThread stJ = new ServerThread(portJJ);
//
//                (new Thread(stR)).start();
//                (new Thread(stJ)).start();
//
//                Verbose.show("... RReServerApp waiting for connections.");
//                while ( keepRunning && 
//                        (!stR.connected || !stJ.connected) ) {
//                    try { Thread.sleep(250L); } catch(InterruptedException ix) {}
//                }
//
//                if ( !keepRunning ) System.exit(0);
//
//                handler = new ServerMessageHandler();
//                handler.launch(stR.socket,stJ.socket,this);
//
//                Verbose.show("RReServerApp connected both ways.");
//                while ( handler.keepRunning ) {
//                    try { Thread.sleep(200L); } catch(InterruptedException ix) {}
//                }
//                Verbose.show("RReServerApp handler shutdown ...");
//            }
//            catch(Exception x) { Verbose.show(x); }
//        }
//    }
        
    
    public void closeConnections() throws IOException {
        handler.close();
    }    
      
    public void shutdown() {
        keepRunning = false;
        System.exit(0);
    }
    
    class ServerThread implements Runnable {
        
        int port;
        Socket socket;
        boolean connected;
        
        ServerThread(int port ) { 
            this.port = port; 
            connected = false;
        }
        
        public void run() {
            try {                
                ServerSocket server = new ServerSocket(port);
                socket = server.accept();
                connected = true;
                Verbose.show("Connected on port=" + port);
            }
            catch(Exception xx) {
                System.err.println(StringUtil.getExceptionMessage(xx) + "\n\n" +
                                   StringUtil.exceptionStackToString(xx));
                System.exit(0);
            }
        }        
    }
    
    public static void main(String[] argv) {
        
        int portR = ArgvUtil.getIntVal(argv, "portRJ", 
                                       SERVER_PORT_RJ_DEFAULT);
        int portJ = ArgvUtil.getIntVal(argv, "portJ",
                                       SERVER_PORT_JJ_DEFAULT);
        Verbose.verbose =
            Boolean.parseBoolean(ArgvUtil.getVal(argv, "verbose", "true"));
                       
        Verbose.show("Launching RReServerApp portR=" + portR +
                     " portJ=" + portJ);
        
        RReServerApp app = new RReServerApp(portR, portJ);
        app.launch();
    }
}
