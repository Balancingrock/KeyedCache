# KeyedCache

A dictionary (key/value) based caching protocol.

SwifterSockets is part of the Swiftfire webserver.

The [Swiftfire website](http://swiftfire.nl)

The [Reference manual](http://swiftfire.nl/projects/keyedcache/reference/index.html)

# Description

A key/value based caching mechanism with an implementation for an in-memory cache.

The cache can be limited in size by either a maximum number of items or a maximum memory usage.

If a new item must be placed and an old item must be purged, the purging strategy can be either "least recently used" or "least used".

To allow limiting by size, items to be stored in the cache must implement the EstimatedMemoryConsumption protocol. A default implementation is provided if this limiting strategy is not used. When using this strategy, the EstimatedMemoryConsumption should make a "best guess" at the memory consumption. The better the "guess" the better this limiting strategy will work. Note that for many (most?) uses it will not be necessary to use exact values.

# Version history

No new features planned. Updates are made on an ad-hoc basis as needed to support Swiftfire development.

#### 1.2.2

- Updated BRUtils version

#### 1.2.1

- Restructured the time based getter

#### 1.2.0

- Added time based criteria to subscript get
- Added estimated memory consumption protocol to swift type Data
- Improved removal algorithm to prevent lock-out and cyclical removal

#### 1.1.0

- Added remove operation to the cache protocol

#### 1.0.2

- Documentation updates

#### 1.0.1

- Documentation updates

#### 1.0.0

- To accompany Swiftfire 1.0.0
