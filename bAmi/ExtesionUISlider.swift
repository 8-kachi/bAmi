//
//  ExtesionUISlider.swift
//  bAmi
//
//  Created by 浅野総一郎 on 2021/11/03.
//

import UIKit

extension UISlider {
    class TappableSlider: UISlider {
        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            return true // touchされた場所がスライダーの位置
        }
    }
}
