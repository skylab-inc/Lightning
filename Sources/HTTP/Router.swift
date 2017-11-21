import Foundation
import StreamKit
import PromiseKit

public final class Router: ServerDelegate {

    var endpoints: [RequestTransformer] = []
    var subpath: String = ""
    weak var parent: Router? = nil

    public init() {

    }

    private init(transformers: [RequestTransformer]) {
        self.endpoints = transformers
    }

    var path: String {
        return ((parent?.path ?? "") + subpath).reduce("") { (result, character) in
            if let last = result.last, character == last, last == "/" {
                return result
            } else {
                return result + String(character)
            }
        }
    }

    func matches(path: String) -> Bool {
        return zip(
            self.path.components(separatedBy: "/"),
            path.components(separatedBy: "/")
            ).reduce(true) { (result, components) in
                return components.0 == components.1 && result
        }
    }

    private func endpoint(method: HTTP.Method? = nil, _ transform: @escaping (Request) -> Response) {
        let endpoint = Endpoint(parent: self, method: method) { [weak self] requests in
            let (matches, leftover) = requests.partition { [weak self] request in
                return self?.matches(path: request.uri.path) ?? false && request.method == method ?? request.method
            }
            return (matches.map(transform), leftover)
        }
        endpoints.append(.endpoint(endpoint))
    }

    private func endpoint(
        subpath: String?,
        method: HTTP.Method,
        _ transform: @escaping (Request) -> Response
    ) {
        if let subpath = subpath {
            filter(subpath).endpoint(method: method, transform)
        } else {
            endpoint(method: method, transform)
        }
    }

    private func endpoint(subpath: String?, _ transform: @escaping (Request) -> Response) {
        if let subpath = subpath {
            filter(subpath).endpoint(transform)
        } else {
            endpoint(transform)
        }
    }

    public func add(_ subrouter: Router) {
        add("", subrouter)
    }

    public func add(_ subpath: String = "", _ subrouter: Router) {
        subrouter.parent = self
        subrouter.subpath = subpath
        endpoints.append(.router(subrouter))
    }

    public func filter(_ subpath: String) -> Router {
        let router = Router()
        add(subpath, router)
        return router
    }

    public func any(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, transform)
    }

    public func get(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .get, transform)
    }

    public func post(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .post, transform)
    }

    public func put(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .put, transform)
    }

    public func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Response) {
        endpoint(subpath: subpath, method: .delete, transform)
    }

    public func map(_ transform: @escaping (Request) -> Request) -> Router {
        let newEndpoint = Endpoint(parent: self) { requests in
            (Signal<Response>.empty, requests.map(transform))
        }
        let newTransformers = endpoints + [.endpoint(newEndpoint)]
        return Router(transformers: newTransformers)
    }

    public func filter(_ predicate: @escaping (Request) -> Bool) -> Router {
        let middleware = RequestMiddleware(parent: self) { requests in
            requests.partition(predicate)
        }
        let newTransformers = endpoints + [.requestMiddleware(middleware)]
        return Router(transformers: newTransformers)
    }

    public func transform(requests: Signal<Request>) -> (Signal<Response>, Signal<Request>) {
        var forwardedRequests = requests
        let (allResponses, allResponsesInput) = Signal<Response>.pipe()
        let (allRequests, allRequestsInput) = Signal<Request>.pipe()
        for endpoint in endpoints {

            switch endpoint {
            case .router(let router):
                let (responses, unhandledRequests) = router.transform(requests: forwardedRequests)
                forwardedRequests = unhandledRequests
                responses.add(observer: allResponsesInput)

            case .endpoint(let endpoint):
                let (responses, unhandledRequests) = endpoint.transform(requests: forwardedRequests)
                forwardedRequests = unhandledRequests
                responses.add(observer: allResponsesInput)

            case .requestMiddleware(let requestMiddleware):
                let (transformedRequests, skippedRequests) =
                    requestMiddleware.transform(requests: forwardedRequests)
                forwardedRequests = transformedRequests
                skippedRequests.add(observer: allRequestsInput)

            }

        }
        forwardedRequests.add(observer: allRequestsInput)
        return (allResponses, allRequests)
    }

}

extension Router: CustomStringConvertible {

    public var description: String {
        return endpoints.map { $0.description }.joined(separator: "\n")
    }

}

enum RequestTransformer {
    case router(Router)
    case endpoint(Endpoint)
    case requestMiddleware(RequestMiddleware)
}

extension RequestTransformer: CustomStringConvertible {

    var description: String {
        switch self {
        case .router(let router):
            return router.description
        case .endpoint(let endpoint):
            return endpoint.description
        case .requestMiddleware(let requestMiddleware):
            return requestMiddleware.description
        }

    }

}

struct RequestMiddleware {

    typealias SourceType = Request
    typealias TransformedType = Request
    typealias ErrorType = ClientError

    weak var parent: Router?

    let transform: TransformType

    typealias TransformType = (Signal<Request>) -> (Signal<Request>, Signal<Request>)

    func transform(requests: Signal<Request>) -> (Signal<Request>, Signal<Request>) {
            return transform(requests)
    }

    init(parent: Router, _ transform: @escaping TransformType) {
        self.transform = transform
        self.parent = parent
    }

    var path: String {
        return (parent?.path ?? "")
    }

}

extension RequestMiddleware: CustomStringConvertible {

    var description: String {
        return ""
    }

}

struct Endpoint {

    let method: HTTP.Method?
    weak var parent: Router?
    let transform: TransformType

    typealias TransformType = (Signal<Request>) -> (Signal<Response>, Signal<Request>)

    func transform(requests: Signal<Request>) -> (Signal<Response>, Signal<Request>) {
        return transform(requests)
    }

    init(parent: Router? = nil, method: HTTP.Method? = nil, _ transform: @escaping TransformType) {
        self.transform = transform
        self.parent = parent
        self.method = method
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
