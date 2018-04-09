// =====================================================================================================================
//
//  File:       KeyedCache.swift
//  Project:    KeyedCache
//
//  Version:    0.1.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Balancingrock/Swiftfire
//
//  Copyright:  (c) 2017 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that voluntarism is the way for societies to function optimally. Thus I have choosen to leave it
//  up to you to determine the price for this code. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you can also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
// PLEASE let me know about bugs, improvements and feature requests. (rien@balancingrock.nl)
// =====================================================================================================================
//
// History
//
// 0.1.0 - Initial release
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
    
    
    /// Empties the cache completely
    
    func reset()
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
        
        get { // Return nil if there is no element for the given key. Otherwsie update the internal tracking parameters and return the element.
            
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
                    case .leastRecentUsed: purgeElement({ $0.lastAccess < $1.lastAccess })
                    case .leastUsed:       purgeElement({ $0.accessCount < $1.accessCount })
                    }
                }
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
                
                // Ensure there is enouigh space for the new element
                
                let target = maxSize - element.estimatedMemoryConsumption
                purge({ estimatedMemoryConsumption > target })
            }
            
            
            // Add the new element and update the estimated memory consumption
            
            items[key] = Item(element)
            estimatedMemoryConsumption += element.estimatedMemoryConsumption
        }
    }
    
    
    /// Remove all elements from the cache.
    
    public func reset() {
        items = [:]
        estimatedMemoryConsumption = 0
    }
}
