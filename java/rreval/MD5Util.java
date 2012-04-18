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

import java.math.*;
import java.security.*;

/**
 *
 * @author moi
 */
public class MD5Util {
 
    private static MessageDigest mDig;
    
    static {
        try {
            mDig = MessageDigest.getInstance("MD5");
        }
        catch(NoSuchAlgorithmException ax) {
            System.out.println(ax);
            System.exit(0);
        }
    }
    
    public static BigInteger calcMD5(String s) {
        mDig.reset();
        mDig.update(s.getBytes());
        return( new BigInteger(1,mDig.digest()) );
    }
}
