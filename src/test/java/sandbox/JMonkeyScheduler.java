package sandbox;

import rx.Scheduler;
import rx.Subscription;
import rx.functions.Action0;
import rx.subscriptions.BooleanSubscription;
import rx.subscriptions.CompositeSubscription;
import rx.subscriptions.Subscriptions;

import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;

import lombok.RequiredArgsConstructor;

import com.jme3.app.Application;

/**
 * Executes work on the JME'application thread (via app.enqueue(..).
 * This scheduler should only be used with actions that execute quickly.
 */
@RequiredArgsConstructor
public final class JMonkeyScheduler extends Scheduler {
	final Application app;

    @Override
    public Worker createWorker() {
        return new MyWorker(app);
    }

    @RequiredArgsConstructor
    private static class MyWorker extends Worker {
    	final Application app;

        private final CompositeSubscription innerSubscription = new CompositeSubscription();

        @Override
        public void unsubscribe() {
            innerSubscription.unsubscribe();
        }

        @Override
        public boolean isUnsubscribed() {
            return innerSubscription.isUnsubscribed();
        }

        @Override
        public Subscription schedule(final Action0 action, long delayTime, TimeUnit unit) {
        	throw new UnsupportedOperationException("TODO");
//            long delay = unit.toMillis(delayTime);
//            assertThatTheDelayIsValidForTheJavaFxTimer(delay);
//            final BooleanSubscription s = BooleanSubscription.create();
//
//            final Timeline timeline = new Timeline(new KeyFrame(Duration.millis(delay), new EventHandler<ActionEvent>() {
//
//                @Override
//                public void handle(ActionEvent event) {
//                    if (innerSubscription.isUnsubscribed() || s.isUnsubscribed()) {
//                        return;
//                    }
//                    action.call();
//                    innerSubscription.remove(s);
//                }
//            }));
//
//            timeline.setCycleCount(1);
//            timeline.play();
//
//            innerSubscription.add(s);
//
//            // wrap for returning so it also removes it from the 'innerSubscription'
//            return Subscriptions.create(new Action0() {
//
//                @Override
//                public void call() {
//                    timeline.stop();
//                    s.unsubscribe();
//                    innerSubscription.remove(s);
//                }
//
//            });
        }

        @Override
        public Subscription schedule(final Action0 action) {
            final BooleanSubscription s = BooleanSubscription.create();
            app.enqueue(new Callable<Void>() {
                @Override
                public Void call() {
                    if (innerSubscription.isUnsubscribed() || s.isUnsubscribed()) {
                        return null;
                    }
                    action.call();
                    innerSubscription.remove(s);
                    return null;
                }
            });

            innerSubscription.add(s);
            // wrap for returning so it also removes it from the 'innerSubscription'
            return Subscriptions.create(new Action0() {

                @Override
                public void call() {
                    s.unsubscribe();
                    innerSubscription.remove(s);
                }

            });
        }

    }
}
