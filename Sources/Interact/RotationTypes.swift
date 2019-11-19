//
//  File.swift
//  
//
//  Created by Kieran Brown on 11/19/19.
//

import Foundation
import SwiftUI


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol RotationOverlayState {
    
    var deltaTheta: CGFloat { get }
    
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol RotationModel: ObservableObject {
    var angle: CGFloat { get set }
    var gestureState: RotationOverlayState { get set }
    var isSelected: Bool { get set }
    var overlay: AnyView { get }
}




@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public enum RotationType<Handle: View>  {
    case normal(handle: (Bool, Bool) -> Handle)
    /// Default Values `model = AngularVelocity()`, `threshold = 0` .
    /// *Threshold* is the angular velocity required to start spinning the view upon release of the drag gesture
    case spinnable(model: AngularVelocityModel = AngularVelocity(), threshold: CGFloat = 0, handle: (Bool, Bool) -> Handle)
    
}
