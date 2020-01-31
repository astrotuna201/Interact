//
//  ResizableModifier.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
struct ResizableOverlayScaleEffects<Handle: View>: ViewModifier {
    
    
    // MARK: State
    
    @ObservedObject var model: ResizableOverlayModel<Handle>
    
    
    func calculateScaleWidth(value: CGFloat) -> CGFloat {
        return (model.size.width + value)/model.size.width
    }
    
    func calculateScaleHeight(value: CGFloat) -> CGFloat {
        return (model.size.height + value)/model.size.height
    }
    
    func body(content: Content) -> some View {
        content
        // Top Leading Drag Gesture
            .scaleEffect(CGSize(width: calculateScaleWidth(value: -model.topLeadState.width),
                                height: calculateScaleHeight(value: -model.topLeadState.height)),
                     anchor: .bottomTrailing)
        // Bottom Leading Drag Gesture
            .scaleEffect(CGSize(width: calculateScaleWidth(value: -model.bottomLeadState.width),
                                height: calculateScaleHeight(value: model.bottomLeadState.height)),
                     anchor: .topTrailing)
        // Top Trailing Drag Gesture
            .scaleEffect(CGSize(width: calculateScaleWidth(value: model.topTrailState.width),
                                height: calculateScaleHeight(value: -model.topTrailState.height)),
                     anchor: .bottomLeading)
        // Bottom Trailing Drag Gesture
            .scaleEffect(CGSize(width: calculateScaleWidth(value: model.bottomTrailState.width),
                                height: calculateScaleHeight(value: model.bottomTrailState.height)),
                     anchor: .topLeading)
        
    }
    
    
    
    init(model: ResizableOverlayModel<Handle>) {
        self.model = model
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
extension View {
    func applyResizingScales<Handle: View>(model: ResizableOverlayModel<Handle>) -> some View {
        self.modifier(ResizableOverlayScaleEffects(model: model))
    }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct Resizable<Handle: View>: ViewModifier {
    
    @ObservedObject var resizableModel: ResizableOverlayModel<Handle>
    
    public init(initialSize: CGSize, dependencies: ObservedObject<GestureDependencies>, @ViewBuilder handle: @escaping (_ isSelected: Bool, _ isActive: Bool) -> Handle) {
        
        self.resizableModel = ResizableOverlayModel(initialSize: initialSize,
                                                    dependencies: dependencies,
                                                    handle: handle)
    }
    
    
    public func body(content: Content) -> some View  {
        content
        .applyResizingScales(model: resizableModel)
            .onTapGesture {
            withAnimation(.easeIn(duration: 0.2)) {
                self.resizableModel.isSelected = !self.resizableModel.isSelected
            }
        }
            .overlay(self.resizableModel.overlay)
            .offset(self.resizableModel.offset)
            
        }
}
