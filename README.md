# Basement

A lightweight wrapper on Realm to isolate and simplyfy a persistence layer of your iOS app.

Features:

- Wraps Realm library instances:

	Yes, Realm is great, but library gets changed over the time and following the best practices, it shuold be isolated from the rest of the app so all lib's updates/changes/glitches could stay udater the hood.

- Realm files management: 

	Adds ability to easily switch between different Realm file sets (databases).

- Adds more more thread safety so you could put a closer look on your app, not to Realm data managment rules:

	 Each wrapped Realm instance is being held on independent thread and deallocated automatically once not used.
	 
- Brings ability to make `read`, `filter` & more requests to Realm objects by using a `KeyPath`.



