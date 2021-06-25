import SwiftUI

typealias FlowConfig = (Crumb) -> Void
public typealias FlowCallback<Output> = (Crumb, Output) -> Void

private var flowConfigs = [ObjectIdentifier: FlowConfig]()

func getFlowConfig<T>(_ type: T.Type) -> FlowConfig? {
    flowConfigs[ObjectIdentifier(T.self)]
}

public class Flow<T>: ObservableObject {
    
    private let callback: (T) -> Void
    
    init(callback: @escaping (T) -> Void) {
        self.callback = callback
    }
    
    public func callAsFunction(_ param: T) {
        callback(param)
    }
    
}

public extension View {

    static func flow<Output>(_ callback: @escaping FlowCallback<Output>) {
        let typeIdentifier = ObjectIdentifier(Self.self)
        let existingConfig = flowConfigs[typeIdentifier]
        
        flowConfigs[typeIdentifier] = { crumb in

            crumb.flow(Output.self) { output in
                callback(crumb, output)
            }
            
            existingConfig?(crumb)
        }
    }
    
}

public extension Crumb {
    
    func flow<T>(_ type: T.Type, _ callback: @escaping (T) -> Void) {
        guard let v = view else { fatalError() }
        swap { v.environmentObject(Flow<T>(callback: callback)).erased }
    }
    
}
