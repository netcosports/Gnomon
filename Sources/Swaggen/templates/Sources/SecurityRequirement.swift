{% include "Includes/Header.stencil" %}

public struct SecurityRequirement {
    public let type: String
    public let scopes: [String]

    public init(type: String, scopes: [String]) {
        self.type = type
        self.scopes = scopes
    }
}
