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
import com.norbl.util.*;
import com.norbl.util.ssh.*;
import ch.ethz.ssh2.*;

/**
 *
 * @author moi
 */
public class SshWrangler {
    
    public static long SSH_WAIT_TIME = 5000L;
    
    enum Arg {
        localFile,
        localDir,
        remoteFile,
        remoteDir
    }
    
    String hostName;
    String userName;
    File pemFile;
    int portLocal, portRemote;
    
    Connection conPF;
    LocalPortForwarder portForwarder;
    
    Connection conSCP;
    SCPClient scpClient;
    
    public SshWrangler(String hostName,String userName, File pemFile,
                       int portLocal, int portRemote) 
        throws IOException, ConnectFailureException {
        this.hostName = hostName;
        this.userName = userName;        
        this.pemFile = pemFile;
        this.portLocal = portLocal;
        this.portRemote = portRemote;      
    }
    
    public void startPortForwarding()
         throws ConnectFailureException, IOException {
         conPF = Ssh.connect(hostName, userName, pemFile, SSH_WAIT_TIME);
         portForwarder = conPF.createLocalPortForwarder(portLocal, 
                                                       "localhost",
                                                       portRemote);
         Verbose.show("SshWrangler: started port forwarding to " +
                     userName + "@" + hostName + " ports " +
                     portLocal + " -> " + portRemote);
    }
    
    public void setupScp() 
        throws ConnectFailureException, IOException {
        Verbose.show("SshWrangler: about to setup scp: " +
                hostName + " " + userName + " " + pemFile.getPath());
        conSCP = Ssh.connect(hostName, userName, pemFile, SSH_WAIT_TIME);
        scpClient = new SCPClient(conSCP);
        Verbose.show("SshWrangler: setup scp client to " +
                     userName + "@" + hostName);
    }
    
//    public void connect() throws ConnectFailureException, IOException {
//        
//        conPF = Ssh.connect(hostName, userName, pemFile, SSH_WAIT_TIME);
//        conSCP = Ssh.connect(hostName, userName, pemFile, SSH_WAIT_TIME);
//        Verbose.show("SshWrangler: calling pf " + portLocal + " -> " +
//                                portRemote);
//        portForwarder = conPF.createLocalPortForwarder(portLocal, 
//                                                       "localhost",
//                                                       portRemote);
//        Verbose.show("SshWrangler.connect(): started port forwarding to " +
//                     userName + "@" + hostName + " ports " +
//                     portLocal + " -> " + portRemote);
//                
//        scpClient = new SCPClient(conSCP);
//        Verbose.show("SshWrangler.connect(): setup scp client to " +
//                     userName + "@" + hostName);
//    }
    
     /** This method run scp in a separate thread and returns as soon
      *  as the transfer has been initiated.
      * 
      * @param cmd
      * @return
      * @throws IOException 
      */
     String scpUpload(AppCmd cmd) throws IOException {
        
        if ( scpClient == null ) return("scp has not been setup yet.");
        
        String localFileS = cmd.getVal(Arg.localFile.toString());
        if ( localFileS == null ) return(("Local file was not specified."));
        File localFile = new File(localFileS);
        if ( !localFile.exists() ) return("Local file " + localFile.getPath() +
                                          " does not exist.");
        
        String remoteDirS = cmd.getVal(Arg.remoteDir.toString());
        if ( remoteDirS == null ) return("Remote dir was not specified.");
        
//        scpClient.put(localFile.getPath(),remoteDirS);
        ScpPut sp = new ScpPut(localFile,remoteDirS);
        (new Thread(sp)).start();
        try { Thread.sleep(1000L); } catch(InterruptedException ix) {}
        if ( sp.iox == null ) {        
            if ( sp.done )
                return("Uploaded " + localFile.getPath() + " to " +
                        hostName + ":" + remoteDirS);
            else 
                return("Uploading " + localFile.getPath() + " to " +
                        hostName + ":" + remoteDirS);
        }
        else throw sp.iox;
    }
     
    class ScpPut implements Runnable {
        File localFile;
        String remoteDirS;
        IOException iox;
        boolean done;
        ScpPut(File localFile, String remoteDirS) {
            this.localFile = localFile;
            this.remoteDirS = remoteDirS;
            iox = null;
            done = false;
        }
        public void run() {
            try {                
                scpClient.put(localFile.getPath(),remoteDirS);
                done = true;
            }
            catch(Exception xxx) {
               System.err.println(StringUtil.toString(xxx));
               if ( xxx instanceof IOException ) iox = (IOException) xxx;
            }
        }
    } 
     
    
    /** This method run scp in a separate thread and returns as soon
      *  as the transfer has been initiated.
      * 
      * @param cmd
      * @return
      * @throws IOException 
      */
    String scpDownload(AppCmd cmd) throws IOException {
        
        if ( scpClient == null ) return("scp has not been setup yet.");
        
        String remoteFileS = cmd.getVal(Arg.remoteFile.toString());
        if ( remoteFileS == null ) return(("Remote file was not specified."));
               
        String localDirS = cmd.getVal(Arg.localDir.toString());
        if ( localDirS == null ) return("Local dir was not specified.");
        File localDir = new File(localDirS);
        if ( !localDir.exists() || !localDir.isDirectory() )
            return(localDir.getPath() + " does not exist or is not a directory.");
        
//        scpClient.get(remoteFileS,localDir.getPath());
        ScpGet sp = new ScpGet(remoteFileS,localDir);
        (new Thread(sp)).start();
        try { Thread.sleep(1000L); } catch(InterruptedException ix) {}
        if ( sp.iox == null ) {     
            if ( sp.done )
                return("Downloaded " + hostName + ":" + remoteFileS +
                        " to " + localDir.getPath());
            else 
                return("Downloading " + hostName + ":" + remoteFileS +
                        " to " + localDir.getPath()); 
        }
        else throw sp.iox;                       
    }     
     
    class ScpGet implements Runnable {
        String remoteFileS;
        File localDir;
        IOException iox;
        boolean done;
        ScpGet(String remoteFileS, File localDir) {
            this.remoteFileS = remoteFileS;
            this.localDir = localDir;
            iox = null;
            done = false;
        }
        public void run() {
            try {                
                scpClient.get(remoteFileS,localDir.getPath());
                done = true;
            }
            catch(Exception xxx) {
               System.err.println(StringUtil.toString(xxx));
               if ( xxx instanceof IOException ) iox = (IOException) xxx;
            }
        }
    }  
     
    void shutdown() throws IOException {
        if ( conPF != null ) conPF.close();
        portForwarder = null;
        conPF = null;
        if ( conSCP != null )  conSCP.close();       
        scpClient = null;
        conSCP = null;
    }
}
