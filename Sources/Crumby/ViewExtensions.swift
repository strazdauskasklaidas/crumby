import SwiftUI

public extension Array where Element: View {
    
    var erased: [AnyView] {
        map { $0.erased }
    }
    
}

extension View {

    func applyIf<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            return AnyView(content(self))
        }

        return AnyView(self)
     }

    func applyWith<Data, Content: View>(_ data: Data?, content: (Self, Data) -> Content) -> some View {
        if let d = data {
            return AnyView(content(self, d))
        }

        return AnyView(self)
     }

    public var erased: AnyView {
        .init(erasing: self)
    }

}

extension AnyView {
    
    struct WithId: Identifiable {
        let id: Int
        let view: AnyView
    }
    
}

extension Array where Element == AnyView {

    var identified: [AnyView.WithId] {
        enumerated().map { .init(id: $0.offset, view: $0.element) }
    }

}
