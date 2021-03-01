import SwiftUI

struct TabCrumbView<Content: View>: View {

    @ObservedObject private var index: ObservableIndex
    private var content: () -> Content
    
    init(index: ObservableIndex, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.index = index
    }
    
    var body: some View {
        TabView(selection: $index.value, content: content)
            .navigationBarHidden(true)
    }
    
}
