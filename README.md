# KeyedCache
A dictionary (key/value) based caching protocol.

# Description
A key/value based caching mechanism with an implementation for an in-memory cache.

The cache can be limited in size by either a maximum number of items or a maximum size.

If a new item must be placed and an old item must be purged, the purging strategy can be either "least recently used" or "least used".

To allow limiting by size, items to be stored in the cache must implement the EstimatedMemoryConsumption protocol. A default implementation is provided if this limiting strategy is not used. When using this strategy, the EstimatedMemoryConsumption should make a "best guess" at the memory consumption. The better the "guess" the better this limiting strategy will work. Note that for many (most?) uses it will not be necessary to use exact values.

# Reference manual

See [http://swiftfire.nl/projects/keyedcache/reference/index.html](http://swiftfire.nl/projects/keyedcache/reference/index.html)

# Version history

Note: Planned releases are for information only and subject to change without notice.

#### 1.0.0 (Planned)

- To accompany Swiftfire 1.0.0

#### 0.5.0 (Current)

- Upgrade for BRUtils 0.9.0

#### 0.4.0

- Upgrade for BRUtils 0.5.0

#### 0.3.0

- Upgrade for BRUtils 0.4.0

#### 0.2.0

- Upgrade for BRUtils 0.3.0

#### 0.1.0

- Initial version