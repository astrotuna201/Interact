//
//  RotationGestureModel.swift
//  
//
//  Created by Kieran Brown on 11/20/19.
//

import Foundation
import SwiftUI
//import Combine


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
class RotationGestureModel: ObservableObject {
    
    // MARK: Rotation Gesture
    
    @Binding var rotationState: CGFloat
    @Binding var angle: CGFloat
    
    var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged({ (value) in
                self.rotationState = CGFloat(value.radians)
            })
            .onEnded { (value) in
                self.angle += CGFloat(value.radians)
                self.rotationState = 0
        }
    }
    
    // MARK: Init
    init(angle: Binding<CGFloat>, rotation: Binding<CGFloat>) {
        self._angle = angle
        self._rotationState = rotation
    }
}
