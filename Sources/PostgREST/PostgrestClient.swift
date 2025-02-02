import Foundation

/// This is the main class in this package. Use it to execute queries on a PostgREST instance on Supabase.
public class PostgrestClient {
  /// Configuration for the client
  public var config: PostgrestClientConfig

  /// Struct for PostgrestClient config options
  public struct PostgrestClientConfig {
    public var url: String
    public var headers: [String: String]
    public var schema: String?
    public var delegate: PostgrestClientDelegate

    public init(
      url: String,
      headers: [String: String] = [:],
      schema: String?,
      delegate: PostgrestClientDelegate? = nil
    ) {
      self.url = url
      self.headers = headers.merging(Constants.defaultHeaders) { old, _ in old }
      self.schema = schema
      self.delegate = delegate ?? DefaultPostgrestClientDelegate()
    }
  }

  /// Initializes the `PostgrestClient` with the correct parameters.
  /// - Parameters:
  ///   - url: Url of your supabase db instance
  ///   - headers: Headers to include when querying the database. Eg, an authentication header
  ///   - schema: Schema ID to use
  public init(
    url: String,
    headers: [String: String] = [:],
    schema: String?,
    delegate: PostgrestClientDelegate? = nil
  ) {
    self.config = PostgrestClientConfig(
      url: url,
      headers: headers,
      schema: schema,
      delegate: delegate
    )
  }

  /// Initializes the `PostgrestClient` with a config object
  /// - Parameter config: A `PostgrestClientConfig` struct with the correct parameters
  public init(config: PostgrestClientConfig) {
    self.config = config
  }

  /// Authenticates the request with JWT.
  /// - Parameter token: The JWT token to use.
  public func auth(_ token: String) -> PostgrestClient {
    config.headers["Authorization"] = "Bearer \(token)"
    return self
  }

  /// Select a table to query from
  /// - Parameter table: The ID of the table to query
  /// - Returns: `PostgrestQueryBuilder`
  public func from(_ table: String) -> PostgrestQueryBuilder {
    PostgrestQueryBuilder(
      client: self,
      url: "\(config.url)/\(table)",
      headers: config.headers,
      schema: config.schema,
      method: nil,
      body: nil,
      delegate: config.delegate
    )
  }

  /// Perform a function call.
  /// - Parameters:
  ///   - fn: The function name to call.
  ///   - params: The parameters to pass to the function call.
  public func rpc<U: Encodable>(
    fn: String,
    params: U?,
    count: CountOption? = nil
  ) -> PostgrestTransformBuilder {
    PostgrestRpcBuilder(
      client: self,
      url: "\(config.url)/rpc/\(fn)",
      headers: config.headers,
      schema: config.schema,
      method: nil,
      body: nil,
      delegate: config.delegate
    ).rpc(params: params, count: count)
  }

  /// Perform a function call.
  /// - Parameters:
  ///   - fn: The function name to call.
  ///   - params: The parameters to pass to the function call.
  public func rpc(
    fn: String,
    count: CountOption? = nil
  ) -> PostgrestTransformBuilder {
    rpc(fn: fn, params: EmptyParams(), count: count)
  }
}

public protocol PostgrestClientDelegate {
  func client(
    _ client: PostgrestClient,
    willSendRequest request: URLRequest,
    completion: @escaping (URLRequest) -> Void
  )
}

extension PostgrestClientDelegate {
  public func client(
    _ client: PostgrestClient,
    willSendRequest request: URLRequest,
    completion: @escaping (URLRequest) -> Void
  ) {
    completion(request)
  }
}

struct DefaultPostgrestClientDelegate: PostgrestClientDelegate {}
