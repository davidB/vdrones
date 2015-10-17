package rx_ext

import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.Observer

class ObserverPrint<T> implements Observer<T> {
	final String name

	override void onCompleted() {
		System::out.printf("%s completed\n", name)
	}

	override void onError(Throwable e) {
		System::out.printf("%s error : %s\n", name, e)
	}

	override void onNext(T t) {
		System::out.printf("%s value : %s\n", name, t)
	}

	@FinalFieldsConstructor
	new(){}
}
