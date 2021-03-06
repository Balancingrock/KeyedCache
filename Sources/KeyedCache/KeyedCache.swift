// =====================================================================================================================
//
//  File:       KeyedCache.swift
//  Project:    KeyedCache
//
//  Version:    1.2.3
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017-2020 Marinus van der Lugt, All rights reserved.
//
//  License:    MIT, see LICENSE file
//
//  And because I need to make a living:
//
//   - You can send payment (you choose the amount) via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 1.2.3 - Updated LICENSE
// 1.2.1 - Restructured the time based subscript getter
// 1.2.0 - Added time based criteria to subscript get
//       - Added estimated memory consumption protocol to swift type Data
//       - Improved removal algorithm to prevent lock-out and cyclical removal
// 1.1.0 - Added operation to remove targetted cache elements
// 1.0.1 - Documentation update
// 1.0.0 - Removed older history
//
// =====================================================================================================================
// Description
// =====================================================================================================================
//
// Implements a keyed cache mechanism with an in-memory cache.
//
// The size of the cache can be limited in two ways: By the number of entries and by the size (in bytes) of the stored
// entries. Unfortunately the size of the entries cannot be determined exactly, hence limiting by size is only an
// estimation. To estimate the size of each entry, the elements stored in the cache must implement the
// EstimatedMemoryConsumption protocol.
//
// If the estimated memory size is not used, the stored elements must still implement the protocol, however the protocol
// has a default implementation. Thus simply extending the element to be stored with the protocol will be sufficient.
// This default implementation has the same effect as limiting by the number of entries.
//
// When limiting by size, only the (estimated) size of the store elements is considered, not the size of the overhead
// introduced by the cache itself. And not the size of the key's or wrapper's either.
//
// =====================================================================================================================

import Foundation
import BRUtils


/// Elements that are stored in the cache must implement this protocol. A default implementation is present, thus extending the type of the element with this protocol is sufficient. However the default implementation does not in fact estimate the size, and is only provided to ease implementation for cache users that do not use the "limit by size" feature.

public protocol EstimatedMemoryConsumption {
    
    
    /// Should return an estimation of the memory used in bytes. The more exact it is, the better the "limit cache by size" strategy will work.
    
    var estimatedMemoryConsumption: Int { get }
}


/// Default implementation.
///
/// This eases the adoption of the caching mechanism for those clients that do not need the "limit by size" strategy.

public extension EstimatedMemoryConsumption {
    
    
    /// Always returns 1. Limiting by size will thus have a very similar effect as limiting by size.
    
    var estimatedMemoryConsumption: Int { return 1 }
}


/// The protocol definition of the keyed cache

public protocol KeyedCache {
    
    
    /// The element to be stored in the cache
    
    associatedtype Element: EstimatedMemoryConsumption
    
    
    /// The key used to access the stored elements
    
    associatedtype Key
    
    
    /// Accessing the cached elements through the subscript notation
    
    subscript(_ key: Key) -> Element? { get set }
    
    
    /// Accessing the cached elements through the subscript notation enhanced by time checking
    ///
    /// The element should be removed from the cache if it was added before the given timestamp (a JavaData).
    
    subscript(_ key: Key, _ timestamp: Int64) -> Element? { get }
    
    
    /// Empties the cache completely
    
    func reset()
    
    
    /// Remove the element associated with the given key from the cache.
    ///
    /// - Returns: True on success, false if the key is unknown.

    func remove(_ key: Key) -> Bool
}


/// A wrapper for the cached elements.

fileprivate class Item<Element> {
    
    
    /// The stored element
    
    let element: Element
    
    
    /// The timestamp of the last time the associated element was retrieved. Will initially be set to the time it was entered in the cache.
    
    var lastAccess: Int64 = Date().javaDate
    
    
    /// The number of times the associated element was retrieved.
    
    var accessCount: Int = 0
    
    
    /// Creates a new item for the given element.
    
    init(_ element: Element) {
        self.element = element
    }
}


/// The purge strategy for the cache.

public enum PurgeStrategy {
    
    
    /// Use this to remove the least used element to make place for new elements.
    
    case leastUsed
    
    
    /// Use this to remove the least recently used element to make place for new elements.
    
    case leastRecentUsed
}


/// The limiting strategy for the cache. This chooses the strategy to be used to prevent the cache from growing too large.

public enum LimitStrategy {
    
    
    /// Use this to limit the number of cache entries to a fixed number.
    
    case byItems(Int)
    
    
    /// Use this to limit the number of entries in the cache by their estimated size. The items stored in the cache must implement the EstimatedMemoryConsumption protocol with a fair approximation of their real size. The better the approximation, the better this strategy will work.
    ///
    /// - Note: Since this is an inexact strategy, the actual memory use may be higher than the specified limit.
    ///
    /// Using this strategy may result in the removal of more than 1 cached items to make place for a new one.
    
    case bySize(Int)
}


/// An implementation of the keyed caching protocol that keeps all the elements in memory.

final public class MemoryCache<K: Hashable, E: EstimatedMemoryConsumption>: KeyedCache {
    
    
    // Maps the associated Element from the KeyedCache protocol to E
    
    public typealias Element = E
    
    
    // Maps the associated Key from the KeyedCache protocol to K
    
    public typealias Key = K
    
    
    /// The limiting strategy.
    
    private var limitStrategy: LimitStrategy
    
    
    /// The purge strategy, used when the liming strategy needs to purge elements.
    
    private var purgeStrategy: PurgeStrategy
    
    
    /// Keeps track of the estimated memory consumption of the elements contained in the cache.
    ///
    /// This number is updated when an element is added or removed.
    
    public var estimatedMemoryConsumption: Int = 0
    
    
    /// The storage of the items that wrap the elements
    
    fileprivate var items: Dictionary<Key, Item<Element>> = [:]
    
    
    /// Creates a new MemoryCache
    ///
    /// - Parameters:
    ///   - limitStrategy: The method to be used to prevent the cache from growing too large.
    ///   - purgeStrategy: The method to be used to determine which elements to remove when the cache grows too large.
    
    public init(limitStrategy: LimitStrategy, purgeStrategy: PurgeStrategy) {
        self.limitStrategy = limitStrategy
        self.purgeStrategy = purgeStrategy
    }
    
    
    /// The subscript accessor to the cache.
    
    public subscript(_ key: K) -> E? {
        
        get { // Return nil if there is no element for the given key. Otherwise update the internal tracking parameters and return the element.
            
            guard let item = items[key] else { return nil }
            
            item.accessCount += 1
            item.lastAccess = Date().javaDate
            
            return item.element
        }
        
        set { // Insert the new element into the cache, make room if necessary.
            
            
            /// Purges elements from the cache until enough space is available according to the closure.
            
            func purge(_ keepPurging: () -> Bool) {
                
                
                /// Purges one item from the cache, selected by applying the closure to all items in the cache.
                
                func purgeElement(_ evaluate: (_ this: Item<E>, _ against: Item<E>) -> Bool) {
                    
                    if let purgeItem = items.min(by: { evaluate($0.value, $1.value) }) {
                        
                        items.removeValue(forKey: purgeItem.key)
                        estimatedMemoryConsumption -= purgeItem.value.element.estimatedMemoryConsumption
                    }
                }
                
                
                // Purge according to the selected purge strategy
                
                while keepPurging() {
                    
                    switch purgeStrategy {
                    
                    case .leastRecentUsed:
                        
                        purgeElement({ $0.lastAccess < $1.lastAccess })
                    
                        
                    case .leastUsed:
                        
                        // Randomize the item to be removed from the eligable items to prevent cyclic removal of the same item
                        let orderedItems = items.sorted { $0.value.accessCount < $1.value.accessCount }
                        let filteredItems = orderedItems.filter { $0.value.accessCount == orderedItems[0].value.accessCount }
                        let i = Int.random(in: 0 ..< filteredItems.count)
                        let removedItem = items.removeValue(forKey: filteredItems[i].key)!
                        estimatedMemoryConsumption -= removedItem.element.estimatedMemoryConsumption
                    }
                }
                
                
                // If the purge was on least used, reset all used counters to prevent 'locking' of the items in the cache
                
                items.forEach { $0.value.accessCount = 0 }
            }
            
            
            // If the new element uses the same key as an old element, then remove the old element and update the estimated memory consumption for the removed element.
            
            if let item = items[key] {
                estimatedMemoryConsumption += item.element.estimatedMemoryConsumption
                items.removeValue(forKey: key)
            }
            
            
            // Unwrap the new element
            
            guard let element = newValue else { return }
            
            
            // Apply the limiting strategy when necessary
            
            switch limitStrategy {
                
            case .byItems(let maxCount):
                
                // Ensure there is room for one more element
                
                purge({ items.count > maxCount - 1 })
                
                
            case .bySize(let maxSize):
                
                // Ensure there is enough space for the new element
                
                let target = maxSize - element.estimatedMemoryConsumption
                purge({ estimatedMemoryConsumption > target })
            }
            
            
            // Add the new element and update the estimated memory consumption
            
            items[key] = Item(element)
            estimatedMemoryConsumption += element.estimatedMemoryConsumption
        }
    }
    
    
    /// Return the request element if it existed after the given timestamp.
    ///
    /// - Note: If the element existed before the given timestamp it will be removed from the cache.
    ///
    /// - Parameters:
    ///   - key: The identifier (key) for the requested object
    ///   - timestamp: The time the object in question should have been created after. (JavaDate)
    
    public subscript(_ key: K, _ timestamp: Int64) -> E? {
        
        get { // Return nil if there is no element for the given key or if the element was older than the given timestamp. Otherwise update the internal tracking parameters and return the element.
            
            guard let item = items[key] else { return nil }
            
            if item.lastAccess < timestamp {
            
                // item is older than given timestamp, remove the item and return nil
                
                _ = self.remove(key)
                return nil
            
            } else {
                
                // update the access related data and return the item
            
                item.accessCount += 1
                item.lastAccess = Date().javaDate
            
                return item.element
            }
        }
    }
    
    
    /// Remove all elements from the cache.
    
    public func reset() {
        items = [:]
        estimatedMemoryConsumption = 0
    }
    
    
    /// Remove the element associated with the given key from the cache
    ///
    /// - Returns: True on success, false if the key is unknown.
    
    public func remove(_ key: K) -> Bool {
        return items.removeValue(forKey: key) != nil
    }
}

extension Data: EstimatedMemoryConsumption {
    public var estimatedMemoryConsumption: Int { return self.count }
}
