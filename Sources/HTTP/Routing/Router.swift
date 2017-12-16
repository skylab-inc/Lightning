import Foundation
import StreamKit
import PromiseKit
import PathToRegex
import Regex

/*
        let (matches, leftover) = requests.partition { request in
            return self.parent?.matches(path: request.uri.path) ?? false
                && request.method == self.method ?? request.method
        }
*/
enum RequestMapper {
    case sync((Request) -> Request)
    case async((Request) -> Promise<Request>)
}

enum ResponseMapper {
    case sync((Response) -> Response)
    case async((Response) -> Promise<Response>)
}

enum RequestHandler {
    case sync((Request) throws -> Response)
    case async((Request) -> Promise<Response>)
}

protocol HandlerNode: RouterNode, CustomStringConvertible {
    func handle(
        requests: Signal<Request>,
        responses: Signal<Response>
    ) -> (
        handled: Signal<Response>,
        unhandled: Signal<Request>
    )
}

protocol FilterNode: RouterNode, CustomStringConvertible {
    func filter(
        requests: Signal<Request>
    ) -> (
        requests: Signal<Request>,
        filtered: Signal<Request>
    )
}

protocol RouterNode {

    var parent: Router? { get }
    var path: String { get }
    var routePath: String { get }

}

extension RouterNode {

    var path: String {
        return "/"
    }

    var routePath: String {
        let parentRoutePath = parent?.routePath ?? "/"
        return Path.join(parentRoutePath, path)
    }

    var depth: Int {
        var p = parent
        var d = 0
        while p != nil {
            p = p!.parent
            d += 1
        }
        return d
    }

    func matches(urlPath: String) -> Bool {
        // Fast matching for the simple cases
        if routePath == "/" || routePath == "*" {
            return true
        }
        let routeRegex = try! Regex(path: urlPath)
        guard let _ = routeRegex.findFirst(in: urlPath) else {
            return false
        }
        return true
    }

}

enum RoutingNode: RouterNode, CustomStringConvertible {

    case filter(FilterNode)
    case handler(HandlerNode)

    var parent: Router? {
        switch self {
            case .filter(let node):
                return node.parent
            case .handler(let node):
                return node.parent
        }
    }

    var description: String {
        switch self {
            case .filter(let node):
                return node.description
            case .handler(let node):
                return node.description
        }
    }

}

public final class Router: HandlerNode {

    weak var parent: Router? = nil
    var nodes: [RoutingNode] = []
    var path: String

    public init() {
        self.path = "/"
    }

    func setParameters(on request: Request, match: Match, regex: Regex) {
        let valsArray = regex.groupNames.map { name in
            (name, match.group(named: name))
        }.filter {$0.1 != nil} . map { tuple in
            (tuple.0, tuple.1!)
        }
        request.parameters = Dictionary(uniqueKeysWithValues: valsArray)
    }

    func shouldHandle(_ request: Request) -> Bool {
        if path == "/" || path == "*" {
            return true
        }
        let urlPath = String(request.uri.absoluteString.prefix(
            upTo: request.uri.absoluteString.index(of: "?") ?? request.uri.absoluteString.endIndex
        ))
        let regexPath = routePath
        let regex = try! Regex(path: regexPath, pathOptions: [])
        guard let match = regex.findFirst(in: urlPath) else {
            return false
        }
        setParameters(on: request, match: match, regex: regex)
        return true
    }

    private init(
        parent: Router,
        path: String?
    ) {
        self.parent = parent
        self.path = path ?? "/"
    }

    private func add(
        path: String? = nil,
        method: HTTP.Method? = nil,
        _ handler: RequestHandler
    ) {
        let subrouter = Router(parent: self, path: path)
        let endpoint = Endpoint(parent: subrouter, method: method, handler)
        subrouter.nodes.append(.handler(endpoint))
        nodes.append(.handler(subrouter))
    }

    func handle(
        requests: Signal<Request>,
        responses: Signal<Response>
    ) -> (
        handled: Signal<Response>,
        unhandled: Signal<Request>
    ) {
        let (unhandled, unhandledInput) = Signal<Request>.pipe()
        var (needsHandling, filtered) = requests.partition(self.shouldHandle)

        // Send filtered to the unhandled output requests of this router.
        filtered.add(observer: unhandledInput)

        // Handle as yet unhandled
        var handled = responses
        for node in nodes {
            switch node {
                case .filter(let node):
                    let newlyFiltered: Signal<Request>
                    // Partition requests that still need handling and the ones that are filtered
                    // Send the ones that need handling onto the next node
                    // Send the filtered ones to the unhandled output
                    (needsHandling, newlyFiltered) = node.filter(requests: needsHandling)
                    newlyFiltered.add(observer: unhandledInput)
                case .handler(let node):
                    (handled, needsHandling) = node.handle(requests: needsHandling, responses: handled)
            }
        }
        needsHandling.add(observer: unhandledInput)
        return (handled: handled, unhandled: unhandled)
    }

}

extension Router: CustomStringConvertible {

    public var description: String {
        return "ROUTER '\(routePath)'" + (nodes.count > 0 ? "\n" : "") + nodes.map {
            (0...depth).map { _ in "\t" } + $0.description
        }.joined(separator: "\n")
    }

}

extension Router: ServerDelegate {

    public func handle(requests: Signal<Request>) -> Signal<Response> {
        let (handled, unhandled) = handle(requests: requests, responses: Signal<Response>.empty)
        let notFound = unhandled.map { request in
            // TODO: warn about unhandled request
            return Response(status: .notFound)
        }
        let (responses, responsesInput) = Signal<Response>.pipe()
        handled.add(observer: responsesInput)
        notFound.add(observer: responsesInput)
        return responses
    }

}

/// Route building
extension Router {

    public func add(_ subrouter: Router) {
        add(nil, subrouter)
    }

    public func add(_ path: String? = nil, _ subrouter: Router) {
        subrouter.path = path ?? "/"
        subrouter.parent = self
        nodes.append(.handler(subrouter))
    }

    public func subrouter(_ path: String) -> Router {
        let subrouter = Router(parent: self, path: path)
        nodes.append(.handler(subrouter))
        return subrouter
    }

}

/// Async Transforms
extension Router {

    public func any(_ path: String? = nil, _ transform: @escaping (Request) -> Promise<Response>) {
        add(path: path, .async(transform))
    }

    public func get(_ path: String? = nil, _ transform: @escaping (Request) -> Promise<Response>) {
        add(path: path, method: .get, .async(transform))
    }

    public func post(_ path: String? = nil, _ transform: @escaping (Request) -> Promise<Response>) {
        add(path: path, method: .post, .async(transform))
    }

    public func put(_ path: String? = nil, _ transform: @escaping (Request) -> Promise<Response>) {
        add(path: path, method: .put, .async(transform))
    }

    public func delete(_ subpath: String? = nil, _ transform: @escaping (Request) -> Promise<Response>) {
        add(path: path, method: .delete, .async(transform))
    }
}

/// Sync transforms
extension Router {

    public func any(_ path: String? = nil, _ transform: @escaping (Request) throws -> Response) {
        add(path: path, .sync(transform))
    }

    public func get(_ path: String? = nil, _ transform: @escaping (Request) -> Response) {
        add(path: path, method: .get, .sync(transform))
    }

    public func post(_ path: String? = nil, _ transform: @escaping (Request) -> Response) {
        add(path: path, method: .post, .sync(transform))
    }

    public func put(_ path: String? = nil, _ transform: @escaping (Request) -> Response) {
        add(path: path, method: .put, .sync(transform))
    }

    public func delete(_ path: String? = nil, _ transform: @escaping (Request) -> Response) {
        add(path: path, method: .delete, .sync(transform))
    }

    public func map(_ transform: @escaping (Request) -> Request) {
        nodes.append(.handler(RequestMiddleware(parent: self, .sync(transform))))
    }

    public func filter(_ predicate: @escaping (Request) -> Bool) {
        nodes.append(.filter(Filter(parent: self, predicate: predicate)))
    }

    public func mapResponses(_ transform: @escaping (Response) -> Response) {
        nodes.append(.handler(ResponseMiddleware(parent: self, .sync(transform))))
    }

}
