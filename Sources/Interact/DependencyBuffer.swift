//
//  DependencyBuffer.swift
//  
//
//  Created by Kieran Brown on 11/18/19.
//

import Foundation
import SwiftUI
//import Combine

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
  
  init(initialSize: CGSize, initialOffset: CGSize = .zero, initialAngle: CGFloat = 0) {
    self.size = initialSize
    self.angle = initialAngle
    self.offset = initialOffset
  }
}



public struct RotBoxPreferenceKey: PreferenceKey {
  public static var defaultValue: RotBoxPreferenceKeyData = RotBoxPreferenceKeyData(id:"none",  angle: .zero, offset: .zero, size: .zero)

    public static  func reduce(value: inout RotBoxPreferenceKeyData, nextValue: () -> RotBoxPreferenceKeyData) {
        value = nextValue()
    }
}

public struct RotBoxPreferenceKeyData: Equatable {
  public let id: String
  public let angle: CGFloat
  public let offset: CGSize
  public let size: CGSize
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct DependencyBuffer<Modifier: ViewModifier>: ViewModifier {
  @ObservedObject var dependencies: GestureDependencies
  public var id: String = "\(Int.random(in: 0...Int.max))"
  var modifier: (ObservedObject<GestureDependencies>) -> Modifier
  
  
  init(id: String, initialSize: CGSize, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) {
    self.id = id
    self.dependencies = GestureDependencies(initialSize: initialSize)
    self.modifier = modifier
  }
  
  init(id: String, initialSize: CGSize, initialOffset: CGSize = .zero, initialAngle: CGFloat = 0, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) {
    self.id = id
    self.dependencies = GestureDependencies(initialSize: initialSize, initialOffset: initialOffset, initialAngle: initialAngle)
    self.modifier = modifier
  }
    
  public func body(content: Content) -> some View {
      GeometryReader { proxy in
          content.onAppear(perform: {
              self.dependencies.parentFrame = proxy.frame(in: .local)
          })
              .frame(width: self.dependencies.size.width, height: self.dependencies.size.height, alignment: .center)
              .modifier(self.modifier(self._dependencies))
              .preference(key: RotBoxPreferenceKey.self, value: RotBoxPreferenceKeyData(id: self.id, angle: self.dependencies.angle, offset: self.dependencies.offset, size: self.dependencies.size))
              
      }
      
  }
}



@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension View {
    
  func injectDependencies<Modifier: ViewModifier>(id: String, initialSize: CGSize, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) -> some View {
    self.modifier(DependencyBuffer(id: id, initialSize: initialSize, modifier: modifier))
  }
  
  func injectDependencies<Modifier: ViewModifier>(id: String, initialSize: CGSize, initialOffset: CGSize, initialAngle: CGFloat, modifier: @escaping (ObservedObject<GestureDependencies>) -> Modifier) -> some View {
    self.modifier(DependencyBuffer(id: id, initialSize: initialSize, initialOffset: initialOffset, initialAngle: initialAngle, modifier: modifier))
      
  }
}





