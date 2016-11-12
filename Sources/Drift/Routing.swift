import Foundation
import Reflex
import HTTP
import POSIX
import POSIXExtensions

final class Router: RouterType, EndpointType {
    
    var endpoints: [EndpointType] = []
    var subpath: String = ""
    weak var parent: RouterType? = nil
    
    func start(host: String, port: POSIXExtensions.Port) {
        
        let server = HTTP.Server()
        let stream = server.listen(host: host, port: port)
        stream.onNext { client in
            
            let requestStream = client.read()
            let (responses, unhandledRequests) = self.process(requests: requestStream.signal)
            responses.onNext { response in
                client.write(response).start()
            }
            unhandledRequests.onNext { request in
                fatalError("Unhandled request: \(request)")
            }
            requestStream.start()
        }
        stream.start()
    }
    
}

extension Router: CustomStringConvertible  {
    
    var description: String {
        return endpoints.map{ $0.description }.joined(separator: "\n")
    }
    
}

protocol RouterType: class, EndpointType {
    
    var endpoints: [EndpointType] { get set }
    var path: String { get }
    var subpath: String { get set }
    weak var parent: RouterType? { get set }
    
    init()
    
}

extension RouterType {

    var path: String {
        return ((parent?.path ?? "") + subpath).characters.reduce("") { (result, character) in
            if let last = result.characters.last, character == last, last == "/" {
                return result
            } else {
                return result + String(character)
            }
        }
    }
    
    func add(_ subrouter: RouterType) {
        add("", subrouter)
    }
    
    func add(_ subpath: String = "", _ subrouter: RouterType) {
        subrouter.parent = self
        subrouter.subpath = subpath
        endpoints.append(subrouter)
    }
    
    func filter(_ subpath: String) -> Self {
        let router = Self()
        add(subpath, router)
        return router
    }
    
    func matches(path: String) -> Bool {
        return zip(
            self.path.components(separatedBy: "/"),
            path.components(separatedBy: "/")
        ).reduce(true) { (result, components) in
            return components.0 == components.1 && result
        }
    }
    
    private func endpoint(_ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self) { requests in
            let (matches, leftover) = requests.partition { request in
                return self.matches(path: request.uri.path)
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(endpoint)
    }
    
    private func endpoint(method: HTTP.Method, _ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self, method: method) { requests in
            let (matches, leftover) = requests.partition { request in
                return self.matches(path: request.uri.path) && request.method == method
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(endpoint)
    }
    
    func get(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .get, transform)
        } else {
            endpoint(method: .get, transform)
        }
    }
    
    func post(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .post, transform)
        } else {
            endpoint(method: .post, transform)
        }
    }
    
    func put(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .put, transform)
        } else {
            endpoint(method: .put, transform)
        }
    }
    
    func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: .delete, transform)
        } else {
            endpoint(method: .delete, transform)
        }
    }
    
    func any(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(transform)
        } else {
            endpoint(transform)
        }
    }
    
    func map(_ transform: @escaping (Request) -> Request) -> Self {
        endpoints.append(Endpoint(parent: self) { requests in
            (Signal<Response, ClientError>.empty, requests.map(transform))
        })
        return self
    }
    
    func filter(_ predicate: @escaping (Request) -> Bool) -> Self {
        endpoints.append(Endpoint(parent: self) { requests in
            (Signal<Response, ClientError>.empty, requests.filter(predicate))
        })
        return self
    }
    
    func process(requests: Signal<Request, ClientError>) -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        var currentUnhandledRequests = requests
        let (allResponses, allResponsesInput) = Signal<Response, ClientError>.pipe()
        for endpoint in endpoints {
            let (responses, unhandledRequests) = endpoint.process(requests: currentUnhandledRequests)
            responses.add(observer: allResponsesInput)
            currentUnhandledRequests = unhandledRequests
        }
        return (allResponses, currentUnhandledRequests)
    }
    
}

struct Endpoint: EndpointType {
    
    let method: HTTP.Method?
    let parent: RouterType?
    
    let transform: (Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>)
    
    init(parent: RouterType, method: HTTP.Method? = nil, _ transform: @escaping (Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>)) {
        self.transform = transform
        self.parent = parent
        self.method = method
    }

    func process(requests: Signal<Request, ClientError>)
        -> (Signal<Response, ClientError>, Signal<Request, ClientError>) {
        return transform(requests)
    }
    
    var description: String {
        if let method = method {
            return "\(method) \(path)"
        }
        return "ANY \(path)"
    }

    var path: String {
        return (parent?.path ?? "")
    }
    
}


protocol EndpointType: CustomStringConvertible {
    
    var path: String { get }
    func process(requests: Signal<Request, ClientError>) -> (Signal<Response, ClientError>, Signal<Request, ClientError>)
    
}

