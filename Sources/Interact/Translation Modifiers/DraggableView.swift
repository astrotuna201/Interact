//
//  DraggableView.swift
//  
//
//  Created by Kieran Brown on 11/20/19.
//

import Foundation
import SwiftUI
import Combine




@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct DraggableView<Content: View>: View {
    
    var content: (CGSize) -> Content
    
    @State public var offset: CGSize = .zero
    @State public var gestureState: DragState = .inactive
    
    public enum DragState: TranslationState {
        case inactive
        case active(time: Date, translation: CGSize, velocity: CGSize)
        
        public var time: Date? {
            switch self {
            case .active(let time, _, _):
                return time
            default:
                return nil
            }
        }
        
        public var translation: CGSize {
            switch self {
            case .active(_, translation: let t, _):
                return t
            default:
                return .zero
            }
        }
        
        
        public var velocity: CGSize {
            switch self {
            case .active(_ , _, let velocity):
                return velocity
            default:
                return .zero
            }
        }
        
        
        public var velocityMagnitude: CGFloat {
            return velocity.width*velocity.width+velocity.height*velocity.height
        }
    }
    
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
                       let vX = -deltaX/deltaT
                       let vY = -deltaY/deltaT
                       
                       return CGSize(width: vX, height: vY)
        
    }
    
    
    // MARK: Gesture 
    
    #if os(macOS)
        public var gesture: some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { (value) in
                    let translation = CGSize(width: value.translation.width, height: -value.translation.height)
                    let velocity = self.calculateDragVelocity(translation: translation, time: value.time)
                    withAnimation(.linear) {
                        self.gestureState = DragState.active(time: value.time,
                        translation: translation,
                        velocity: velocity)
                    }
            }
            .onEnded { (value) in
                
                withAnimation(.linear) {
                    self.offset.width += value.translation.width
                    self.offset.height -= value.translation.height
                    self.gestureState = DragState.inactive
                }
                
                
            }
        }
    
    #else
    public var gesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { (value) in
                let velocity = self.calculateDragVelocity(translation: value.translation, time: value.time)
                self.gestureState = DragState.active(time: value.time,
                                                translation: value.translation,
                                                velocity: velocity)
        }
        .onEnded { (value) in
            
            self.offset.width += value.translation.width
            self.offset.height += value.translation.height
            
            self.gestureState = DragState.inactive
        }
    }
    
    #endif
    
    public init(content: @escaping (CGSize) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(gestureState.velocity)
        .gesture(gesture)
        .offset(x: offset.width + gestureState.translation.width,
                y: offset.height + gestureState.translation.height)
    }
    
}
