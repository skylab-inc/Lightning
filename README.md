<p align="center">
<img src="https://cloud.githubusercontent.com/assets/6432361/15267819/634be4ee-1981-11e6-9ad6-71f47c633e50.png" width="224" alt="Edge">
<br/>Serverside non-blocking IO <b>in Swift</b><br/>
Ask questions on our <a href="https://swiftedge.slack.com">Slack</a>!<br/>
</p>


# Edge

#### Node
Edge is an HTTP Server and TCP Client/Server framework written in Swift and inspired by [Node.js](https://nodejs.org). It runs on both OS X and Linux. Like Node.js, Edge uses an **event-driven, non-blocking I/O model**. In the same way that Node.js uses [libuv](http://libuv.org) to implement this model, Edge uses [libdispatch](https://github.com/apple/swift-corelibs-libdispatch). 

This makes Edge fast and efficient, but it also means that Edge applications can naturally make use of libdispatch to easily offload heavy processing to a background thread.

> The name Edge is a play on the name Node, as they are both components of [graphs](https://en.wikipedia.org/wiki/Graph_(abstract_data_type)).

#### Reactive Programming
Edge's event API embraces the concepts of Functional Reactive Programming while still not having any external dependencies. The API is called [Reactive](https://github.com/SwiftOnEdge/Reactive) and it is a modified version of [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), but also inspired by [RxSwift](https://github.com/ReactiveX/RxSwift). 


> Why did we reimplement?
* Edge should be easy to use out of the box.
* Edge is optimized for maximum performance, which requires careful tuning of the internals.
* The modified API is meant to be more similar to the familiar concepts of Futures and Promises.
* We don't want to be opinionated about any one framework. We want it to be easy to integate Edge with either ReactiveCocoa or RxSwift.

>FRP, greatly simplies management of asynchronous events. The general concept is that we can build a spout which pushes out asynchronous events as they happen. Then we hookup a pipeline of transformations that operate on events and pass the transformed values along. We can even do things like merge streams in interesting ways! Take a look at some of these [operations](http://rxmarbles.com) or watch [this talk](https://www.youtube.com/watch?v=XRYN2xt11Ek) about how FRP is used at Netflix. 

# Installation

Edge is available as a Swift 3 package (No current 2.2 support). Simply add Edge as a dependency to your Swift Package.

```Swift
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .Package(url: "https://github.com/SwiftOnEdge/Edge.git", majorVersion: 0, minor: 1)
    ]
)
```

# Usage

### TCP
```Swift

import Edge
import Foundation

let server = try! TCP.Server()
try server.bind(host: "0.0.0.0", port: 50000)
    
server.listen().startWithNext { connection in
    let read = connection.read()
    let strings = read.map { String(bytes: $0, encoding: .utf8)! }
    
    strings.onNext { message in
        print("Client \(connection) says \"\(message)\"!")
    }
    
    strings.onFailed { error in
        print("Oh no, there was an error! \(error)")
    }
    
    strings.onCompleted {
        print("Goodbye \(connection)!")
    }
    
    read.start()
}

RunLoop.runAll()
```


### Edge is not Node.js

Edge is not meant to fulfill all of the roles of Node.js. Node.js is a JavaScript runtime, while Edge is a TCP/Web server framework. The Swift compiler and package manager, combined with third-party Swift packages, make it unnecessary to build that functionality into Edge.
