package vdrones;

import com.google.inject.Injector;
import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import lombok.extern.slf4j.Slf4j;

/**
 *
 * @author dwayne
 */
@Slf4j
abstract public class AppState0 extends AbstractAppState {
    protected Injector injector;

    @Override
    public final void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        injector = Injectors.find(app);
        initialize();
        initialized = true;
        if( isEnabled() ) {
            enable();
        }
    }

    @Override
    public final void setEnabled( boolean enabled ) {
        if( isEnabled() == enabled )
            return;
        super.setEnabled(enabled);
        if( !isInitialized() )
            return;
        if( enabled ) {
            log.trace("enable():" + this);
            enable();
        } else {
            log.trace("disable():" + this);
            disable();
        }
    }

    protected void initialize(){}
    abstract protected void enable();
    abstract protected void disable();
    protected void dispose(){};

    @Override
    public final void cleanup() {
        if( isEnabled() ) {
            disable();
        }
        dispose();
        initialized = false;
    }

}
