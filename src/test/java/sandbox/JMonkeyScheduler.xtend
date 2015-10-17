package sandbox

import com.jme3.app.Application
import java.util.concurrent.TimeUnit
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.Scheduler
import rx.Subscription
import rx.functions.Action0
import rx.subscriptions.BooleanSubscription
import rx.subscriptions.CompositeSubscription
import rx.subscriptions.Subscriptions

/** 
 * Executes work on the JME'application thread (via app.enqueue(..).
 * This scheduler should only be used with actions that execute quickly.
 */
final class JMonkeyScheduler extends Scheduler {
	final package Application app

	override Worker createWorker() {
		return new MyWorker(app)
	}

	private static class MyWorker extends Worker {
		final package Application app
		final CompositeSubscription innerSubscription = new CompositeSubscription()

		override void unsubscribe() {
			innerSubscription.unsubscribe()
		}

		override boolean isUnsubscribed() {
			return innerSubscription.isUnsubscribed()
		}

		override Subscription schedule(Action0 action, long delayTime, TimeUnit unit) {
			throw new UnsupportedOperationException("TODO") // long delay = unit.toMillis(delayTime);
			// assertThatTheDelayIsValidForTheJavaFxTimer(delay);
			// final BooleanSubscription s = BooleanSubscription.create();
			//
			// final Timeline timeline = new Timeline(new KeyFrame(Duration.millis(delay), new EventHandler<ActionEvent>() {
			//
			// @Override
			// public void handle(ActionEvent event) {
			// if (innerSubscription.isUnsubscribed() || s.isUnsubscribed()) {
			// return;
			// }
			// action.call();
			// innerSubscription.remove(s);
			// }
			// }));
			//
			// timeline.setCycleCount(1);
			// timeline.play();
			//
			// innerSubscription.add(s);
			//
			// // wrap for returning so it also removes it from the 'innerSubscription'
			// return Subscriptions.create(new Action0() {
			//
			// @Override
			// public void call() {
			// timeline.stop();
			// s.unsubscribe();
			// innerSubscription.remove(s);
			// }
			//
			// });
		}

		override Subscription schedule(Action0 action) {
			val BooleanSubscription s = BooleanSubscription::create()
			app.enqueue[
				if (innerSubscription.isUnsubscribed() || s.isUnsubscribed()) {
					return false
				}
				action.call()
				innerSubscription.remove(s)
				true
			]
			innerSubscription.add(s) // wrap for returning so it also removes it from the 'innerSubscription'
			return Subscriptions::create(([|s.unsubscribe() innerSubscription.remove(s)] as Action0))
		}

		@FinalFieldsConstructor
		new(){}
	}

	@FinalFieldsConstructor
	new(){}
}
