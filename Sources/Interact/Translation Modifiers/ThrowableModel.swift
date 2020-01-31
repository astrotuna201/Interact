//
//  ThrowableModel.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine


/// Data model describing the position and velocity of a view that can be dragged and released
/// The `Model` is any type conforming to the `VelocityModel` protocol. Create your own custom `VelocityModel`
/// to add in additional calculations such as gravity, air resistance or some wacky forcefield.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class ThrowableModel: ObservableObject, DragModel {
    
    // MARK: State
    @Binding public var parentFrame: CGRect
    @Binding public var size: CGSize
    @Binding public var gestureState: TranslationState
    @Binding public var offset: CGSize
    var currentOffset: CGSize {
        CGSize(width: offset.width + gestureState.translation.width,
               height: offset.height + gestureState.translation.height)
    }
    
    
    var velocityModel: VelocityModel
    /// Value used to scale the velocity of the drag gesture.
    var vScale: CGFloat = 0.3
    var threshold: CGFloat = 0
    
    
    /// # Throw State
    /// Similar to the example given by apple in the composing gestures article.
    /// Additionally the drags velocity has been included so that upon ending the drag gesture the velocity can be used for animations.
    public enum ThrowState: TranslationState {
        case inactive
        case active(time: Date,
            translation: CGSize,
            velocity: CGSize)
        
        /// `DragGesture`'s translation value
        public var time: Date? {
            switch self {
            case .active(let time, _, _):
                return time
            default:
                return nil
            }
        }
        /// `DragGesture`s time value
        public var translation: CGSize {
            switch self {
            case .active(_, let translation, _):
                return translation
            default:
                return .zero
            }
        }
        /// Velocity calculated from the difference in translations divided by the difference in times from the old state to the current state to the ne
        public var velocity: CGSize {
            switch self {
            case .active(_, _, let velocity):
                return velocity
            default:
                return .zero
            }
        }
        /// The magnitude of the velocity vector, used in comparison with the `threshold` value, if greater then throw object  if less then dont.
        public var velocityMagnitude: CGFloat {
            switch self {
            case .active(_, _, let v):
                return sqrt(v.width*v.width+v.height*v.height)
            default:
                return 0
            }
        }
        
        var isActive: Bool {
            switch self {
            case .active(_, _, _):
                return true
            default:
                return false
            }
        }
    }
    
    
    
    // MARK: Timer
    var timer = Timer()
    var refreshRate: Double = 0.001
    
    // uses the formula c = x + v*t ,
    // where d, x, v, and t are the current offset, offset, velocity, and time respectively.
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: refreshRate , repeats: true) { timer in
            let v = self.velocityModel.getVelocity(offset: self.offset, parentFrame: self.parentFrame, size: self.size, refreshRate: CGFloat(self.refreshRate))
            self.offset.width += v.width*CGFloat(self.refreshRate)
            self.offset.height += v.height*CGFloat(self.refreshRate)
        }
    }
    
    func stop() {
        timer.invalidate()
    }
    
    
    func reset() {
        timer.invalidate()
        velocityModel.velocity = .zero
    }
    
    func setVelocity() {
        velocityModel.velocity = gestureState.velocity
    }
    
    
    
    // MARK: Calculations
    
    /// Calculates the velocity of the drag gesture.
    func calculateDragVelocity(translation: CGSize, time: Date) -> CGSize {
        if gestureState.time == nil {
            return .zero
        }
        
        let deltaX = translation.width-gestureState.translation.width
        let deltaY = translation.height-gestureState.translation.height
        let deltaT = CGFloat(gestureState.time!.timeIntervalSince(time))
        
        if deltaT == 0 {
            return .zero
        }
        
        let vX = -vScale*deltaX/deltaT
        let vY = -vScale*deltaY/deltaT
        
        return CGSize(width: vX, height: vY)
        
    }
    
    
    // MARK: Throw Gesture
    
    #if os(macOS)
        public var gesture: some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { (value) in
                    self.reset()
                    let translation = CGSize(width: value.translation.width, height: -value.translation.height)
                    let velocity = self.calculateDragVelocity(translation: translation, time: value.time)
                    self.gestureState = ThrowState.active(time: value.time,
                                                    translation: translation,
                                                    velocity: velocity)
            }
            .onEnded { (value) in
                
                self.offset.width += value.translation.width
                self.offset.height -= value.translation.height
                if self.gestureState.velocityMagnitude > self.threshold {
                    
                    self.start()
                    self.setVelocity()
                    
                }
                self.gestureState = ThrowState.inactive
            }
        }
    
    #else
    public var gesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { (value) in
                self.reset()
                let velocity = self.calculateDragVelocity(translation: value.translation, time: value.time)
                self.gestureState = ThrowState.active(time: value.time,
                                                translation: value.translation,
                                                velocity: velocity)
        }
        .onEnded { (value) in
            
            self.offset.width += value.translation.width
            self.offset.height += value.translation.height
            if self.gestureState.velocityMagnitude > self.threshold {
                
                self.start()
                self.setVelocity()
                
            }
            self.gestureState = ThrowState.inactive
        }
    }
    
    #endif
    
    
    // MARK: Init
    
    /// Default model is `Velocity`
    public init(dependencies: ObservedObject<GestureDependencies>, model: VelocityModel = Velocity(), threshold: CGFloat = 0) {
        self._parentFrame = dependencies.projectedValue.parentFrame
        self._size = dependencies.projectedValue.size
        self._offset = dependencies.projectedValue.offset
        self._gestureState = dependencies.projectedValue.dragState
        self.velocityModel = model
        self.threshold = threshold
    }
    
    
}
