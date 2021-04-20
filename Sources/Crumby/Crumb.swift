import SwiftUI

public class Crumb: NSObject, ObservableObject {
    
    struct Tabs {
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
    var tabs: Tabs?
    
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
        tabs = nil
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
        tabs = newTabs
    }
    
    var selectedTab: Int? {
        tabs?.index.value
    }
    
    func selectTab(index: Int, onAppear: ((Crumb) -> Void)? = nil) {
        guard
            let tabs = tabs,
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
        var maybe: T? = nil
        
        visitAncestors { crumb in
            
            if let h = crumb.handle as? T {
                maybe = h
                maybeCrumb = crumb
                return false
            }
            
            return true
        }
        
        if let c = maybeCrumb, let m = maybe {
            return (c, m)
        }
        
        return nil
    }
    
}

extension Crumb {
    
//    func walkHierarchy(_ visit: (Crumb) -> Bool) {
//        var maybeParent = parent
//        while let p = maybeParent, visit(p) {
//            maybeParent = p.parent
//        }
//    }
    
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
