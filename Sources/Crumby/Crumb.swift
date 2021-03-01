import SwiftUI

public class Crumb: NSObject, ObservableObject {

    struct TabView {
        let views: [AnyView]
        let tabViews: [AnyView]
        
        init(views: [AnyView], tabViews: [AnyView]) {
            self.views = views
            self.tabViews = tabViews
        }
    }
    
    struct Tabs {
        let crumbs: [Crumb]
        var index: ObservableIndex
    }
    
    var view: AnyView?
    var isVisible = false
    var isSwapppingOutView = false
    @Published var parent: Crumb?
    let presentationType: ViewPresentationType
    
    @Published var child: Crumb?
    @Published var tabs: Tabs?
    
    init(view: AnyView?, parent: Crumb?, presentationType: ViewPresentationType) {
        self.view = view
        self.parent = parent
        self.presentationType = presentationType
    }
        
    deinit { print("deinit \(self)") }
        
    func dismiss() {
        guard presentationType != .tab else { return }
        
        let p = parent
        
        disconnect()
        
        p?.printHierarchy()
    }
    
    func disconnect() {
        tabs?.crumbs.forEach { $0.disconnect() }
        child?.disconnect()
        
        child = nil
        tabs = nil
        
        parent?.child = nil
        parent?.tabs = nil
        parent = nil
    }
    
}


// root -> navi -> view

extension View {

    func wrapInNavigationView() -> AnyView {
        NavigationView { self }
            .navigationViewStyle(StackNavigationViewStyle())
            .erased
    }

}

extension Crumb {

    func wrapInNavigationView() -> AnyView {
        CrumbView<AnyView>(crumb: self)
            .wrapInNavigationView()
    }

}

extension Crumb.TabView {

    func toCrumb(parent: Crumb?, presentationType: ViewPresentationType) -> Crumb {
        let crumb = Crumb(view: nil, parent: parent, presentationType: presentationType)
        let tabs = Crumb.Tabs(crumbs: views.map { .init(view: $0.wrapInNavigationView(),
                                                        parent: crumb,
                                                        presentationType: .tab) },
                              
                              index: .init(index: 0))
        
        crumb.tabs = tabs
        crumb.view = TabCrumbView(index: tabs.index) {
            ForEach(views.identified) { (v: AnyView.WithId) in
                CrumbView<AnyView>(crumb: tabs.crumbs[v.id])
                    .tabItem { tabViews[v.id] }
            }
        }
        .erased
        
        return crumb
    }

}

extension CrumbView where Content == AnyView {
    
    static func root(view: AnyView, rootCrumb callback: ((Crumb) -> Void)? = nil) -> AnyView {
        let crumb = Crumb(view: view.erased, parent: nil, presentationType: .root)
        callback?(crumb)
        
        
        
        return
//            NavigationView {
            CrumbView(crumb: crumb).wrapInNavigationView()
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//        .erased
    }
    
//    static func root(tabView: Crumb.TabView, rootCrumb callback: ((Crumb) -> Void)? = nil) -> AnyView {
//        let crumb = tabView.toCrumb(parent: nil, presentationType: .root)
//        callback?(crumb)
//        return crumb.wrapInNavigationView()
//    }
        
}



extension Crumb {
    
    func push(view: AnyView) {
        let c = Crumb(view: view, parent: self, presentationType: .push)
        child = c
    }
    
    func push(tabView: TabView) {
        child = tabView.toCrumb(parent: self, presentationType: .push)
    }
    
    func sheet(view: AnyView) {
        child = .init(view: view, parent: self, presentationType: .sheet)
    }
    
    func sheet(tabView: TabView) {
        child = tabView.toCrumb(parent: self, presentationType: .sheet)
    }
    
//    func swapOut(withView view: AnyView) {
//
//    }
//
//    func swapOut(withTabView tabView: TabView) {
//
//    }
    
}

extension Crumb {
    
    var ancestors: [Crumb] {
        var array = [Crumb]()
        
        var maybeParent = parent
        while let p = maybeParent {
            array.append(p)
            maybeParent = p.parent
        }
        
        return array
    }
    
    var distancesToFirst: [ViewPresentationType: Int] {
        ancestors.enumerated().reduce(into: [ViewPresentationType: Int]()) {
            $0[$1.element.presentationType] = $0[$1.element.presentationType] ?? $1.offset
        }
    }

    
}


extension Crumb {
    
    func printHierarchy() {
        
        return 
        var crumbs = [self]

        var maybeParent = parent
        while let p = maybeParent {
            crumbs.append(p)
            maybeParent = p.parent
        }

        let output = crumbs
            .reversed()
            .enumerated()
            .reduce(into: "\n\(String(repeating: "-", count: 20))\nNavigationStack\n\(String(repeating: "-", count: 20))")
            {
                if $1.offset > 0 {
                    $0.append("\nV")
                }

                let crumb = $1.element
                if let parent = crumb.parent {
                    $0.append("\n parent: \(parent)")
                }

                $0.append("\n crumb: \(crumb) \(crumb.presentationType)")
                
                if let tabs = crumb.tabs {
                    $0.append("\n tabs: \(tabs)" )
                }
                

                if let child = crumb.child {
                    $0.append("\n child: \(child)" )
                }

            }.appending("\n\(String(repeating: "-", count: 20))")

        print(output)
    }
    
}
