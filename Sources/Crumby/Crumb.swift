import SwiftUI

public class Crumb: NSObject, ObservableObject {
    
    struct TabCrumbsWithIndex {
        let crumbs: [Crumb]
        var index: ObservableIndex
    }
    
    var view: AnyView?
    public let handle: Any?
    
    var isVisible = false
    var isSwapppingOutView = false
    public private(set) var parent: Crumb?
    let presentationType: ViewPresentationType
    
    @Published public private(set) var child: Crumb?
    var tabCrumbs: TabCrumbsWithIndex?
    public var tabs: [Crumb]? { tabCrumbs?.crumbs }
    
    var performOnAppearOnce = [() -> Void]()
    var performOnDisappearOnce = [() -> Void]()
    
    init(view: AnyView?, parent: Crumb?, presentationType: ViewPresentationType, handle: Any? = nil) {
        self.view = view
        self.parent = parent
        self.presentationType = presentationType
        self.handle = handle
    }
      
    convenience init<T: View>(@ViewBuilder content: () -> T, parent: Crumb?, presentationType: ViewPresentationType) {
        let c = content()
        self.init(view: c.erased,
                  parent: parent,
                  presentationType:presentationType,
                  handle: toHandle(c))
    }
        
}

public extension Crumb {
        
    func push<T: View>(@ViewBuilder content: @escaping () -> T, onAppear: ((Crumb) -> Void)? = nil) {
        let childCrumb = Crumb(content: content, parent: self, presentationType: .push)
        childCrumb.performOnAppearOnce(onAppear)
        child = childCrumb
    }
            
    func sheet<T: View>(@ViewBuilder content: @escaping () -> T, onAppear: ((Crumb) -> Void)? = nil) {
        let childCrumb = Crumb(content: content, parent: self, presentationType: .sheet)
        childCrumb.performOnAppearOnce(onAppear)
        child = childCrumb
    }
    
    func sheet(tabView: (inout TabViewBuilder) -> Void, onAppear: ((Crumb) -> Void)? = nil) {
        var builder = TabViewBuilder()
        tabView(&builder)
        let childCrumb = builder.toCrumb(parent: self, presentationType: .sheet)
        childCrumb.performOnAppearOnce(onAppear)
        child = childCrumb
    }
    
    func swap<T: View>(@ViewBuilder content: @escaping () -> T, onAppear: ((Crumb) -> Void)? = nil) {
        isSwapppingOutView = true
        tabCrumbs = nil
        performOnAppearOnce(onAppear)
        view = content().erased
    }

    func swap(tabView: (inout TabViewBuilder) -> Void, onAppear: ((Crumb) -> Void)? = nil) {
        isSwapppingOutView = true
        
        var builder = TabViewBuilder()
        tabView(&builder)
        let (newView, newTabs) = builder.makeViewAndTabs(parent: self)
        
        performOnAppearOnce(onAppear)
        
        view = newView
        tabCrumbs = newTabs
    }
    
    var selectedTab: Int? {
        tabCrumbs?.index.value
    }
    
    func selectTab(index: Int, onAppear: ((Crumb) -> Void)? = nil) {
        guard
            let tabs = tabCrumbs,
            (tabs.crumbs.count - 1) <= index,
            tabs.index.value != index
        else { return }
        
        let crumb = tabs.crumbs[index]
        
        crumb.performOnAppearOnce(onAppear)
        
        tabs.index.value = index
    }

    func parent(ofPresentationType type: ViewPresentationType) -> Crumb? {
        var result: Crumb? = nil
        
        visitAncestors {
            if $0.presentationType == type {
                result = $0
                return false
            }
            
            return true
        }
        
        return result
    }
    
    func getParentTabView() -> Crumb? {
        presentationType == .tab
            ? parent
            : parent(ofPresentationType: .tab)?.parent
    }
    
    func dismiss(onDisappear: ((Crumb) -> Void)? = nil) {
        guard let p = parent, ![.tab, .root].contains(presentationType) else { return }
        
        performOnDisappearOnce(onDisappear)
        
        disconnect()
        
        p.printHierarchy()
    }
    
    func get<T>(ofType type: T.Type) -> (crumb: Crumb, handle: T)? {
        var maybeCrumb: Crumb? = nil
        var maybeHandle: T? = nil
        
        visitEveryone {
            guard let handle = $0.handle as? T else { return true }
            
            maybeCrumb = $0
            maybeHandle = handle
            return false
        }
        
        if let c = maybeCrumb, let h = maybeHandle {
            return (c, h)
        }
        return nil
    }
    
    func makeVisible() {
        child?.dismiss()
        
        var trailingCrumb = self
        visitAncestors {
            if let t = $0.tabCrumbs, let index = t.crumbs.firstIndex(of: trailingCrumb) {
                t.index.value = index
            }
            
            trailingCrumb = $0
            return true
        }
        
    }
    
}

extension Crumb {
    
    func disconnect() {
        tabCrumbs?.crumbs.forEach { $0.disconnect() }
        child?.disconnect()
        
        child = nil
        tabCrumbs = nil
        
        parent?.child = nil
        parent?.tabCrumbs = nil
        parent = nil
    }
    
    func visitEveryone(from: Crumb? = nil, visit: (Crumb) -> Bool) {
        
        let crumbsToVisit = ([parent, child].compactMap { $0 } + (tabCrumbs?.crumbs ?? [])).filter { $0 != from }
        
        for crumbToVisit in crumbsToVisit {
            guard visit(crumbToVisit) else { return }
         
            crumbToVisit.visitEveryone(from: self, visit: visit)
        }
    }
    
    func visitAncestors(_ visit: (Crumb) -> Bool) {
        var maybeParent = parent
        while let p = maybeParent, visit(p) {
            maybeParent = p.parent
        }
    }
    
    var ancestors: [Crumb] {
        var array = [Crumb]()
        
        visitAncestors {
            array.append($0)
            return true
        }
        
        return array
    }
    
    var distancesToFirst: [ViewPresentationType: Int] {
        ancestors.enumerated().reduce(into: [ViewPresentationType: Int]()) {
            $0[$1.element.presentationType] = $0[$1.element.presentationType] ?? $1.offset
        }
    }
    
    func performOnAppearOnce(_ callback: ((Crumb) -> Void)?) {
        guard let callback = callback else { return }
        performOnAppearOnce.append {
            callback(self)
        }
    }
    
    func performOnDisappearOnce(_ callback: ((Crumb) -> Void)?) {
        guard let callback = callback else { return }
        performOnDisappearOnce.append {
            callback(self)
        }
    }
    
}


extension Crumb {
    
    func printHierarchy() {
        
//        return 
//        var crumbs = [self]
//
//        var maybeParent = parent
//        while let p = maybeParent {
//            crumbs.append(p)
//            maybeParent = p.parent
//        }
//
//        let output = crumbs
//            .reversed()
//            .enumerated()
//            .reduce(into: "\n\(String(repeating: "-", count: 20))\nNavigationStack\n\(String(repeating: "-", count: 20))")
//            {
//                if $1.offset > 0 {
//                    $0.append("\nV")
//                }
//
//                let crumb = $1.element
//                if let parent = crumb.parent {
//                    $0.append("\n parent: \(parent)")
//                }
//
//                $0.append("\n crumb: \(crumb) \(crumb.presentationType)")
//
//                if let tabs = crumb.tabs {
//                    $0.append("\n tabs: \(tabs)" )
//                }
//
//
//                if let child = crumb.child {
//                    $0.append("\n child: \(child)" )
//                }
//
//            }.appending("\n\(String(repeating: "-", count: 20))")
//
//        print(output)
    }
    
}
