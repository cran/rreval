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

/** A command from the user to be performed by the client or server app.
 *  These handled by the apps - they are never sent to the rreval server.
 *  <p>
 *  A command is transmitted as a delimited string (the default 
 *  delimiter is '&').  Each element is of the form 
 *  <tt>&lt;label&gt;=&lt;value&gt;</tt>. At a minimum, a command must
 *  have the 'cmd' element, which specifies the unique command name.  
 *
 * @author moi
 */
public class AppCmd implements Serializable {
    static final long serialVersionUID = 1L;
    
    public static String DELIM = "&";
    public static String CMD_NAME = "cmd";
    
    String cmdString;
    String[] cmdFields;  
    
    String cmdName;
   
    public AppCmd(String cs) {
        if ( cs == null ) throw new RuntimeException("UserCmd was passed null.");     
        cmdString = cs;
        cmdFields = cs.split(DELIM);    
        cmdName = getVal(CMD_NAME);
    }
    
    public String getCmdName() { return(cmdName); }
    
    public String getVal(String label) {
        return(ArgvUtil.getVal(cmdFields,label));
    }
    
    public String toString() {
        StringBuilder s = new StringBuilder();
        s.append(cmdString + "\n");
        for ( int i = 0; i < cmdFields.length; i++ ) {
            s.append(i + " " + cmdFields[i] + "\n");
        }
        return(s.toString());
    }
    
    public static String createCmdString(String cmdName) {
        return( CMD_NAME + "=" + cmdName );
    }
}
