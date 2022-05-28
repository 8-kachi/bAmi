//
//  SaveViewController.swift
//  bAmi
//
//  Created by 浅野総一郎 on 2021/11/13.
//

import UIKit

class SaveViewController: UIViewController {

    @IBOutlet weak var saveImageView: UIImageView!
    
    var selectedImg:UIImage!
    
    
    @IBOutlet var rotationRecognizer: UIRotationGestureRecognizer!
    
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveImageView.image = selectedImg
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
