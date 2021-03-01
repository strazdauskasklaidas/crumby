import SwiftUI

class ObservableIndex: ObservableObject {
    @Published var value: Int
    
    init(index: Int) {
        self.value = index
    }
}
