/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package sandbox;

import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.input.event.MouseButtonEvent;
import com.jme3.input.event.MouseMotionEvent;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Vector2f;
import com.jme3.math.Vector4f;
import tonegod.gui.controls.buttons.Button;
import tonegod.gui.controls.extras.Indicator;
import tonegod.gui.controls.lists.Slider;
import tonegod.gui.controls.windows.LoginBox;
import tonegod.gui.controls.windows.Panel;
import tonegod.gui.core.Screen;
import tonegod.gui.core.SubScreen;

/**
 *
 * @author dwayne
 */
public class MultiScreen extends SimpleApplication {

    public PageManager pageMgr;
    Screen screen;
    
    public static void main(String[] args) {
        MultiScreen app = new MultiScreen();
        app.start();
    }
    
    @Override
    public void simpleInitApp() {
        pageMgr = new PageManager();
        pageMgr.stateManager = stateManager;
        screen = new Screen(this);
        this.getGuiNode().addControl(screen);
        pageMgr.show(new Page1());
    }
}
class PageManager {
    AppState[] states;
    public AppStateManager stateManager;
    void show(Page p) {
        if (states != null) {
            for (AppState e : states) {
                stateManager.detach(e);
            }
        }
        if (p != null) {
            states = p.states();
            stateManager.attachAll(states);
        }
    }
}

interface Page {
    AppState[] states();
}

class Page1 implements Page {
    @Override
    public AppState[] states() {
        return new AppState[]{new UserLogin()};
    }
}

class Page0 implements Page {
    @Override
    public AppState[] states() {
        return new AppState[]{new Screen0()};
    }
}

class Screen0 extends AbstractAppState {
    MultiScreen app;
    Panel panel;
    
    @Override
    public void initialize(AppStateManager stateManager, Application app0) {
      super.initialize(stateManager, app);
      app = (MultiScreen) app0;
      app.getInputManager().setCursorVisible(true);
      fillScreen(app.screen);
    }
    
    void fillScreen(Screen screen) {
        Panel p = new Panel(screen, Vector2f.ZERO, new Vector2f(screen.getWidth(), screen.getHeight()));
        final ColorRGBA color = new ColorRGBA();

        final Indicator ind = new Indicator(
                screen,
                new Vector2f(50, 50),
                new Vector2f(300, 30),
                Indicator.Orientation.HORIZONTAL) {
            @Override
            public void onChange(float currentValue, float currentPercentage) {
            }
        };
        ind.setBaseImage(screen.getStyle("Window").getString("defaultImg"));
//ind.setIndicatorImage(screen.getStyle("Window").getString("defaultImg"));
        ind.setIndicatorColor(ColorRGBA.randomColor());
        ind.setAlphaMap(screen.getStyle("Indicator").getString("alphaImg"));
        ind.setIndicatorPadding(new Vector4f(7, 7, 7, 7));
        ind.setMaxValue(100);
        ind.setDisplayPercentage();

        p.addChild(ind);

        Slider slider = new Slider(screen, new Vector2f(100, 100), Slider.Orientation.HORIZONTAL, true) {
            @Override
            public void onChange(int selectedIndex, Object value) {
                float blend = selectedIndex * 0.01f;
                color.interpolate(ColorRGBA.Red, ColorRGBA.Green, blend);
                ind.setIndicatorColor(color);
                ind.setCurrentValue((Integer) value);
            }
        };

        p.addChild(slider);

        Button btn = new Button(screen, new Vector2f(100, screen.getHeight() - 200)) {
            @Override
            public void onButtonMouseLeftDown(MouseButtonEvent evt, boolean toggled) {
                System.out.println("onButtonMouseLeftDown");
            }
            
            @Override
            public void onButtonMouseRightDown(MouseButtonEvent evt, boolean toggled) {
                System.out.println("onButtonMouseRightDown");
            }
            
            @Override
            public void onButtonMouseLeftUp(MouseButtonEvent evt, boolean toggled) {
                System.out.println("onButtonMouseLeftUp");
                ((MultiScreen)app).pageMgr.show(new Page1());
            }
            
            @Override
            public void onButtonMouseRightUp(MouseButtonEvent evt, boolean toggled) {
                System.out.println("onButtonMouseRightUp");
            }
            
            @Override
            public void onButtonFocus(MouseMotionEvent evt) {
                System.out.println("onButtonFocus");
            }
            
            @Override
            public void onButtonLostFocus(MouseMotionEvent evt) {
                System.out.println("onButtonLostFocus");
            }
        };
        p.addChild(btn);
        panel = p;
        screen.addElement(p);
    }

    void emptyScreen(Screen screen) {
        if (panel != null) {
            panel.removeFromParent();
            screen.removeElement(panel);
        }
    }
    
    @Override
    public void cleanup() {
        System.out.println("cleanup screen0");
        super.cleanup();
        emptyScreen(app.screen);
    }
}

class UserLogin extends AbstractAppState {
    MultiScreen app;
    LoginBox loginWindow;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        this.app = (MultiScreen) app;
        this.app.getInputManager().setCursorVisible(true);
        fillScreen(this.app.screen);
    }
 
    public void fillScreen(Screen screen) {
        
        loginWindow = new LoginBox(screen, "loginWindow", new Vector2f(screen.getWidth()/2-175,screen.getHeight()/2-125)) {
            @Override
            public void onButtonLoginPressed(MouseButtonEvent evt, boolean toggled) {
                // Some call to the server to log the client in
                finalizeUserLogin();
            }

            @Override
            public void onButtonCancelPressed(MouseButtonEvent evt, boolean toggled) {

            }
        };
        screen.addElement(loginWindow);
    }
    void emptyScreen(Screen screen) {
        if (loginWindow != null) {
            loginWindow.removeFromParent();
            screen.removeElement(loginWindow);
        }
    }
    
    @Override
    public void cleanup() {
        System.out.println("cleanup login");
        super.cleanup();
        emptyScreen(app.screen);
    }
 
    public void finalizeUserLogin() {
        // Some call to your app to unload this AppState and load the next AppState
        //app.someMethodToSwitchAppStates();
        app.pageMgr.show(new Page0());
    }
}
