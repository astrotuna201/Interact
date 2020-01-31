//
//  RotatableDraggable.swift
//  
//
//  Created by Kieran Brown on 11/20/19.
//

import Foundation
import SwiftUI
import Combine


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct RotationDraggable<Handle: View, R: RotationModel, T: DragModel>: ViewModifier {
    @ObservedObject var rotationModel: R
    @ObservedObject var rotationGestureModel: RotationGestureModel
    @ObservedObject var translationModel: T
    var includesRotationGesture: Bool
    
    public init(dependencies: ObservedObject<GestureDependencies>, includesRotationGesture: Bool = true, rotationModel: R, translationModel: T) {
        
        
        self.rotationModel = rotationModel
        self.rotationGestureModel = RotationGestureModel(angle: dependencies.projectedValue.angle, rotation: dependencies.projectedValue.rotation)
        self.includesRotationGesture = includesRotationGesture
        self.translationModel = translationModel
        
    }
    
    var currentAngle: CGFloat {
        rotationModel.angle + rotationModel.gestureState.deltaTheta + rotationModel.rotation
    }
    
    public func body(content: Content) -> some View  {
        includesRotationGesture ?
            ZStack {
                AnyView(content
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.rotationModel.isSelected.toggle()
                        }
                }
                .simultaneousGesture(translationModel.gesture)
                .rotationEffect(Angle(radians: Double(currentAngle)))
                .simultaneousGesture(rotationGestureModel.rotationGesture)
                .overlay(self.rotationModel.overlay)
                .offset(x: translationModel.offset.width + translationModel.gestureState.translation.width,
                        y: translationModel.offset.height + translationModel.gestureState.translation.height)
                )
            }
            :
            ZStack {
                AnyView(content
                    .onTapGesture {
                        withAnimation(.easeIn(duration: 0.2)) {
                            self.rotationModel.isSelected.toggle()
                        }
                }
                .simultaneousGesture(translationModel.gesture)
                .rotationEffect(Angle(radians: Double(currentAngle)))
                .overlay(self.rotationModel.overlay)
                .offset(x: translationModel.offset.width + translationModel.gestureState.translation.width,
                        y: translationModel.offset.height + translationModel.gestureState.translation.height)
        )}
        
    }
}


