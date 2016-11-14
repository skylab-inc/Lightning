<p align="center">
<img src="https://cloud.githubusercontent.com/assets/6432361/15267819/634be4ee-1981-11e6-9ad6-71f47c633e50.png" width="224" alt="Edge">
<br/>Serverside non-blocking IO <b>in Swift</b><br/>
Ask questions in our <a href="https://slackin-on-edge.herokuapp.com">Slack</a> channel!<br/>
</p>


# Edge

![Swift](http://img.shields.io/badge/swift-3.0-brightgreen.svg)
[![Build Status](https://travis-ci.org/SwiftOnEdge/Edge.svg?branch=master)](https://travis-ci.org/SwiftOnEdge/Edge)
[![codecov](https://codecov.io/gh/SwiftOnEdge/Edge/branch/master/graph/badge.svg)](https://codecov.io/gh/SwiftOnEdge/Edge)
[![Slack Status](https://slackin-on-edge.herokuapp.com/badge.svg)](https://slackin-on-edge.herokuapp.com)

#### Node
Edge is an HTTP Server and TCP Client/Server framework written in Swift and inspired by [Node.js](https://nodejs.org). It runs on both OS X and Linux. Like Node.js, Edge uses an **event-driven, non-blocking I/O model**. In the same way that Node.js uses [libuv](http://libuv.org) to implement this model, Edge uses [libdispatch](https://github.com/apple/swift-corelibs-libdispatch). 

This makes Edge fast and efficient, but it also means that Edge applications can naturally make use of libdispatch to easily offload heavy processing to a background thread.

> The name Edge is a play on the name Node, as they are both components of [graphs](https://en.wikipedia.org/wiki/Graph_(abstract_data_type)).

#### Reactive Programming
Edge's event API embraces the concepts of Functional Reactive Programming while still not having any external dependencies. The API is called [Reflex](https://github.com/SwiftOnEdge/Reflex) and it is a modified version of [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), but also inspired by [RxSwift](https://github.com/ReactiveX/RxSwift). 


> Why did we reimplement?
* Edge should be easy to use out of the box.
* Edge is optimized for maximum performance, which requires careful tuning of the internals.
* The modified API is meant to be more similar to the familiar concepts of Futures and Promises.
* We don't want to be opinionated about any one framework. We want it to be easy to integate Edge with either ReactiveCocoa or RxSwift.

>FRP, greatly simplies management of asynchronous events. The general concept is that we can build a spout which pushes out asynchronous events as they happen. Then we hookup a pipeline of transformations that operate on events and pass the transformed values along. We can even do things like merge streams in interesting ways! Take a look at some of these [operations](http://rxmarbles.com) or watch [this talk](https://www.youtube.com/watch?v=XRYN2xt11Ek) about how FRP is used at Netflix. 

# Installation

Edge is available as a Swift 3 package. Simply add Edge as a dependency to your Swift Package.

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

### Routing
```swift
import Edge
import Foundation

// Create an API router.
let api = Router()

// Add a GET "/users" endpoint.
api.get("/users") { request in
    return Response(status: .ok)
}

// Filter requests under api that match "/auth". If it's a POST
// request at "/auth/login" return a 200 OK response.
// NOTE: Equivalent to `api.post("/auth/login")`
let auth = api.filter("/auth").post("/login") { request in
    return Response(status: .ok)
}
api.add(auth)

// Create the top level router and add simple middleware
// which logs all requests.
// NOTE: Middleware is a simple as a map function or closure!
let app = Router().map { request in
    print(request)
    return request
}

// Mount the API router under "/v1.0".
app.add("/v1.0", api)

// Handle all other requests with a 404 NOT FOUND error.
// NOTE: Any unhandled responses with throw an error.
// This means clear error messages and no more accidentally
// timing out clients!
app.any { _ in
    return Response(status: .notFound)
}

// Start the application.
app.start(host: "0.0.0.0", port: 3000)
```

### Raw HTTP
```swift
import Edge
import Foundation

func handleRequest(request: Request) -> Response {
    print(String(bytes: request.body, encoding: .utf8)!)
    return try! Response(json: ["message": "Message received!"])
}

let server = HTTP.Server()
server.listen(host: "0.0.0.0", port: 3000).startWithNext { client in

    let requestStream = client.read()
    requestStream.map(handleRequest).onNext{ response in
        client.write(response).start()
    }

    requestStream.onFailed { clientError in
        print("Oh no, there was an error! \(clientError)")
    }

    requestStream.onCompleted {
        print("Goodbye \(client)!")
    }

    requestStream.start()
}
```

### TCP
```Swift

import Edge
import Foundation

let server = try! TCP.Server()
try! server.bind(host: "0.0.0.0", port: 50000)
    
server.listen().startWithNext { connection in
    let byteStream = connection.read()
    let strings = byteStream.map { String(bytes: $0, encoding: .utf8)! }
    
    strings.onNext { message in
        print("Client \(connection) says \"\(message)\"!")
    }
    
    strings.onFailed { error in
        print("Oh no, there was an error! \(error)")
    }
    
    strings.onCompleted {
        print("Goodbye \(connection)!")
    }
    
    byteStream.start()
}

RunLoop.runAll()
```


### Edge is not Node.js

Edge is not meant to fulfill all of the roles of Node.js. Node.js is a JavaScript runtime, while Edge is a TCP/Web server framework. The Swift compiler and package manager, combined with third-party Swift packages, make it unnecessary to build that functionality into Edge.
