# crumby
```
import SwiftUI
import Crumby

struct RootView: View {
    
    var body: some View {
        CrumbView.root { TestView() }
    }
    
}

struct RootView: View {
    
    var body: some View {
        CrumbView.root { tab in
            tab(content: { TestView() }, item: { Text("t1") })
            tab(content: { TestView() }, item: { Text("t2") })
        }
    }
    
}


struct TestView: View {
    
    @EnvironmentObject var crumb: Crumb
    
    var body: some View {
        VStack {
            Text("crumb: \(crumb)")

            Button("sheet") { crumb.sheet { TestView() } }
            Button("push") { crumb.push { TestView() } }

            Button("swap") { crumb.swap { TestView().background(Color.init(.red)) } }
            Button("swap tabs") {
                crumb.swap { tab in
                    tab(content: { TestView() }, item: { Text("t1") })
                    tab(content: { TestView() }, item: { Text("t2") })
                }
            }

            Button("sheet tabView") {
                crumb.sheet { tab in
                    tab(content: { TestView() }, item: { Text("t1") })
                    tab(content: { TestView() }, item: { Text("t2") })
                }
            }

            Button("dismiss") { crumb.dismiss() }            
        }        
    }
    
}

```                  
