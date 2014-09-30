package sandbox;

import java.util.AbstractMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentLinkedQueue;

import rx.Observable;
import rx.Subscriber;
import lombok.RequiredArgsConstructor;

//TODO add testcase (on put, remove, removeAll, entrySet.iterator.remove)
//TODO add testcase multiThread
//TODO add doc
//TODO add testcase put, put, remove, subscribe
//TODO add testcase keep 2 Maps sync
public class ObservableMap<K, V> extends AbstractMap<K, V> {
	final Map<K, V> entries;
	final ConcurrentLinkedQueue<Subscriber<Event>> subscribers = new ConcurrentLinkedQueue<>();

	public ObservableMap(Map<K, V> init) {
		entries = init;
	}

	public ObservableMap() {
		this(new TreeMap<K,V>());
	}

	@Override
	public Set<java.util.Map.Entry<K, V>> entrySet() {
		return entries.entrySet();
	}

	@Override
	public V remove(Object k) {
		@SuppressWarnings("unchecked")
		K key = (K) k;
		V value = entries.remove(key);
		if (value != null) {
			fire(new Event(true, key, value));
		}
		return value;
	}

	@Override
	public V put(K key, V value) {
		entries.put(key, value);
		if (value != null) {
			fire(new Event(false, key, value));
		}
		return value;
	}

	void fire(Event e) {
		for(Subscriber<Event> s: subscribers) {
			if (s.isUnsubscribed()) {
				subscribers.remove(s);
			}
		}
		for(Subscriber<Event> s: subscribers) {
			s.onNext(e);
		}
	}

	//TODO fix
	@SuppressWarnings("unchecked")
	public Observable<Event> as() {
		return Observable.create((Observable.OnSubscribe<Event>)(aSubscriber -> {
		  try {
			    for (Map.Entry<K, V> e : entries.entrySet()) {
			      if (aSubscriber.isUnsubscribed()) {
			        return;
			      }
			      aSubscriber.onNext(new Event(true, e.getKey(), e.getValue()));
			    }
			    if (!aSubscriber.isUnsubscribed()) {
			      aSubscriber.onCompleted();
			    } else {
			    	subscribers.add((Subscriber<Event>)aSubscriber);
			    }
			  } catch(Throwable t) {
			    if (!aSubscriber.isUnsubscribed()) {
			      aSubscriber.onError(t);
			    }
			  }
		}));
	}

	@RequiredArgsConstructor
	public class Event {
		public final boolean removed;
		public final K k;
		public final V v;
	}
}

//see https://github.com/Netflix/RxJava/issues/798
//class ObservableList<T> {
//
//	final Observable<T> onAdd;
//	final Observable<T> onRemove;
//	public void add(T v) {
//
//	}
//
//	public void remove(T v) {
//
//	}
//
//	public void removeAll() {
//
//	}
//}