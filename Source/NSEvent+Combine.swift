// Copyright (c) 2020, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the OpenEmu Team nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import AppKit.NSEvent
import Combine

@available(macOS 10.15, *)
extension NSEvent {
    /// Returns a publisher that emits events from a local or global NSEvent monitor.
    /// - Parameters:
    ///   - scope: The scope of the events to monitor.
    ///   - mask: A mask specifying the type of events to monitor.
    static public func publisher(for scope: Publisher.Scope, matching mask: EventTypeMask) -> Publisher {
        return Publisher(scope: scope, matching: mask)
    }
    
    // swiftlint:disable nesting
    
    public struct Publisher: Combine.Publisher {
        public typealias Output = NSEvent
        public typealias Failure = Never
        
        /// Determines the scope of the NSEvent publisher.
        public enum Scope {
            /// Monitor local events
            case local
            
            /// Monitor global events
            case global
        }
        
        private let scope: Scope
        private let matching: EventTypeMask
        
        public init(scope: Scope, matching: EventTypeMask) {
            self.scope    = scope
            self.matching = matching
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let subscription = Subscription(scope: scope, matching: matching, subscriber: subscriber)
            subscriber.receive(subscription: subscription)
        }
    }
}

@available(macOS 10.15, *)
private extension NSEvent.Publisher {
    final class Subscription<S: Subscriber> where S.Input == NSEvent, S.Failure == Never {
        fileprivate let lock = NSLock()
        fileprivate var demand = Subscribers.Demand.none
        private var monitor: Any?
        
        fileprivate let subscriberLock = NSRecursiveLock()
        
        init(scope: Scope, matching: NSEvent.EventTypeMask, subscriber: S) {
            switch scope {
            case .local:
                monitor = NSEvent.addLocalMonitorForEvents(matching: matching, handler: { [weak self] (event) -> NSEvent? in
                    self?.didReceive(event: event, subscriber: subscriber)
                    return event
                })
                
            case .global:
                monitor = NSEvent.addGlobalMonitorForEvents(matching: matching, handler: { [weak self] in
                    self?.didReceive(event: $0, subscriber: subscriber)
                })
            }
            
        }
        
        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        
        func didReceive(event: NSEvent, subscriber: S) {
            let val = { () -> Subscribers.Demand in
                lock.lock()
                defer { lock.unlock() }
                let before = demand
                if demand > 0 {
                    demand -= 1
                }
                return before
            }()
            
            guard val > 0 else { return }
            
            let newDemand = subscriber.receive(event)
            
            lock.lock()
            demand += newDemand
            lock.unlock()
        }
    }
}

@available(macOS 10.15, *)
extension NSEvent.Publisher.Subscription: Combine.Subscription {
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        defer { lock.unlock() }
        self.demand += demand
    }
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        guard let monitor = monitor else { return }
        
        self.monitor = nil
        NSEvent.removeMonitor(monitor)
    }
}
