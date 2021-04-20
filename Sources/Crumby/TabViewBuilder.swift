import SwiftUI

public struct TabViewBuilder {
    
    private var tabs = [(view: AnyView, handle: Any?)]()
    private var items = [AnyView]()
    
    public mutating func callAsFunction<T: View, I: View>(@ViewBuilder content: @escaping () -> T, @ViewBuilder item: @escaping () -> I) {
        let c = content()
        tabs = tabs + [(c.erased, toHandle(c))]
        items = items + [item().erased]
    }
        
}

extension TabViewBuilder {
    
    func makeViewAndTabs(parent: Crumb) -> (AnyView, Crumb.Tabs) {
        let tabs = Crumb.Tabs(crumbs: self.tabs.map { tab in
                                .init(view: tab.view,
                                      parent: parent,
                                      presentationType: .tab,
                                      handle: tab.handle) },
                              index: .init(index: 0))
        
        let view = TabCrumbView(index: tabs.index) {
            ForEach(self.tabs.map { $0.view }.identified) { (v: AnyView.WithId) in
                CrumbView<AnyView>(crumb: tabs.crumbs[v.id])
                    .tabItem { items[v.id] }
            }
        }
        .erased
        
        return (view, tabs)
    }
    
    func toCrumb(parent: Crumb?, presentationType: ViewPresentationType) -> Crumb {
        let crumb = Crumb(view: nil, parent: parent, presentationType: presentationType)
        let (view, tabs) = makeViewAndTabs(parent: crumb)
        
        crumb.view = view
        crumb.tabs = tabs
        
        return crumb
    }

}
