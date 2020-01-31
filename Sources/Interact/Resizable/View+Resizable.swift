//
//  View+Resizable.swift
//  
//
//  Created by Kieran Brown on 11/17/19.
//

import Foundation
import SwiftUI
import Combine

/// Here I combined the rotation and resizable modifiers into one. I tried my best since the last version to simplify and reuse code that had been repeated again and again
/// It may not be 100% perfect but I needed to make some compromises in the end about what I was really trying to accomplish. I would love to have the ability to combine modifiers, arbitrarily throught the dot syntax but its just not so easy. I tried implementing preference keys with data for all the different types of modifiers I created, but the overall design wasn't sound. I quickly realized that It was going to be way more work and labor intensive then this project itself.
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct ResizableRotatable<ResizingHandle: View, RotationHandle: View, R: RotationModel, T: DragModel>: ViewModifier {
    
    // MARK: State
    
    @ObservedObject var resizableModel: ResizableOverlayModel<ResizingHandle>
    @ObservedObject var magnificationGestureModel: MagnificationGestureModel
    @ObservedObject var rotationModel: R
    @ObservedObject var rotationGestureModel: RotationGestureModel
    @ObservedObject var dragGestureModel: T

    
    // MARK: Convienence Values
    
    var currentAngle: CGFloat {
        rotationModel.angle + rotationModel.gestureState.deltaTheta + rotationGestureModel.rotationState
    }
    
    
    
    public func body(content: Content) -> some View  {
        
        content
            .frame(width: resizableModel.size.width, height: resizableModel.size.height)
            .onTapGesture {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.resizableModel.isSelected = !self.resizableModel.isSelected
                    }
            }
            .simultaneousGesture(dragGestureModel.gesture)
            .scaleEffect(magnificationGestureModel.magnification)
            .applyResizingScales(model: resizableModel)
            
        .simultaneousGesture(magnificationGestureModel.magnificationGesture)
        .overlay(resizableModel.overlay)
        .rotationEffect(Angle(radians: Double(currentAngle)))
        .simultaneousGesture(rotationGestureModel.rotationGesture)
        .overlay(rotationModel.overlay)
        .offset(x: dragGestureModel.offset.width + dragGestureModel.gestureState.translation.width,
                y: dragGestureModel.offset.height + dragGestureModel.gestureState.translation.height)
    }
    
    
    public init(initialSize: CGSize, dependencies: ObservedObject<GestureDependencies>,
                resizingHandle: @escaping (_ isSelected: Bool, _ isActive: Bool) -> ResizingHandle,
                rotationModel: R,
                translationModel: T) {
        
        self.resizableModel = ResizableOverlayModel(initialSize: initialSize,
                                                    dependencies: dependencies,
                                                    handle: resizingHandle)
        
        self.magnificationGestureModel = MagnificationGestureModel(size: dependencies.projectedValue.size, magnification: dependencies.projectedValue.magnification)
        self.rotationModel = rotationModel
        self.rotationGestureModel = RotationGestureModel(angle: dependencies.projectedValue.angle, rotation: dependencies.projectedValue.rotation)
        self.dragGestureModel = translationModel
        
    }
    
    
}



@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public extension View {
    /// Use this modifier to create a resizing overlay for your view, The handle parameter allows you to create a custom view to be used as the handles in each corner of the resizable view.
    /// The two `Bool`s provided in the closure give access to the isSelected and isActive properties of the modified view and handle respectively.
    ///
    /// **Example** Here a Resizable green rectangle is created whose handles all change from blue to orange when active, and become visible when selected.
    ///
    ///         Rectangle()
    ///                 .foregroundColor(.green)
    ///                 .resizable(initialSize: CGSize(width: 200, height: 350),
    ///                             resizingHandle: { (isSelected, isActive) in
    ///                                     Rectangle()
    ///                                     .foregroundColor(isActive ? .orange : .blue)
    ///                                     .frame(width: 30, height: 30)
    ///                                     .opacity(isSelected ? 1 : 0)
    ///               })
    ///
    ///
    func resizable<Handle: View>(initialSize: CGSize, @ViewBuilder handle: @escaping (_ isSelected: Bool, _ isActive: Bool) -> Handle) -> some View {
        
        self.injectDependencies(initialSize: initialSize) { (dependencies)  in
            Resizable(initialSize: initialSize,
                      dependencies: dependencies,
                      handle: handle)
        }
    }
    
    
    
    /// # Resizable and Rotatable
    ///
    ///     Use this modifier for creating resizable and rotatable views. Similar to the normal
    ///     resizable modifier but with an additional parameter to specify the type of rotation
    ///     (normal or spinnable).
    ///
    ///     The two boolean values in the handle closure give access to the `isSelected`
    ///     and `isActive` values of the modified view and handle respectively.
    ///
    ///
    ///     - parameters:
    ///
    ///     - handle: A view that will be used as the handle of the overlay, the `Bool` values in the closure give access to the `isSelected` and `isActive`properties  of the modified view and handle respectively.
    ///     -  isSelected: `Bool `value that is toggled on or off when the view is tapped.
    ///     -  isActive: `Bool` value that is true while the individual handle view is dragging and false otherwise.
    ///
    ///  - note: @ViewBuilder is used here because each of the handles will be wrapping
    ///          in a container ZStack,this way its one less Grouping to write in the final
    ///          syntax.  
    ///
    ///
    /// **Example**   Here a resizable and  spinnable  rectangle is created. both the resizing and rotation handles become visible when the view is selected,
    ///             The resizing handles change from  blue to orange when dragged while the rotation handle changes from yellow to purple when dragged.
    ///
    ///         Rectangle()
    ///         .foregroundColor(.green)
    ///         .resizable(initialSize: CGSize(width: 200, height: 350),
    ///                    resizingHandle: { (isSelected, isActive) in
    ///                         Rectangle()
    ///                         .foregroundColor(isActive ? .orange : .blue)     // Color changes from blue to orange while handle is being dragged
    ///                         .frame(width: 30, height: 30)
    ///                         .opacity(isSelected ? 1 : 0)                               //  Handle view  becomes visible while the main view is selected
    ///         },
    ///           rotation: .spinnable(handle: { (isSelected, isActive) in
    ///                         Circle()
    ///                         .foregroundColor(isActive ? .purple : .yellow)
    ///                         .frame(width: 30, height: 30)
    ///                         .opacity(isSelected ? 1 : 0)
    ///           }))
    ///
    ///
    func resizable<ResizingHandle: View,
        RotationHandle: View>(initialSize: CGSize ,
                              @ViewBuilder resizingHandle: @escaping (_ isSelected: Bool, _ isActive: Bool) -> ResizingHandle,
                                           rotationType: RotationType<RotationHandle>,
                                           dragType: DragType = .drag) -> some View  {
        switch rotationType {
            
        case .normal(let handle):
            
            switch dragType {
            case .drag:
                return AnyView(
                   self.injectDependencies(initialSize: initialSize,
                                         modifier: { (dependencies)   in
                                           ResizableRotatable<ResizingHandle, RotationHandle, RotationOverlayModel, DragGestureModel>(
                                                   initialSize: initialSize,
                                                   dependencies: dependencies,
                                                   resizingHandle: resizingHandle,
                                                   rotationModel: RotationOverlayModel(dependencies: dependencies,
                                                                                       handle: handle),
                                                   translationModel: DragGestureModel(offset: dependencies.projectedValue.offset, dragState: dependencies.projectedValue.dragState))
                   })
                )
            case .throwable(model: let model, threshold: let threshold):
                return AnyView(
                    self.injectDependencies(initialSize: initialSize,
                                          modifier: { (dependencies)   in
                                            ResizableRotatable<ResizingHandle, RotationHandle, RotationOverlayModel, ThrowableModel>(
                                                    initialSize: initialSize,
                                                    dependencies: dependencies,
                                                    resizingHandle: resizingHandle,
                                                    rotationModel: RotationOverlayModel(dependencies: dependencies,
                                                                                        handle: handle),
                                                    translationModel: ThrowableModel(dependencies: dependencies, model: model, threshold: threshold))
                    })
                )
            }
            
            
        case .spinnable(let model, let threshold, let handle):
            
            switch dragType {
            case .drag:
                return AnyView(
                    self.injectDependencies(initialSize: initialSize, modifier: { (dependencies)  in
                        ResizableRotatable<ResizingHandle,RotationHandle,SpinnableModel, DragGestureModel>(
                            initialSize: initialSize,
                              dependencies: dependencies,
                              resizingHandle: resizingHandle,
                              rotationModel: SpinnableModel<RotationHandle>(dependencies: dependencies,
                                                                            model: model,
                                                                            threshold: threshold,
                                                                            handle: handle),
                              translationModel: DragGestureModel(offset: dependencies.projectedValue.offset, dragState: dependencies.projectedValue.dragState))
                    })
                )
                
            case .throwable( let vModel,  let vThreshold):
                return AnyView(
                    self.injectDependencies(initialSize: initialSize, modifier: { (dependencies)  in
                        ResizableRotatable<ResizingHandle,RotationHandle,SpinnableModel, ThrowableModel>(
                            initialSize: initialSize,
                              dependencies: dependencies,
                              resizingHandle: resizingHandle,
                              rotationModel: SpinnableModel<RotationHandle>(dependencies: dependencies,
                                                                            model: model,
                                                                            threshold: threshold,
                                                                            handle: handle),
                              translationModel: ThrowableModel(dependencies: dependencies, model: vModel, threshold: vThreshold))
                    })
                )
                
            }
            
        }
    }
}
