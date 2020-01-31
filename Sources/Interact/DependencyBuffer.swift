//
//  DependencyBuffer.swift
//  
//
//  Created by Kieran Brown on 11/18/19.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public class GestureDependencies: ObservableObject {
    @Published public var parentFrame: CGRect = .zero
    @Published public var offset: CGSize = .zero
    @Published public var dragState: TranslationState = DragGestureModel.DragState.inactive
    @Published public var size: CGSize
    @Published public var magnification: CGFloat = 1
    @Published public var topLeadingState: CGSize = .zero
    @Published public var bottomLeadingState: CGSize = .zero
    @Published public var topTrailingState: CGSize = .zero
    @Published public var bottomTrailingState: CGSize = .zero
    @Published public var angle: CGFloat = 0
    @Published public var rotationOverlayState: RotationOverlayState = RotationState.inactive
    @Published public var rotation: CGFloat = 0
    @Published public var isSelected: Bool = false
    
    
    init(initialSize: CGSize) {
        self.size = initialSize
    }
}




@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct DependencyBuffer<Modifier: ViewModifier>: ViewModifier {
    @ObservedObject var dependencies: GestureDependencies
    
    var modifier: (ObservedObject<GestureDependencies>) -> Modifier
    
    
    init(initialSize: CGSize, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) {
        self.dependencies = GestureDependencies(initialSize: initialSize)
        self.modifier = modifier
    }
    
    
    public func body(content: Content) -> some View {
        GeometryReader { proxy in
            content.onAppear(perform: {
                self.dependencies.parentFrame = proxy.frame(in: .local)
            })
                .frame(width: self.dependencies.size.width, height: self.dependencies.size.height, alignment: .center)
                .modifier(self.modifier(self._dependencies))
        }
        
    }
}



@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension View {
    
    func injectDependencies<Modifier: ViewModifier>(initialSize: CGSize, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) -> some View {
        self.modifier(DependencyBuffer(initialSize: initialSize, modifier: modifier))
    }
    
    
}





