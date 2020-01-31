//
//  AngularVelocityModels.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine

/// Protocol used to describe the angular velocity of a spinnable view
/// Only has two requirements to ensure compatability with the `SpinnableModel`
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol AngularVelocityModel {
    var angularVelocity: CGFloat { get set }
    func getAngularVelocity(angle: CGFloat, refreshRate: CGFloat) -> CGFloat
}



/// The simplest `AngularVelocityModel`
/// It just houses the velocity.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class AngularVelocity: AngularVelocityModel {
    public var angularVelocity: CGFloat = 0
    public func getAngularVelocity(angle: CGFloat, refreshRate: CGFloat = 0.001) -> CGFloat {
        return angularVelocity
    }
    
    
    public init(angularVelocity: CGFloat = 0) {
        self.angularVelocity = angularVelocity
    }
}


/// # Angular Velocity With Friction
/// Has a friction value that acts reduces the angular velocity each refresh. 
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class FrictionalAngularVelocity: AngularVelocityModel {
    public var angularVelocity: CGFloat = 0
    public var friction: CGFloat = 0.01
    public func getAngularVelocity(angle: CGFloat, refreshRate: CGFloat = 0.001) -> CGFloat {
        let deltaAV = -angularVelocity*friction
        angularVelocity += deltaAV
        return angularVelocity
    }
    
    
    public init(angularVelocity: CGFloat = 0) {
        self.angularVelocity = angularVelocity
    }
}
