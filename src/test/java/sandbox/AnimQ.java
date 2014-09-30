/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package sandbox;

import com.jme3.math.Quaternion;

/**
 *
 * @author dwayne
 */
public class AnimQ {

    public static void main(String[] args) {
        Quaternion q0 = new Quaternion(0.0f, 0.0f, 0.0f, 1.0f);
        Quaternion qxp = new Quaternion(1.0f, 0.0f, 0.0f, 1.0f).normalizeLocal();
        Quaternion qxn = new Quaternion(1.0f, 0.0f, 0.0f, -1.0f).normalizeLocal();
        Quaternion qyp = new Quaternion(0.0f, 1.0f, 0.0f, 1.0f).normalizeLocal();
        Quaternion qyn = new Quaternion(0.0f, 1.0f, 0.0f, -1.0f).normalizeLocal();
        Quaternion qx = new Quaternion();
        Quaternion qy = new Quaternion();
        
        System.out.println(q0);
        for(float i= 0; i <= 1.0; i += 0.125f) {
            float r = (i <= 0.5) ? i*2 : 1 - i;
            qx.slerp(qxn, qxp, r*2);
            qy.slerp(qyn, qyp, r);
            System.out.printf("%s %s * %s = %s\n", i * 48, qx, qy, qx.mult(qy).normalizeLocal());
        }
/*    
        qx.slerp(qxp, q0, 1.0f);
        qy.slerp(qyn, qyp, 1.0f);
        System.out.printf("%s * %s = %s\n", qx, qy, qx.mult(qy).normalizeLocal());

        //qx.slerp(qxp, q0, 1.0f);
        qy.slerp(qyp, qyn, 0.5f);
        System.out.printf("%s * %s = %s\n", qx, qy, qx.mult(qy).normalizeLocal());

        qy.slerp(qyp, qyn, 1.0f);
        System.out.printf("%s * %s = %s\n", qx, qy, qx.mult(qy).normalizeLocal());
*/
}
}
