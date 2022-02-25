//
//  Draggable.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct Draggable<T: DragModel>: ViewModifier {
    @ObservedObject public var model: T
    
    
    public func body(content: Content) -> some View {
            content
            .gesture(model.gesture)
            .offset(x: model.offset.width + model.gestureState.translation.width,
                    y: model.offset.height + model.gestureState.translation.height)
    }
    
    public init(model: T) {
        self.model = model
    }
}



@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension View {
    
  func draggable(id: String, initialSize: CGSize = CGSize(width: 150, height: 250)) -> some View {
    self.injectDependencies(id: id, initialSize: initialSize) { (dependencies) in
            Draggable<DragGestureModel>(model: DragGestureModel(offset: dependencies.projectedValue.offset, dragState: dependencies.projectedValue.dragState))
        }
    }
    
  func throwable(id: String, initialSize: CGSize = CGSize(width: 150, height: 250), model: VelocityModel = Velocity(), threshold: CGFloat = 0) -> some View {
    self.injectDependencies(id:id, initialSize: initialSize) { (dependencies) in
            Draggable<ThrowableModel>(model: ThrowableModel(dependencies: dependencies, model: model, threshold: threshold))
        }
    }
}
