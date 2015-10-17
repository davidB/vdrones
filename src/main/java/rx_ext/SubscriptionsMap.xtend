package rx_ext

import java.util.HashMap
import org.slf4j.LoggerFactory
import rx.Subscription

class SubscriptionsMap {
	val log = LoggerFactory.getLogger(SubscriptionsMap)
	HashMap<String, Subscription> subs = new HashMap()

	def void add(String k, Subscription v) {
		log.debug("add subscription {}", k)
		subs.put(k, v)
	}

	def void unsubscribe(String k) {
		log.debug("remove subscription {}", k)
		var Subscription v = subs.remove(k)
		if(v !== null) v.unsubscribe()
	}

	def void unsubscribeAll() {
		log.debug("remove all subscriptions {}", subs.size())
		subs.values().forEach[v|v.unsubscribe()]
		subs.clear()
	}

}
