import SwiftUI

// Tab push Appear
//xxx appear tab
//xxx appear first
//xxx disa par

// Tab push disappear
//xxx appear par
//xxx disa first
//xxx disa tab

// Tab sheet appear
//xxx appear tab
//xxx appear first

// Tab sheet disappear
// xxx disa tab
// xxx disa first

// Embed
// new view appears
// old disappears

public struct CrumbView<Content: View>: View {
    
    @ObservedObject private var crumb: Crumb
    
    init(crumb: Crumb) {
        self.crumb = crumb
    }
    
    public var body: some View {
        VStack {
            crumb.view
                .environmentObject(crumb)
                .onAppear(perform: onAppear)
                .onDisappear(perform: onDisappear)
                
            if let child = crumb.child, child.presentationType == .push {
                NavigationLink("",
                               destination: CrumbView(crumb: child),
                               isActive: .constant(true))
                    .frame(width: 0, height: 0, alignment: .bottom)
                    .hidden()
            }
        }
        .sheet(isPresented: .init(get: { crumb.child?.presentationType == .sheet }, set: { _ in })) {
            CrumbView(crumb: crumb.child!)
        }
        .applyIf(crumb.shouldBeWrappedInNavigationView) { v in
            NavigationView { v }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func onAppear() {
//        print("xxx onAppear \(crumb)")
        
        defer {
            crumb.performOnAppearOnce.forEach { $0() }
            crumb.performOnAppearOnce.removeAll()
        }
        
        if crumb.isSwapppingOutView {
            crumb.isSwapppingOutView = false
            return
        }
        
        crumb.isVisible = true
    }
    
    private func onDisappear() {
//        print("xxx onDisappear \(crumb)")
        
        defer {
            crumb.performOnDisappearOnce.forEach { $0() }
            crumb.performOnDisappearOnce.removeAll()
        }
        
        guard !crumb.isSwapppingOutView else { return }

        crumb.isVisible = false
        
        let parentIsVisible = crumb.parent?.isVisible ?? false
        
        switch crumb.presentationType {
        case .push:
            if parentIsVisible{
                crumb.disconnect()
            } else if crumb.child == nil, let parentSheet = crumb.parent(ofPresentationType: .sheet), parentSheet.child?.presentationType == .push {
                parentSheet.disconnect()
            }
            
        case .sheet where parentIsVisible && crumb.child?.presentationType != .push:
            crumb.disconnect()
        default:
            return
        }
        
    }
            
}

private extension Crumb {

    var shouldBeWrappedInNavigationView: Bool {
        switch presentationType {
        case .root where tabs == nil:
            return true
        case .sheet where tabs == nil:
            return true
        case .tab:
            return true
        default:
            return false
        }
    }

}

public extension CrumbView where Content == AnyView {
    
    static func root<T: View>(@ViewBuilder content: @escaping () -> T, rootCrumb callback: ((Crumb) -> Void)? = nil) -> AnyView {
        let crumb = Crumb(content: content, parent: nil, presentationType: .root)
        callback?(crumb)
        
        return CrumbView(crumb: crumb).erased
    }

    static func root(tabView: (inout TabViewBuilder) -> Void, rootCrumb callback: ((Crumb) -> Void)? = nil) -> AnyView {
        var builder = TabViewBuilder()
        tabView(&builder)
        let crumb = builder.toCrumb(parent: nil, presentationType: .root)
        callback?(crumb)
        
        return CrumbView(crumb: crumb).erased
    }
            
}
