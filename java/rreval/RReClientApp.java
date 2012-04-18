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
import java.util.*;
import com.norbl.util.*;

/**
 *
 * @author moi
 */
public class RReClientApp {
    
    public static final int CLIENT_PORT_RJ_DEFAULT = 4460;
    
    int portRJ;
    boolean keepRunning;
    ServerSocket serverSocket;
    String[] argv;
   
    List<ClientMessageHandler> clientHandlers;
    
    /**
     * 
     * @param portRJ port used for communications between the R client
     *               and {@link RReClientApp}.
     */
    public RReClientApp(int portRJ,String[] argv) {
        this.portRJ = portRJ;    
        this.argv = argv;
        clientHandlers = new ArrayList<ClientMessageHandler>();
    }
    
    protected RReClientApp() {}
    
    public void launch() {
        
        try {
            keepRunning = true;
            serverSocket = new ServerSocket(portRJ);
            Verbose.show("... waiting for rre client to connect " +
                                                    "on port " + portRJ);
            while (keepRunning) {
                try {                    
                    Socket s = serverSocket.accept();
                    ClientMessageHandler h = new ClientMessageHandler(s,this);
                    clientHandlers.add(h);
                    (new Thread(h)).start();
                    Verbose.show("... R client has connected " +
                                 " on port "+ portRJ);
                }
                catch(Exception xxx) {
                    Verbose.show("RReClientApp.run(): ",xxx);                 
                }
            }
        }
        catch(IOException iox) { throw new RuntimeException(iox); }   
    }
    
     public String[] getArgv() { return(argv); }
    
    public void shutdown() {
        Verbose.show("RReClientApp.shutdown()");
        System.exit(0);
    }
    
    /** Close all message handlers and then calls System.exit()
     * 
     */
    public void closeAllAndShutdown() {
        for ( ClientMessageHandler h : clientHandlers ) {
            h.closeAllConnections();
        }
        shutdown();
    }
    
    public void remove(ClientMessageHandler mHandler) {
        clientHandlers.remove(mHandler);
    }
    
    public int getNHandlers() { return( clientHandlers.size() ); }
    
    public static void main(String[] argv) {
        
        int portR = ArgvUtil.getIntVal(argv, "portRJ", 
                                       CLIENT_PORT_RJ_DEFAULT);
       
        Verbose.verbose =
            Boolean.parseBoolean(ArgvUtil.getVal(argv, "verbose", "true"));
                        
        RReClientApp app = new RReClientApp(portR,argv);
        app.launch();
    }
}
