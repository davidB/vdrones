package sandbox

import java.util.AbstractMap
import java.util.Map
import java.util.Set
import java.util.TreeMap
import java.util.concurrent.ConcurrentLinkedQueue
import rx.Observable
import rx.Subscriber
import org.eclipse.xtend.lib.annotations.Data

//TODO add testcase (on put, remove, removeAll, entrySet.iterator.remove)
//TODO add testcase multiThread
//TODO add doc
//TODO add testcase put, put, remove, subscribe
//TODO add testcase keep 2 Maps sync
class ObservableMap<K, V> extends AbstractMap<K, V> {
	final package Map<K, V> entries
	final package ConcurrentLinkedQueue<Subscriber<Event<K, V>>> subscribers = new ConcurrentLinkedQueue()

	new(Map<K, V> init) {
		entries = init
	}

	new() {
		this(new TreeMap<K, V>())
	}

	override Set<java.util.Map.Entry<K, V>> entrySet() {
		return entries.entrySet()
	}

	override V remove(Object k) {
		/*FIXME Cannot add Annotation to Variable declaration. Java code: @SuppressWarnings("unchecked")*/
		var K key = k as K
		var V value = entries.remove(key)
		if (value !== null) {
			fire(new Event(true, key, value))
		}
		return value
	}

	override V put(K key, V value) {
		entries.put(key, value)
		if (value !== null) {
			fire(new Event(false, key, value))
		}
		return value
	}

	def package void fire(Event<K, V> e) {
		for (Subscriber<Event<K,V>> s : subscribers) {
			if (s.isUnsubscribed()) {
				subscribers.remove(s)
			}

		}
		for (Subscriber<Event<K,V>> s : subscribers) {
			s.onNext(e)
		}

	}

	// TODO fix
	def Observable<Event<K, V>> ^as() {
		return Observable::create [ aSubscriber |
			try {
				for (Map.Entry<K, V> e : entries.entrySet()) {
					if (aSubscriber.isUnsubscribed()) {
						return
					}
					aSubscriber.onNext(new Event(true, e.getKey(), e.getValue()))
				}
				if (!aSubscriber.isUnsubscribed()) {
					aSubscriber.onCompleted()
				} else {
					subscribers.add(aSubscriber as Subscriber<Event<K, V>>)
				}
			} catch (Throwable t) {
				if (!aSubscriber.isUnsubscribed()) {
					aSubscriber.onError(t);
				}
			}
		]
	}

	@Data
	static class Event<K, V> {
		public final boolean removed
		public final K k
		public final V v
	// see https://github.com/Netflix/RxJava/issues/798
	// class ObservableList<T> {
	//
	// final Observable<T> onAdd;
	// final Observable<T> onRemove;
	// public void add(T v) {
	//
	// }
	//
	// public void remove(T v) {
	//
	// }
	//
	// public void removeAll() {
	//
	// }
	// }
	}
}
