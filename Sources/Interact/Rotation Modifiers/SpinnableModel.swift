//
//  SpinnableModel.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine

/// Data model describing a view that can be rotated and spun with a handle.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class SpinnableModel<Handle: View>: ObservableObject, RotationModel {
    
    
    // MARK: State
    var model: AngularVelocityModel
    @Binding var size: CGSize
    @Binding var magnification: CGFloat
    @Binding var topLeadState: CGSize
    @Binding var bottomLeadState: CGSize
    @Binding var topTrailState: CGSize
    @Binding var bottomTrailState: CGSize
    /// This is kind of like the angular equivalent of a draggable view's `offset`.
    @Binding public var angle: CGFloat
    @Binding public var rotation: CGFloat
    /// Describes the angular drag state of the rotation handle. 
    @Binding public var gestureState: RotationOverlayState
    @Binding public var isSelected: Bool
    
    /// Value describing the distance from the top of the view to the rotation handle.
    var radialOffset: CGFloat = 50
    /// Value used to scale down the velocity of a drag.
    let vScale: CGFloat = 0.5
    /// minimum angular velocity required to start spinning the view.
    var threshold: CGFloat = 0
    var handle: (Bool, Bool) -> Handle
    
    
    /// #  Spin State
    /// Used to keep track of a drag gesture that is constrained to a circle.
    /// Allows access to variables such as the change in angle `deltaTheta`
    ///  or the `angularVelocity` of a `DragGesture` Constrained to a radius.
    public enum SpinState: RotationOverlayState {
        case inactive
        case active(translation: CGSize, time: Date?, deltaTheta: CGFloat, angularVelocity: CGFloat)
        
        /// `DragGesture`'s translation value
        var translation: CGSize {
            switch self {
            case .active(let translation, _, _, _):
                return translation
            default:
                return .zero
            }
        }
        /// `DragGesture`s time value
        public var time: Date? {
            switch self {
            case .active(_, let time, _, _):
                return time
            default:
                return nil
            }
        }
        /// The change in angle from the last translation to the current translation.
        /// A computed value that requires the drag be constrained to a radius.
        public var deltaTheta: CGFloat {
            switch self {
            case .active(_, _, let angle, _):
                return angle
            default:
                return .zero
            }
        }
        /// Angular velocity is computed from the deltaTheta/deltaTime
        public var angularVelocity: CGFloat {
            switch self {
            case .active(_, _, _, let velocity):
                return velocity
            default:
                return .zero
            }
        }
        
        
        public var isActive: Bool {
            switch self {
            case .active(_ ,_ , _, _):
                return true
            default:
                return false
            }
        }
    }
    
    
    public func setVelocity() {
        model.angularVelocity = gestureState.angularVelocity
    }
    
    var radius: CGFloat {
        return magnification*size.height/2 + radialOffset
    }
    
    var dragWidths: CGFloat {
        return topLeadState.width + topTrailState.width + bottomLeadState.width + bottomTrailState.width
    }
    
    var dragTopHeights: CGFloat {
        return topLeadState.height + topTrailState.height
    }
    
    
    // MARK: Calculations
    
   
    
    // The Y component of the bottom handles should not affect the offset of the rotation handle
    // The Y component of the top handles are doubled to compensate.
    // All X components contribute half of their value.
    public var rotationalOffset: CGSize {
        
        let angles = angle + gestureState.deltaTheta + rotation
        
        let rX = sin(angles)*radius
        let rY = -cos(angles)*radius
        let x =   rX + cos(angles)*dragWidths/2 - sin(angles)*dragTopHeights
        let y =   rY + cos(angles)*dragTopHeights + sin(angles)*dragWidths/2
        
        return CGSize(width: x, height: y)
    }
    
    /// Returns the change of angle from the dragging the handle
    public func calculateDeltaTheta(translation: CGSize) -> CGFloat {
        
        let lastX = radius*sin(angle + rotation)
        let lastY = -radius*cos(angle + rotation)
        
        let newX = lastX + translation.width
        let newY = lastY + translation.height
        
        let newAngle = atan2(newY, newX) + .pi/2
        
        return (newAngle-angle)
        
    }
    
    /// Calculates the angular velocity of the rotational drag
    public func calculateDragAngularVelocity(value: DragGesture.Value) -> CGFloat {
        
        if gestureState.time == nil {
            return 0
        }
        
        let deltaA = self.calculateDeltaTheta(translation: value.translation)-gestureState.deltaTheta
        let deltaT = CGFloat(gestureState.time!.timeIntervalSince(value.time))
        let aV = -vScale*deltaA/deltaT
        
        return aV
    }
    
    // MARK: Timer
    
    var timer = Timer()
    var refreshRate: Double = 0.01
    
    
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: refreshRate , repeats: true) { timer in
            let aV = self.model.getAngularVelocity(angle: self.angle, refreshRate: CGFloat(self.refreshRate))
            self.angle += aV*CGFloat(self.refreshRate)
        }
    }
    
    func stop() {
        timer.invalidate()
    }
    
    func reset() {
        timer.invalidate()
        model.angularVelocity = 0
    }
    
    // MARK: Overlay
    
    public var overlay: some View {
        ZStack {
            handle(isSelected, gestureState.isActive)
        }.offset(rotationalOffset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged({ (value) in
                        self.reset()
                        let deltaTheta = self.calculateDeltaTheta(translation: value.translation)
                        let angularVelocity = self.calculateDragAngularVelocity(value: value)
                        self.gestureState = SpinState.active(translation: value.translation, time: value.time, deltaTheta: deltaTheta, angularVelocity: angularVelocity)
                    })
                    .onEnded({ (value) in
                        
                        self.angle += self.calculateDeltaTheta(translation: value.translation)
                        if abs( self.gestureState.angularVelocity ) > self.threshold {
                            self.start()
                            self.model.angularVelocity = self.gestureState.angularVelocity
                        }
                        self.gestureState = SpinState.inactive
                        
                    })
        )
    }
    
    
    // MARK: Init
    
    public init(dependencies: ObservedObject<GestureDependencies>,
                model: AngularVelocityModel,
                threshold: CGFloat = 0,
                handle: @escaping (_ isSelected: Bool, _ isActive: Bool) -> Handle) {
        
        
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
        self.model = model
        self.handle = handle
        self.threshold = threshold
    }
    
}
