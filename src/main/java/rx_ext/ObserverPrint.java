package rx_ext;

import lombok.RequiredArgsConstructor;
import rx.Observer;

@RequiredArgsConstructor
public class ObserverPrint<T> implements Observer<T> {
	 private final String name;

	@Override
	public void onCompleted() {
		System.out.printf("%s completed\n", name);
	}

	@Override
	public void onError(Throwable e) {
		System.out.printf("%s error : %s\n", name, e);
	}

	@Override
	public void onNext(T t) {
		System.out.printf("%s value : %s\n", name, t);
	}

}