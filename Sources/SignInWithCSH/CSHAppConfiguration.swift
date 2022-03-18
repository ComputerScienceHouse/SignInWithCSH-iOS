import Foundation

public struct CSHAppConfiguration {
    public var clientID: String
    public var redirectURL: URL
    public var issuer: URL
    public var scopes: [OpenIDScope]

    public init(
        clientID: String,
        redirectURL: URL,
        issuer: URL,
        scopes: [OpenIDScope]
    ) {
        self.clientID = clientID
        self.redirectURL = redirectURL
        self.issuer = issuer
        self.scopes = scopes
    }
}
