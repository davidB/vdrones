package rx_ext

import rx.Subscriber
import rx.Subscription

abstract class SubscriberL2<T> extends Subscriber<T> {
    package Subscription subscription = null

    def package void terminate() {
        if(subscription !== null) subscription.unsubscribe()
    }

    override void onCompleted() {
        terminate()
    }

    override void onError(Throwable e) {
        terminate()
    }

    override void onNext(T v) {
        terminate()
        subscription = onNext2(v)
    }

    def abstract Subscription onNext2(T v)

}
