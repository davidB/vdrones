package rx_ext;

import rx.Subscriber;
import rx.Subscription;

public abstract class SubscriberL2<T> extends Subscriber<T> {
	Subscription subscription = null;

	void terminate() {
		if (subscription != null) subscription.unsubscribe();
	}
	@Override
	public void onCompleted() {
		terminate();
	}

	@Override
	public void onError(Throwable e) {
		terminate();
	}

	@Override
	public void onNext(T v) {
		terminate();
		subscription = onNext2(v);
	}

	public abstract Subscription onNext2(T v);
}