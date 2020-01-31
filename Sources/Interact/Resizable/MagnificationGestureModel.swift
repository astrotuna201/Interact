//
//  MagnificationGestureModel.swift
//  
//
//  Created by Kieran Brown on 11/20/19.
//

import Foundation
import SwiftUI
import Combine

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
class MagnificationGestureModel: ObservableObject {
    
    // MARK: Magnification Gesture
    
    @Binding var magnification: CGFloat
    @Binding var size: CGSize
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged({ (value) in
                self.magnification = value
            })
            .onEnded { (value) in
                self.size.width *= value
                self.size.height *= value
                self.magnification = 1
        }
        
    }
    
    
    // MARK: Init
    init(size: Binding<CGSize>, magnification: Binding<CGFloat>) {
        self._size = size
        self._magnification = magnification
    }
}
