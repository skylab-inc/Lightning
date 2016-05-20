//
//  IOStream.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Dispatch

public struct IOStreamEventEmitter {
    
    /// Listeners called for onRead events
    var readListeners: [(result: [UInt8]) -> ()] = []
    
    var writeListeners: [(unwrittenData: [UInt8]) -> ()] = []
    
    var closeListeners: [() -> ()] = []
    
    var endListeners: [() -> ()] = []
    
    var writeEndListeners: [() -> ()] = []
    
    var errorListeners: [(error: Error) -> ()] = []
    
    
    /// Dispatch functions
    func emitRead(result: [UInt8]) {
        log.debug("Emitting to read listeners: \(readListeners)")
        readListeners.forEach { listener in
            listener(result: result)
        }
    }
    
    func emitClose() {
        log.debug("Emitting to close listeners: \(closeListeners)")
        closeListeners.forEach { listener in
            listener()
        }
    }
    
    func emitEnd() {
        log.debug("Emitting to end listeners: \(endListeners)")
        endListeners.forEach { listener in
            listener()
        }
    }
    
    func emitError(error: Error) {
        log.debug("Emitting to error listeners: \(errorListeners)")
        errorListeners.forEach { listener in
            listener(error: error)
        }
    }
    
    func emitWrite(unwrittenData: [UInt8]) {
        log.debug("Emitting to write listeners: \(writeListeners)")
        writeListeners.forEach { listener in
            listener(unwrittenData: unwrittenData)
        }
    }
    
    func emitWriteEnd() {
        log.debug("Emitting to write end listeners: \(writeEndListeners)")
        writeEndListeners.forEach { listener in
            listener()
        }
    }

}

public protocol IOStream: class {
    
    var fd: FileDescriptor { get }
    
    var loop: RunLoop { get }
    
    var channel: dispatch_io_t { get }
    
    var eventEmitter: IOStreamEventEmitter { get set }
    
    /// onClose is called when the IO stream is closed
    func onClose(_: () -> ())
    
    /// onClose handlers will be called after the onError handlers for unrecoverable errors
    func onError(_: (error: Error) -> ())
    
}

public extension IOStream {
    
    public func onClose(_ close: () -> ()) {
        eventEmitter.closeListeners.append(close)
    }
    
    public func onError(_ error: (error: Error) -> ()) {
        eventEmitter.errorListeners.append(error)
    }
    
}

public protocol WritableIOStream: class, IOStream {
    
    func onWrite(_: (unwrittenData: [UInt8]) -> ())
    
    func onWriteEnd(_: () -> ())
    
    func write(buffer: [UInt8])

}

public extension WritableIOStream {
    
    public func onWrite(_ write: (unwrittenData: [UInt8]) -> ()) {
        eventEmitter.writeListeners.append(write)
    }
    
    public func onWriteEnd(_ writeEnd: () -> ()) {
        eventEmitter.writeEndListeners.append(writeEnd)
    }
    
    public func write(buffer: [UInt8]) {
        buffer.withUnsafeBufferPointer { buffer in
            
            // Allocate dispatch data
            guard let dispatchData = dispatch_data_create(buffer.baseAddress, buffer.count, dispatch_get_main_queue(), nil) else {
                eventEmitter.emitError(error: .noMemory)
                
                // Emit close as the channel was never open.
                eventEmitter.emitClose()
                return
            }
            
            // Schedule write operation
            dispatch_io_write(channel, off_t(), dispatchData, dispatch_get_main_queue()) { done, data, error in
                
                if error != 0 {
                    // If there was an error emit the error.
                    self.eventEmitter.emitError(error: Error(rawValue: error))
                }
                
                if let data = data where data !== dispatch_data_empty {
                    // Get unwritten data
                    var p = UnsafePointer<Void>(nil)
                    var size: size_t = 0
                    _ = dispatch_data_create_map(data, &p, &size)
                    let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                    
                    self.eventEmitter.emitWrite(unwrittenData: buffer)
                }
                
                if done {
                    if error == 0 {
                        // If the done param is set and there is no error,
                        // all data has been written, emit writing end.
                        // DO NOT emit end otherwise!
                        self.eventEmitter.emitWriteEnd()
                    } else {
                        // Must be an unrecoverable error, close the channel.
                        // TODO: Maybe don't close if you want half-open channel
                        dispatch_io_close(self.channel, 0)
                    }
                }
            }
        }
    }
}


public protocol ReadableIOStream: class, IOStream {
    
    /// Registering a callback with onRead will automatically begin the stream
    func onRead(_: (result: [UInt8]) ->())
    
    /// Emitted when EOF is reached or socket sends a FIN packet.
    /// Only emitted when ALL of the data is read.
    func onEnd(_ end: () -> ())

}

public extension ReadableIOStream {
    
    public func onRead(_ read: (result: [UInt8]) ->()) {
        eventEmitter.readListeners.append(read)
    }
    
    public func onEnd(_ end: () -> ()) {
        eventEmitter.endListeners.append(end)
    }
    
    func startRead(minBytes: Int = 1) {
        dispatch_io_set_low_water(channel, minBytes);
        dispatch_io_read(channel, off_t(), size_t(INT_MAX), dispatch_get_main_queue()) { done, data, error in
            
            if error != 0 {
                // If there was an error emit the error.
                self.eventEmitter.emitError(error: Error(rawValue: error))
            }
            
            // Deliver data if it is non-empty
            if let data = data where data !== dispatch_data_empty {
                var p = UnsafePointer<Void>(nil)
                var size: size_t = 0
                _ = dispatch_data_create_map(data, &p, &size)
                let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                
                self.eventEmitter.emitRead(result: buffer)
            }

            if done {
                if error == 0 {
                    // If the done param is set and there is no error,
                    // all data has been read, emit end.
                    // DO NOT emit end otherwise!
                    self.eventEmitter.emitEnd()
                }
                
                // It's done close the channel
                // TODO: Maybe don't close if you want half-open channel
                dispatch_io_close(self.channel, 0)
            }
            
        }
    }
}
