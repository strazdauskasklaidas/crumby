import SwiftUI

public struct TabViewBuilder {
    
    private var tabs = [AnyView]()
    private var items = [AnyView]()
    
    public mutating func callAsFunction<T: View, I: View>(@ViewBuilder content: @escaping () -> T, @ViewBuilder item: @escaping () -> I) {
        tabs = tabs + [content().erased]
        items = items + [item().erased]
    }
        
}

extension TabViewBuilder {
    
    func makeViewAndTabs(parent: Crumb) -> (AnyView, Crumb.Tabs) {
        let tabs = Crumb.Tabs(crumbs: self.tabs.map { v in
                                .init(view: v,
                                      parent: parent,
                                      presentationType: .tab) },
                              index: .init(index: 0))
        
        let view = TabCrumbView(index: tabs.index) {
            ForEach(self.tabs.identified) { (v: AnyView.WithId) in
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
