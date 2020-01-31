//
//  VelocityModels.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine


/// Protocol used in `ThrowableModel` to give more customizability to the forces exerted on the view after it has been thrown
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public protocol VelocityModel {
    func getVelocity(offset: CGSize, parentFrame: CGRect, size: CGSize, refreshRate: CGFloat) -> CGSize
    var velocity: CGSize { get set }
}


/// The simplest `VelocityModel` possible.
/// Just houses the velocity you give it and gives it back when you ask for it
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class Velocity: VelocityModel {
    public var velocity: CGSize = .zero
    public func getVelocity(offset: CGSize, parentFrame: CGRect = .zero, size: CGSize = .zero, refreshRate: CGFloat) -> CGSize {
        return velocity
    }
    
    
    
    public init(velocity: CGSize = .zero) {
        self.velocity = velocity
    }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class AirResistanceModel: VelocityModel {
    
    public var velocity: CGSize = .zero
    var gravity: CGFloat
    var dragCoefficient: CGFloat
    var restitution: CGFloat
    
    
    func checkForCollision(offset: CGSize, parentFrame: CGRect, size: CGSize, velocity: CGSize) ->  CGSize  {
         let leading = parentFrame.width/2 + offset.width - ( size.width/2) < 0
         let trailing = parentFrame.width/2 + offset.width + ( size.width/2) > parentFrame.width
         let top = parentFrame.height/2 + offset.height - ( size.height/2) < 0
         let bottom = parentFrame.height/2 + offset.height + ( size.height/2) > parentFrame.height
         
         if leading {
             
             return  CGSize(width: -self.restitution*velocity.width, height: velocity.height)


         } else if trailing {
            
            return CGSize(width: -self.restitution*velocity.width, height: velocity.height)


         } else if top {
            
            return CGSize(width: velocity.width, height: -self.restitution*velocity.height)


         } else if bottom {
            
            return CGSize(width: velocity.width, height: -self.restitution*velocity.height)

    
         } else {
             
            return velocity
         }
         
     }
    
    
    public func getVelocity(offset: CGSize, parentFrame: CGRect, size: CGSize,  refreshRate: CGFloat) -> CGSize {
        let checkedV = checkForCollision(offset: offset, parentFrame: parentFrame, size: size, velocity: velocity)
        let vMag = sqrt(checkedV.width*checkedV.width + checkedV.height*checkedV.height)
        let airX = -dragCoefficient*vMag*checkedV.width
        let airY = -dragCoefficient*vMag*checkedV.height
        
        
        let aX = airX
        let aY = gravity + airY
        
        
        let newVX = checkedV.width + aX*refreshRate
        let newVY = checkedV.height + aY*refreshRate
        
        
        let aveVX = (checkedV.width + newVX)/2
        let aveVY = (checkedV.height + newVY)/2
        
        velocity = CGSize(width: newVX, height: newVY)
        
        return CGSize(width: aveVX, height: aveVY)
    }
    
    
    public init(velocity: CGSize = .zero, gravity: CGFloat = 500, dragCoefficient: CGFloat = 0.001, restitution: CGFloat = 0.96) {
        self.velocity = velocity
        self.gravity = gravity
        self.dragCoefficient = dragCoefficient
        self.restitution = restitution
    }
    
    
}
