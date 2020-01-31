//
//  View+Rotatable.swift
//  
//
//  Created by Kieran Brown on 11/20/19.
//

import Foundation
import SwiftUI
import Combine


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension View {
    
    func rotatable<RotationHandle: View>(initialSize: CGSize, includesRotationGesture: Bool = true,  @ViewBuilder handle: @escaping (Bool, Bool) -> RotationHandle) -> some View {
        self.injectDependencies(initialSize: initialSize) { (dependencies)  in
            RotationOverlayModifier<RotationHandle, RotationOverlayModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: RotationOverlayModel(dependencies: dependencies, handle: handle))
        }
    }
    
    
    
    func rotatable<RotationHandle: View>(initialSize: CGSize, includesRotationGesture: Bool = true,  @ViewBuilder handle: @escaping (Bool, Bool) -> RotationHandle, dragType: DragType) -> some View {
        
        switch dragType {
        case .drag:
            return AnyView(self.injectDependencies(initialSize: initialSize) { (dependencies)  in
                RotationDraggable<RotationHandle, RotationOverlayModel, DragGestureModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: RotationOverlayModel<RotationHandle>(dependencies: dependencies, handle: handle), translationModel: DragGestureModel(offset: dependencies.projectedValue.offset, dragState: dependencies.projectedValue.dragState))
            })
        case .throwable(let model, let threshold):
            return AnyView(self.injectDependencies(initialSize: initialSize) { (dependencies)  in
                RotationDraggable<RotationHandle, RotationOverlayModel, ThrowableModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: RotationOverlayModel<RotationHandle>(dependencies: dependencies, handle: handle), translationModel: ThrowableModel(dependencies: dependencies, model: model, threshold: threshold))
                
            })
        }
        
    }
    
    
    
    
    func spinnable<RotationHandle: View>(initialSize: CGSize = CGSize(width: 100, height: 100), includesRotationGesture: Bool = true, model: AngularVelocityModel = AngularVelocity(), threshold: CGFloat = 0, @ViewBuilder handle: @escaping (Bool, Bool) -> RotationHandle, dragType: DragType) -> some View {
        
        switch dragType {
        case .drag:
            return AnyView(self.injectDependencies(initialSize: initialSize) { (dependencies)  in
                
                RotationDraggable<RotationHandle, SpinnableModel, DragGestureModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: SpinnableModel<RotationHandle>(dependencies: dependencies, model: model, threshold: threshold, handle: handle), translationModel: DragGestureModel(offset: dependencies.projectedValue.offset, dragState: dependencies.projectedValue.dragState))
                
                
            })
        case .throwable(let vModel, let vThreshold):
            return AnyView(self.injectDependencies(initialSize: initialSize) { (dependencies)  in
                
                RotationDraggable<RotationHandle, SpinnableModel, ThrowableModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: SpinnableModel<RotationHandle>(dependencies: dependencies, model: model, threshold: threshold, handle: handle), translationModel: ThrowableModel(dependencies: dependencies, model: vModel, threshold: vThreshold))
            })
        }
        
    }
    
    
    
    func spinnable<RotationHandle: View>(initialSize: CGSize = CGSize(width: 100, height: 100), includesRotationGesture: Bool = true, model: AngularVelocityModel = AngularVelocity(), threshold: CGFloat = 0, @ViewBuilder handle: @escaping (Bool, Bool) -> RotationHandle) -> some View {
        self.injectDependencies(initialSize: initialSize) { (dependencies)  in
            RotationOverlayModifier<RotationHandle, SpinnableModel>(dependencies: dependencies, includesRotationGesture: includesRotationGesture, rotationModel: SpinnableModel(dependencies: dependencies, model: model, threshold: threshold, handle: handle))
        }
    }
}
