//
//  RotationOverlayModel.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class RotationOverlayModel<Handle: View>: ObservableObject, RotationModel {
    
    
    // MARK: State
    
    @Binding public var size: CGSize
    @Binding public var magnification: CGFloat
    @Binding var topLeadState: CGSize
    @Binding var bottomLeadState: CGSize
    @Binding var topTrailState: CGSize
    @Binding var bottomTrailState: CGSize
    // distance from the top of the view to the rotation handle
    var radialOffset: CGFloat = 50
    @Binding public var angle: CGFloat
    @Binding public var gestureState: RotationOverlayState
    @Binding public var rotation: CGFloat
    @Binding public var isSelected: Bool
    
    var handle: (Bool, Bool) -> Handle
    
   
    
    var radius: CGFloat {
        magnification*size.height/2 + radialOffset
    }
    
    var dragWidths: CGFloat {
        return topLeadState.width + topTrailState.width + bottomLeadState.width + bottomTrailState.width
    }
    
    var dragTopHeights: CGFloat {
        return topLeadState.height + topTrailState.height
    }
    
    // MARK: Calculations 
    
    
    // Calculates the change in angle when the rotational handle is dragging
    public func calculateDeltaTheta(translation: CGSize) -> CGFloat {
        
        let lastX = radius*sin(angle)
        let lastY = -radius*cos(angle)
        
        let newX = lastX + translation.width
        let newY = lastY + translation.height
        let newAngle = atan2(newY, newX) + .pi/2
        
        return (newAngle-angle)
        
    }
    
    // The Y component of the bottom handles should not affect the offset of the rotation handle
    // The Y component of the top handles are doubled to compensate.
    // All X components contribute half of their value.
    var rotationalOffset: CGSize {
           
           let angles = angle + gestureState.deltaTheta + rotation
           
           
           let rX = sin(angles)*radius
           let rY = -cos(angles)*radius
           let x =   rX + cos(angles)*dragWidths/2 - sin(angles)*dragTopHeights
           let y =   rY + cos(angles)*dragTopHeights + sin(angles)*dragWidths/2
           
           
           return CGSize(width: x, height: y)
       }
    
    
    public var overlay: some View {
        ZStack {
            handle(isSelected, gestureState.isActive)
        }
        .offset(rotationalOffset)
        .gesture(
            DragGesture()
                .onChanged({ (value) in
                    
                    let deltaTheta = self.calculateDeltaTheta(translation: value.translation)
                    self.gestureState = RotationState.active(translation: value.translation, deltaTheta: deltaTheta)
                })
                .onEnded({ (value) in
                    self.angle += self.calculateDeltaTheta(translation: value.translation)
                    self.gestureState = RotationState.inactive
                })
        )
    }
    
    
    
    
    
    // MARK: Init
    
    public init(dependencies: ObservedObject<GestureDependencies>, handle: @escaping (Bool, Bool) -> Handle) {
        
        
        self._size = dependencies.projectedValue.size
        self._magnification = dependencies.projectedValue.magnification
        self._topLeadState = dependencies.projectedValue.topLeadingState
        self._bottomLeadState = dependencies.projectedValue.bottomLeadingState
        self._topTrailState = dependencies.projectedValue.topTrailingState
        self._bottomTrailState = dependencies.projectedValue.bottomTrailingState
        self._angle = dependencies.projectedValue.angle
        self._gestureState = dependencies.projectedValue.rotationOverlayState
        self._rotation = dependencies.projectedValue.rotation
        self._isSelected = dependencies.projectedValue.isSelected
        self.handle = handle
    }
    
}


/// Use to model the state of the rotation handles drag gesture.
   /// The movement of the rotation handle is restricted to the radius of the circle given by half the height of the rotated view plus the `radialOffset`
   public enum RotationState: RotationOverlayState {
       case inactive
       case active(translation: CGSize, deltaTheta: CGFloat)
       
       
       public var time: Date? {
           nil
       }
       
       
       /// `DragGesture`'s translation value
       var translation: CGSize {
           switch self {
           case .active(let translation, _):
               return translation
           default:
               return .zero
           }
       }
       /// Value calculated by restricting the translation to a specific radius.
       public var deltaTheta: CGFloat {
           switch self {
           case .active(_, let angle):
               return angle
           default:
               return .zero
           }
       }
       
       public var angularVelocity: CGFloat {
           0
       }
       
       public var isActive: Bool {
           switch self {
           case .active(_ , _):
               return true
           default:
               return false
           }
       }
   }
