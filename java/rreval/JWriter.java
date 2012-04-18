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

/**
 *
 * @author moi
 */
public class JWriter {
   
    public static int MAX_WRITE_RETRIES = 16;
    public static long RETRY_NAP = 500L;
    
    ConnectionJ con;
    
    public JWriter(ConnectionJ con) {
        this.con = con;
    }
    
    public void writeMessage(Serializable obj) throws Exception {
     
        Exception z = null;
        
        for ( int i = 0; i < MAX_WRITE_RETRIES; i++ ) {        
            try {               
                con.write(obj);                             
                if ( readAck() ) return;
                else { 
                    try { Thread.sleep(RETRY_NAP); }            
                    catch(InterruptedException ix) {}                
                }
            }
            catch(Exception xxx) {
                if ( (xxx instanceof RuntimeException) &&
                     !(xxx instanceof ClassCastException) ) {
                    throw ((RuntimeException) xxx);
                }
                else z = xxx;
            }
        }
        Verbose.show("JWriter.writeM: max tries exceeded");
        if ( z != null ) {
            Verbose.show("JWriter.writeM: thowing ", z);
            throw z;
        }
        else {
            Verbose.show("JWriter.writeM: throwing write faile exception");
            throw new WriteException("Write object failed after " +
                MAX_WRITE_RETRIES + " tries.");
        }
    }
    
    boolean readAck() throws Exception {
        Boolean ack = (Boolean) con.read();
        return(ack.booleanValue());
    }
}
