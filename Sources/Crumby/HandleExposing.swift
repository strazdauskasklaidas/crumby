import SwiftUI

public protocol HandleExposing {

    var handle: Any { get }

}

func toHandle(_ any: Any) -> Any? {
    (any as? HandleExposing)?.handle
}

