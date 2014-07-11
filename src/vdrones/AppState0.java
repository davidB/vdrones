package vdrones;

import lombok.extern.slf4j.Slf4j;

import com.google.inject.Injector;
import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;

/**
 *
 * @author dwayne
 */
@Slf4j
abstract public class AppState0 extends AbstractAppState {
    protected Injector injector;
    protected Application app;

    @Override
    public final void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        injector = Injectors.find(app);
        this.app = app;
        initialized = true;
        doInitialize();
        if( isEnabled() ) {
            doEnable();
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
            doEnable();
        } else {
            log.trace("disable():" + this);
            doDisable();
        }
    }

    @Override
    public final void update(float tpf) {
    	if (isEnabled()){
    		doUpdate(tpf);
    	}
    };


	protected void doInitialize(){}
    protected void doEnable(){};
    protected void doUpdate(float tpf) {}
    protected void doDisable(){};
    protected void doDispose(){};

    @Override
    public final void cleanup() {
        if( isEnabled() ) {
            doDisable();
        }
        doDispose();
        initialized = false;
    }

}
