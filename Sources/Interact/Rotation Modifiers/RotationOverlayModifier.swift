//
//  RotationOverlayModifier.swift
//  
//
//  Created by Kieran Brown on 11/19/19.
//

import Foundation
import SwiftUI 
//import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct RotationOverlayModifier<Handle: View, R: RotationModel>: ViewModifier {
    @ObservedObject var model: R
    @ObservedObject var rotationGestureModel: RotationGestureModel
    var includesRotationGesture: Bool
    
    public init(dependencies: ObservedObject<GestureDependencies>, includesRotationGesture: Bool = true, rotationModel: R) {
        
        
        self.model = rotationModel
        self.rotationGestureModel = RotationGestureModel(angle: dependencies.projectedValue.angle, rotation: dependencies.projectedValue.rotation)
        self.includesRotationGesture = includesRotationGesture
        
    }
    
    var currentAngle: CGFloat {
        model.angle + model.gestureState.deltaTheta + model.rotation
    }
    
    public func body(content: Content) -> some View  {
        includesRotationGesture ?
            ZStack {
                AnyView(content
                    .rotationEffect(Angle(radians: Double(currentAngle)))
                    .simultaneousGesture(rotationGestureModel.rotationGesture)
                    .overlay(self.model.overlay)
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.model.isSelected.toggle()
                        }
                })
            }
        :
            ZStack {
                AnyView(content
                    .rotationEffect(Angle(radians: Double(currentAngle)))
                    .overlay(self.model.overlay)
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.model.isSelected.toggle()
                        }
                })
        }
    }
}




