//
//  ThrowableSpinnableResizable.swift
//  
//
//  Created by Kieran Brown on 11/15/19.
//

import Foundation
import SwiftUI


/// # Throwable, Spinnable And Resizable
///  Provides the ability to scale, rotate, drag, throw , and spin the view. Throw the rotation handle and watch it go.
///  If the view is  selected an overlay with handles in the four corners of the frame plus the rotation handle above are displayed.
///  The handles in the corners resize the view while the handle above rotates the view about its center.
///
///  - parameter viewSize, a binding to a CGSize value.
///
///  - important:
///     1. Use on views that reside in a container which does not affect layout (*ex*:  `ZStack`).
///     2. This is the final modifier to be applied to the view, applying other gestures or geometric effects will result in unforseen occurences.
///  - bug: When grabbing and dragging next neighbor corner holds, The pependicular axis gets double the input.
///
///  - ToDo: Give the ability to define custom handles for resizing and rotating.
///
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
struct ThrowableSpinnableResizable: ViewModifier {
    
    // MARK: Main View Dragging And Size
    @Binding var viewSize: CGSize
    @State var dragState = VelocityState.inactive
    @ObservedObject var velocityModel: VelocityModel = VelocityModel()
    @State private var isSelected: Bool = false
    enum VelocityState {
        case inactive
        case active(time: Date,
            translation: CGSize,
            location: CGPoint,
            velocity: CGSize)
        
        var time: Date? {
            switch self {
            case .active(let time, _, _, _):
                return time
            default:
                return nil
            }
        }
        
        var translation: CGSize {
            switch self {
            case .active(_, let translation, _ , _):
                return translation
            default:
                return .zero
            }
        }
        
        var velocity: CGSize {
            switch self {
            case .active(_, _, _, let velocity):
                return velocity
            default:
                return .zero
            }
        }
        
        var location: CGPoint {
            switch self {
            case .active(_, _, let location ,_):
                return location
            default:
                return .zero
            }
        }
        
        var isActive: Bool {
            switch self {
            case .active(_, _, _ ,_):
                return true
            default:
                return false
            }
        }
    }

    
    var shadowColor: Color
    var shadowRadius: CGFloat
    
    var throwGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .global)
            .onChanged({ (value) in
                if self.dragState.time == nil {
                    self.velocityModel.reset()
                }
                let v = self.calculateVelocity(state: self.dragState, value: value)
                self.dragState = .active(time: value.time,
                                         translation: value.translation,
                                         location: value.location,
                                         velocity: v)
                
            })
            .onEnded { (value) in
                self.velocityModel.velocity = self.dragState.velocity
                self.velocityModel.offset.width += value.translation.width
                self.velocityModel.offset.height += value.translation.height
                self.dragState = .inactive
                self.velocityModel.start()
                
        }
    }
    
    init(viewSize: Binding<CGSize> ,shadowColor: Color? = .gray, radius: CGFloat? = 5) {
        self._viewSize = viewSize
        self.shadowColor = shadowColor!
        self.shadowRadius = radius!
    }
    
    func calculateVelocity(state: VelocityState, value: DragGesture.Value) -> CGSize {
        if state.time == nil {
            return .zero
        }
        
        let deltaX = value.translation.width-state.translation.width
        let deltaY = value.translation.height-state.translation.height
        let deltaT = CGFloat((state.time?.timeIntervalSince(value.time) ?? 1))
        
        let vX = -vScale*deltaX/deltaT
        let vY = -vScale*deltaY/deltaT
        
        return CGSize(width: vX, height: vY)
    }
    enum DragState {
        case inactive
        case active(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .active(translation: let translation):
                return translation
            default:
                return .zero
            }
        }
        
        
        var isActive: Bool {
            switch self {
            case .active(_):
                return true
            default:
                return false
            }
        }
    }
    
    
    // MARK: Resizing
    var handleSize: CGSize = CGSize(width: 40, height: 40)
    @GestureState private var topLeadState: DragState = .inactive
    @GestureState private var topTrailState: DragState = .inactive
    @GestureState private var bottomLeadState: DragState = .inactive
    @GestureState private var bottomTrailState: DragState = .inactive
    
    private var handle: some View {
        Circle()
            .frame(width: handleSize.width, height: handleSize.height)
            .foregroundColor(.blue)
            .opacity(isSelected ? 1 : 0)
    }
    
    private func getTopLeading(proxy: GeometryProxy) -> some View{
        self.handle
            .position(x: proxy.frame(in: .local).minX + self.topLeadState.translation.width + bottomLeadState.translation.width,
                      y: proxy.frame(in: .local).minY + self.topLeadState.translation.height + topTrailState.translation.height)
            .gesture(
                DragGesture()
                    .updating(self.$topLeadState) { (value, state, _) in
                        state = .active(translation: value.translation)
                }
                .onEnded { (value) in
                    self.velocityModel.offset.width += cos(self.angularVelocity.angle)*value.translation.width/2 - sin(self.angularVelocity.angle)*value.translation.height/2
                    self.velocityModel.offset.height += cos(self.angularVelocity.angle)*value.translation.height/2 + sin(self.angularVelocity.angle)*value.translation.width/2
                    self.viewSize.width -= value.translation.width
                    self.viewSize.height -= value.translation.height
            }).offset(x: -viewSize.width*(magnification-1)/2,
                      y: -viewSize.height*(magnification-1)/2)
    }
    
    private func getBottomLead(proxy: GeometryProxy) -> some View {
        self.handle
            .position(x: proxy.frame(in: .local).minX + self.topLeadState.translation.width + self.bottomLeadState.translation.width,
                      y: proxy.frame(in: .local).maxY + self.bottomTrailState.translation.height + self.bottomLeadState.translation.height )
            .gesture(
                DragGesture()
                    .updating(self.$bottomLeadState) { (value, state, _) in
                        state = .active(translation: value.translation)
                }
                .onEnded { (value) in
                    self.velocityModel.offset.width += cos(self.angularVelocity.angle)*value.translation.width/2 - sin(self.angularVelocity.angle)*value.translation.height/2
                    self.velocityModel.offset.height += cos(self.angularVelocity.angle)*value.translation.height/2 + sin(self.angularVelocity.angle)*value.translation.width/2
                    self.viewSize.width -= value.translation.width
                    self.viewSize.height += value.translation.height
            }).offset(x: -viewSize.width*(magnification-1)/2,
                      y: viewSize.height*(magnification-1)/2)
    }
    
    private func getTopTrail(proxy: GeometryProxy) -> some View {
        self.handle
            .position(x: proxy.frame(in: .local).maxX + self.bottomTrailState.translation.width + self.topTrailState.translation.width,
                      y: proxy.frame(in: .local).minY + self.topLeadState.translation.height + topTrailState.translation.height)
            .gesture(
                DragGesture()
                    .updating(self.$topTrailState) { (value, state, _) in
                        state = .active(translation: value.translation)
                }
                .onEnded { (value) in
                    self.velocityModel.offset.width += cos(self.angularVelocity.angle)*value.translation.width/2 - sin(self.angularVelocity.angle)*value.translation.height/2
                    self.velocityModel.offset.height += cos(self.angularVelocity.angle)*value.translation.height/2 + sin(self.angularVelocity.angle)*value.translation.width/2
                    self.viewSize.width += value.translation.width
                    self.viewSize.height -= value.translation.height
            }).offset(x: viewSize.width*(magnification-1)/2,
                      y: -viewSize.height*(magnification-1)/2)
    }
    
    private func getBottomTrail(proxy: GeometryProxy) -> some View {
        self.handle
            .position(x: proxy.frame(in: .local).maxX + topTrailState.translation.width + bottomTrailState.translation.width ,
                      y: proxy.frame(in: .local).maxY + bottomLeadState.translation.height + bottomTrailState.translation.height )
            .gesture(
                DragGesture()
                    .updating(self.$bottomTrailState) { (value, state, _) in
                        state = .active(translation: value.translation)
                }
                .onEnded { (value) in
                    self.velocityModel.offset.width += cos(self.angularVelocity.angle)*value.translation.width/2 - sin(self.angularVelocity.angle)*value.translation.height/2
                    self.velocityModel.offset.height += cos(self.angularVelocity.angle)*value.translation.height/2 + sin(self.angularVelocity.angle)*value.translation.width/2
                    self.viewSize.width += value.translation.width
                    self.viewSize.height += value.translation.height
            }).offset(x: viewSize.width*(magnification-1)/2,
                      y: viewSize.height*(magnification-1)/2)
        
    }
    
    // Overlay of corner handles which can resize the view when dragged
    private var resizingOverlay: some View {
        GeometryReader { (proxy: GeometryProxy) in
            self.getTopLeading(proxy: proxy)
            
            self.getBottomLead(proxy: proxy)
            
            self.getTopTrail(proxy: proxy)
            
            self.getBottomTrail(proxy: proxy)
            
        }
    }
    
    
    // MARK: Rotation
    
    // distance from the top of the view to the rotation handle
    var radialOffset: CGFloat = 50
    // value used to scale calulated velocities
    let vScale: CGFloat = 0.5
    @ObservedObject var angularVelocity: AngularVelocityModel = AngularVelocityModel()
    @State private var spinState: SpinState = .inactive
    @State private var rotationState: CGFloat = 0
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged({ (value) in
                self.angularVelocity.angularVelocity = 0
                self.rotationState = CGFloat(value.radians)
            })
            .onEnded({ (value) in
                self.angularVelocity.angle += CGFloat(value.radians)
                self.rotationState = 0
            })
    }
    
    /// Modified drag state, has a deltaTheta value to use when the gesture is in progress and an angularVelocity value for on the throws end.
    enum SpinState {
        case inactive
        case active(translation: CGSize, time: Date?, deltaTheta: CGFloat, angularVelocity: CGFloat)
        
        var translation: CGSize {
            switch self {
            case .active(let translation, _, _, _):
                return translation
            default:
                return .zero
            }
        }
        
        var time: Date? {
            switch self {
            case .active(_, let time, _, _):
                return time
            default:
                return nil
            }
        }
        
        var deltaTheta: CGFloat {
            switch self {
            case .active(_, _, let angle, _):
                return angle
            default:
                return .zero
            }
        }
        
        var angularVelocity: CGFloat {
            switch self {
            case .active(_, _, _, let velocity):
                return velocity
            default:
                return .zero
            }
        }
        
        
        var isActive: Bool {
            switch self {
            case .active(_ ,_ , _, _):
                return true
            default:
                return false
            }
        }
    }
    
    // Calculates the radius of the circle that the rotation handle is constrained to.
    private func calculateRadius(proxy: GeometryProxy) -> CGFloat {
        return proxy.size.height/2 + radialOffset
    }
    
    // The Y component of the bottom handles should not affect the offset of the rotation handle
    // The Y component of the top handles are doubled to compensate.
    // All X components contribute half of their value.
    private func calculateRotationalOffset(proxy: GeometryProxy) -> CGSize {
        
        let angles = self.angularVelocity.angle + self.spinState.deltaTheta + self.rotationState
        let dragWidths = topLeadState.translation.width + topTrailState.translation.width + bottomLeadState.translation.width + bottomTrailState.translation.width
        let topHeights = topLeadState.translation.height + topTrailState.translation.height
        
        let rX = sin(angles)*(self.calculateRadius(proxy: proxy) - (1-magnification)*proxy.size.width/2)
        let rY = -cos(angles)*(self.calculateRadius(proxy: proxy) - (1-magnification)*proxy.size.height/2)
        let x =   rX + cos(self.angularVelocity.angle)*dragWidths/2 - sin(self.angularVelocity.angle)*topHeights
        let y =   rY + cos(self.angularVelocity.angle)*topHeights + sin(self.angularVelocity.angle)*dragWidths/2
        
        
        return CGSize(width: x, height: y)
    }
    
    /// Returns the change of angle from the dragging the handle
    private func calculateDeltaTheta(proxy: GeometryProxy, translation: CGSize) -> CGFloat {
          let radius = calculateRadius(proxy: proxy)
          
          let lastX = radius*sin(self.angularVelocity.angle)
          let lastY = -radius*cos(self.angularVelocity.angle)
          
          let newX = lastX + translation.width
          let newY = lastY + translation.height
          
          let newAngle = atan2(newY, newX) + .pi/2
    
          return (newAngle-self.angularVelocity.angle)
          
      }
      
      private func calculateAngularVelocity(proxy: GeometryProxy, value: DragGesture.Value) -> CGFloat {
          
          if self.spinState.time == nil {
              return 0
          }
          
          let deltaA = self.calculateDeltaTheta(proxy: proxy, translation: value.translation)-self.spinState.deltaTheta
          let deltaT = CGFloat((self.spinState.time?.timeIntervalSince(value.time) ?? 1))
          let aV = -vScale*deltaA/deltaT
          
          return aV
      }
      
      private var rotationOverlay: some View {
          GeometryReader { (proxy: GeometryProxy) in
              Circle()
                  .frame(width: self.handleSize.width, height: self.handleSize.height)
                  .offset(self.calculateRotationalOffset(proxy: proxy))
                  .gesture(
                      DragGesture()
                          .onChanged({ (value) in
                              self.angularVelocity.stop()
                              let deltaTheta = self.calculateDeltaTheta(proxy: proxy, translation: value.translation)
                              self.spinState = .active(translation: value.translation,
                                                       time: value.time,
                                                       deltaTheta: deltaTheta,
                                                       angularVelocity: self.calculateAngularVelocity(proxy: proxy, value: value))
                          })
                          .onEnded({ (value) in
                              self.angularVelocity.angle += self.calculateDeltaTheta(proxy: proxy, translation: value.translation)
                              self.angularVelocity.angularVelocity = self.spinState.angularVelocity
                              self.spinState = .inactive
                              self.angularVelocity.start()
                          })
              )
          }
      }
    
    
    // MARK: Magnification
    @State private var magnification: CGFloat = 1
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged({ (value) in
                self.magnification = value
            })
            .onEnded({ (value) in
                self.magnification = 1
                self.viewSize.width *= value
                self.viewSize.height *= value
                
            })
    }
    
    // Not really need just makes the body easier to read
    private func applyScales(view: AnyView) -> some View {
        // basiclly to make the animations for dragging the
        // corners work properly, specific scale effects are applied
        // during the individual holds drag gesture.
        view
            .scaleEffect(magnification)
            // Top Leading
            .scaleEffect(CGSize(width: (viewSize.width - topLeadState.translation.width)/viewSize.width,
                                height: (viewSize.height - topLeadState.translation.height)/viewSize.height),
                         anchor: .bottomTrailing)
            // Bottom Leading
            .scaleEffect(CGSize(width: (viewSize.width - bottomLeadState.translation.width)/viewSize.width,
                                height: (viewSize.height + bottomLeadState.translation.height)/viewSize.height),
                         anchor: .topTrailing)
            // Top Trailing
            .scaleEffect(CGSize(width: (viewSize.width + topTrailState.translation.width)/viewSize.width,
                                height: (viewSize.height - topTrailState.translation.height)/viewSize.height),
                         anchor: .bottomLeading)
            // Bottom Trailing
            .scaleEffect(CGSize(width: (viewSize.width + bottomTrailState.translation.width)/viewSize.width,
                                height: (viewSize.height + bottomTrailState.translation.height)/viewSize.height),
                         anchor: .topLeading)
    }
    
    
    // MARK: Body
    func body(content: Content) -> some View {
        ZStack {
            applyScales(view: AnyView(content
                .frame(width: viewSize.width, height: viewSize.height, alignment: .center)))
                .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(throwGesture)
                .overlay(resizingOverlay)
                .rotationEffect(Angle(radians: Double(self.angularVelocity.angle + spinState.deltaTheta + rotationState)))
                .simultaneousGesture(rotationGesture)
            
        }.overlay(rotationOverlay)
            .onTapGesture {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.isSelected.toggle()
                }
        }
        .offset(x: velocityModel.offset.width + dragState.translation.width ,
                y: velocityModel.offset.height + dragState.translation.height)
    }
    
}
