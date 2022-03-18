import AppAuth

public struct OpenIDScope: RawRepresentable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var profile: OpenIDScope {
        OpenIDScope(rawValue: OIDScopeProfile)
    }

    public static var email: OpenIDScope {
        OpenIDScope(rawValue: OIDScopeEmail)
    }

    public static var phone: OpenIDScope {
        OpenIDScope(rawValue: OIDScopePhone)
    }

    public static var address: OpenIDScope {
        OpenIDScope(rawValue: OIDScopeAddress)
    }

    public static var openID: OpenIDScope {
        OpenIDScope(rawValue: OIDScopeOpenID)
    }

    public static var offlineAccess: OpenIDScope {
        OpenIDScope(rawValue: "offline_access")
    }
}
