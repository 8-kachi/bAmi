//
//  ViewController.swift
//  bAmi
//
//  Created by 浅野総一郎 on 2021/10/23.
//

import UIKit
import AVFoundation

extension UISlider {
    class changeSlider: UISlider {
        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            return true // touchされた場所がスライダーの位置
        }
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    /// AVキャプチャーセッションを生成
    var captureSession = AVCaptureSession()
    //カメラデバイスそのものを管理するオブジェクトの作成
    //メインカメラの管理オブジェクトの作成
    var mainCamera: AVCaptureDevice?
    //インカメの管理オブジェクトの作成
    var innerCamera: AVCaptureDevice?
    //現在しようしているカメラデバイスの管理オブジェクトの作成
    var currentDevice: AVCaptureDevice?
    //キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput : AVCapturePhotoOutput?
    //プレビュー表示用のレイヤ
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    
    
    
    @IBOutlet weak var toAlbumButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var saveCameraViewButton: UIButton!
    @IBOutlet weak var backGroundCancelButton: UIButton!
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            //最初の画像
            imageView.image = UIImage(named: "guidanceGirl")
        }
    }
    @IBOutlet weak var changeSlider: UISlider!
    
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet var rotationRecognizer: UIRotationGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    //ドラッグ終了時のアフィン変換
    var prevEndPinch:CGAffineTransform = CGAffineTransform()
    var prevEndRotate:CGAffineTransform = CGAffineTransform()
    
    //ドラッグ中の前回アフィン変換
    var prevPinch:CGAffineTransform = CGAffineTransform()
    var prevRotate:CGAffineTransform = CGAffineTransform()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        // Do any additional setup after loading the view.
        
        //panViewをパンジェスチャー（ドラッグ）で動かせるように
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(panAction(_:)))
        imageView.addGestureRecognizer(panGesture)
        //デリゲート先に自分を設定する。
        rotationRecognizer.delegate = self
        pinchRecognizer.delegate = self
        //アフィン変換の初期値を設定する。
        prevEndPinch = imageView.transform
        prevEndRotate = imageView.transform
        prevPinch = imageView.transform
        prevRotate = imageView.transform
        
        saveCameraViewButton.isEnabled = false
        backGroundCancelButton.isEnabled = false
        saveCameraViewButton.isHidden = true
        backGroundCancelButton.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /// アルバムを開きます。
    /// - Parameter sender: Any
    @IBAction func toAlbumButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
        
        if cameraView.image == nil {
            
        }
    }
    
    
    /// スライダーのイベントに反応して透明度を変更します。
    /// - Parameters:
    ///   - sender: Any
    ///   - event: UIEvent
    @IBAction func changeSlider(_ sender: UISlider, forEvent event: UIEvent) {
        imageView.alpha = CGFloat(sender.value)
    }
    
    
    /// 撮影に戻るかどうかのアラートを表示します。
    func showbackGroundcancelAlert()  {
        let alert = UIAlertController(
            title: "撮影した背景画像を削除します",
            message: "撮影に戻ってもよいでしょうか",
            preferredStyle: .alert
        )
        let okButton = UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction) -> Void in
            //撮影した画像を削除
            self.cameraView.image = nil
            
            self.toAlbumButton.isEnabled = true
            self.trashButton.isEnabled = true
            self.cameraButton.isEnabled = true
            self.saveCameraViewButton.isEnabled = false
            self.backGroundCancelButton.isEnabled = false
            self.toAlbumButton.isHidden = false
            self.trashButton.isHidden = false
            self.cameraButton.isHidden = false
            self.saveCameraViewButton.isHidden = true
            self.backGroundCancelButton.isHidden = true
            
        })
        let cancelButton = UIAlertAction(
            title: "キャンセル",
            style: .cancel,
            handler: nil
        )
        
        // アラートにボタン追加
        alert.addAction(okButton)
        alert.addAction(cancelButton)
        
        // アラートの表示
        present(alert, animated: true, completion: nil)
    }

    
    /// 撮影に戻るかどうかのアラートを表示させます。
    /// - Parameter sender: Any
    @IBAction func backGroundCansel(_ sender: Any) {
        showbackGroundcancelAlert()
    }
    
    /// 画像を保存するかどうかのアラートを表示します。
    func showSaveAlert() {
        let alert = UIAlertController(
            title: "画像を保存します",
            message: "この位置で保存してもよいでしょうか",
            preferredStyle: .alert
        )
        let okButton = UIAlertAction(
            title: "OK",
            style: .default,
            handler: { [self](action: UIAlertAction) -> Void in
                if self.cameraView.image != nil {
                
                    toAlbumButton.isHidden = true
                    trashButton.isHidden = true
                    cameraButton.isHidden = true
                    saveCameraViewButton.isHidden = true
                    backGroundCancelButton.isHidden = true
                    changeSlider.isHidden = true
                    
                    UIGraphicsBeginImageContextWithOptions(
                        CGSize(
                            width: cameraView.frame.width,
                            height: cameraView.frame.height
                        ),
                        false,
                        0
                    )
                self.view.drawHierarchy(
                    in: CGRect(
                        x: -cameraView.frame.origin.x,
                        y: -cameraView.frame.origin.y,
                        width: view.bounds.size.width,
                        height: view.bounds.size.height
                    ),
                    afterScreenUpdates: true
                )
                
                let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                //コンテキストを閉じる
                UIGraphicsEndImageContext()
                // imageをカメラロールに保存
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                

                saveCameraViewButton.isHidden = false
                backGroundCancelButton.isHidden = false
                changeSlider.isHidden = false
            }
        })
        let cancelButton = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        // アラートにボタン追加
        alert.addAction(okButton)
        alert.addAction(cancelButton)
        
        // アラートの表示
        present(alert, animated: true, completion: nil)
    }
    
    
    /// 画像を保存するかどうかのアラートを呼び出します。
    /// - Parameter sender: Any
    @IBAction func saveCameraView(_ sender: Any) {
        showSaveAlert()
    }
    
    /// オーバーレイ画像をドラッグできるようにします。
    /// - Parameter sender: UIPanGestureRecognizer
    @IBAction func panAction(_ sender: UIPanGestureRecognizer) {
        // Viewをドラッグした量だけ動かす
        let point: CGPoint = sender.translation(in: self.imageView )
        let movedPoint = CGPoint(x:self.imageView.center.x + point.x, y:self.imageView.center.y + point.y)
        self.imageView.center = movedPoint
        
        // ドラッグで移動した距離をリセット
        sender.setTranslation(CGPoint.zero, in: self.imageView)
    }
    
    //ビューを回転させる
    @IBAction func rotateImageView(_ sender: UIRotationGestureRecognizer) {
        //前回ドラッグ終了時の回転を引き継いだアフィン変換を行う。
        let nowRotate = prevEndRotate.rotated(by: sender.rotation)
        
        //拡大縮小と回転のアフィン変換を合わせたものをラベルに登録する。
        imageView.transform = prevPinch.concatenating(nowRotate)
        
        //今回の回転のアフィン変換をクラス変数に保存する。
        prevRotate = nowRotate
        
        if(sender.state == UIGestureRecognizer.State.ended) {
            //ドラッグ終了時の回転のアフィン変換をクラス変数に保存する。
            prevEndRotate = nowRotate
        }
    }
    
    //ビューを拡大、縮小する
    @IBAction func pinchAction(_ sender: UIPinchGestureRecognizer) {
        //前回ドラッグ終了時の拡大縮小を引き継いだアフィン変換を行う。
        let nowPinch = prevEndPinch.scaledBy(x: sender.scale, y: sender.scale)
        
        //拡大縮小と回転のアフィン変換を合わせたものをラベルに登録する。
        imageView.transform = prevRotate.concatenating(nowPinch)
        
        //今回の拡大縮小のアフィン変換をクラス変数に保存する。
        prevPinch = nowPinch
        
        if(sender.state == UIGestureRecognizer.State.ended) {
            //ドラッグ終了時の拡大終了のアフィン変換をクラス変数に保存する。
            prevEndPinch = nowPinch
        }
    }
    
    //リコグナイザーの同時検知を許可するメソッド
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //画像が選択された時に呼ばれる
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            //imageViewにカメラロールから選んだ画像を表示する
            imageView.image = selectedImage
        }
        //画像をImageViewに表示したらアルバムを閉じる
        self.dismiss(animated: true)
    }
    
    //画像選択がキャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //ゴミ箱ボタンが押された時のアクション
    @IBAction func trashButton_TouchUpInside(_ sender: Any) {
        // アラート表示
        showAlert()
    }
    
    // オーバーレイした画像を初期画像に戻す時に呼ばれる関数
    func showAlert() {
        let alert = UIAlertController(
            title: "重ねている画像を削除します",
            message: "画像を基本状態に戻してもよいでしょうか",
            preferredStyle: .alert
        )
        let okButton = UIAlertAction(
            title: "OK",
            style: .default,
            handler: {(action: UIAlertAction) -> Void in
                //最初の画像
                self.imageView.image = UIImage(named: "guidanceGirl")
        })
        
        let cancelButton = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        // アラートにボタン追加
        alert.addAction(okButton)
        alert.addAction(cancelButton)
        
        // アラートの表示
        present(alert, animated: true, completion: nil)
    }
    
    //シャッターボタンが押された時のアクション
    @IBAction func cameraButton_TouchUpInside(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        //フラッシュの設定
        settings.flashMode = .auto
        //撮影された画像をdelegateメソッドで処理
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        
        toAlbumButton.isEnabled = false
        trashButton.isEnabled = false
        cameraButton.isEnabled = false
        saveCameraViewButton.isEnabled = true
        backGroundCancelButton.isEnabled = true
        toAlbumButton.isHidden = true
        trashButton.isHidden = true
        cameraButton.isHidden = true
        saveCameraViewButton.isHidden = false
        backGroundCancelButton.isHidden = false
    }
}

//MARK: AVCapturePhotoCaptureDelegateデリゲートメソッド
extension ViewController: AVCapturePhotoCaptureDelegate{
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.cameraView.image = UIImage(data: photo.fileDataRepresentation()!)
    }
}

//MARK:カメラ設定メソッド
extension ViewController{
    // カメラの画質の設定
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    //デバイスの設定
    func setupDevice() {
        //カメラデバイスのプロパティ設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        //プロパティの条件を満たしたカメラデバイスの取得
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                mainCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                innerCamera = device
            }
        }
        //起動時のカメラを設定
        currentDevice = mainCamera
    }
    
    //入出力データの設定
    func setupInputOutput() {
        do {
            //指定したデバイスを使用するために入力を初期化
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            //指定した入力をセッションに追加
            captureSession.addInput(captureDeviceInput)
            //出力データを受け取るオブジェクトの作成
            photoOutput = AVCapturePhotoOutput()
            //出力データのフォーマットを指定
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }

    //カメラのプレビューを表示するレイヤの設定
    func setupPreviewLayer() {
        // 指定したAVCaptureSessionでプレビューレイヤを初期化
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // プレビューレイヤの表示の向きを設定
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait

        self.cameraPreviewLayer?.frame = self.view.frame

        // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
//        self.cameraPreviewLayer?.videoGravity = .resize
        
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
}
