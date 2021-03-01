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

struct CrumbView<Content: View>: View {
    
    @ObservedObject private var crumb: Crumb
    
    init(crumb: Crumb) {
        self.crumb = crumb
    }
    
    var body: some View {

            
        VStack {
            crumb.view
                .environmentObject(crumb)
                
            if let child = crumb.child, child.presentationType == .push {
                NavigationLink("",
                               destination: CrumbView(crumb: child),
                               isActive: .constant(true))
                    .frame(width: 0, height: 0, alignment: .bottom)
                    .hidden()
            }
            
        }
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .sheet(isPresented: .init(get: { crumb.child?.presentationType == .sheet }, set: { _ in })) {
                CrumbView(crumb: crumb.child!)
        }.applyIf([.sheet].contains(crumb.presentationType)) { v in
            NavigationView {
                v
            }.navigationViewStyle(StackNavigationViewStyle())
        }
            

    }
    
    private func onAppear() {
        print("xxx onAppear \(crumb)")
        if crumb.isSwapppingOutView {
            crumb.isSwapppingOutView = false
            return
        }
        
        crumb.isVisible = true
    }
    
    private func onDisappear() {
        print("xxx onDisappear \(crumb)")
        guard !crumb.isSwapppingOutView else { return }

        crumb.isVisible = false
        
        //Push disappear
        if crumb.presentationType == .push && crumb.parent?.isVisible ?? false  {
            crumb.disconnect()
            return
        }

        // sheet disappear
        // sheet -> push -> swipe down = poop
        if crumb.presentationType == .sheet && crumb.parent?.isVisible ?? false && crumb.child?.presentationType != .push {
            crumb.disconnect()
            return
        }
    }
            
}
