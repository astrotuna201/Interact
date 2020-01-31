//
//  DragTypes.swift
//  
//
//  Created by Kieran Brown on 11/19/19.
//

import Foundation
import SwiftUI
import Combine




@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol TranslationState {
    
    var time: Date? { get }
    var translation: CGSize { get }
    var velocity: CGSize { get }
    var velocityMagnitude: CGFloat { get }
    
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol DragModel: ObservableObject {
   
    
    var offset: CGSize { get set }
    var gestureState: TranslationState { get set }
    associatedtype Drag: Gesture
    var gesture: Drag { get }
    
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public enum DragType {
    case drag
    case throwable(model: VelocityModel = Velocity(), threshold: CGFloat = 0)
}
