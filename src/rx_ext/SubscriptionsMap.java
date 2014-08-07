package rx_ext;

import java.util.HashMap;

import lombok.extern.slf4j.Slf4j;
import rx.Subscription;

@Slf4j
public class SubscriptionsMap {

	private HashMap<String, Subscription> subs = new HashMap<>();

	public void add(String k , Subscription v) {
		log.debug("add subscription {}", k);
		subs.put(k, v);
	}

	public void unsubscribe(String k) {
		log.debug("remove subscription {}", k);
		Subscription v = subs.remove(k);
		if (v != null) v.unsubscribe();
	}

	public void unsubscribeAll() {
		log.debug("remove all subscriptions {}", subs.size());
		subs.values().stream().forEach((v) -> v.unsubscribe());
		subs.clear();
	}
}
