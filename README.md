# crumby
```
import SwiftUI
import Crumby

struct RootView: View {
    
    var body: some View {
        CrumbView.root(view: TestView().erased)
    }
    
}

struct TestView: View {
    
    @EnvironmentObject var crumb: Crumb
    
    var body: some View {
        VStack {
            Text("crumb: \(crumb)")

            Button("sheet") { crumb.sheet(view: TestView().erased) }
            Button("push") { crumb.push(view: TestView().erased) }
            
            Button("sheet tabView") { crumb.sheet(tabView: tabView) }
            Button("push tabView") { crumb.push(tabView: tabView) }
            
            Button("dismiss") { crumb.dismiss() }
            
            Button("print parent") { print(crumb.parent ) }
        }        
    }
    
}

let tabView = Crumb.TabView(views: [TestView(), TestView()].erased,
                            tabViews: [Text("t1"), Text("t2")].erased)
```                  
