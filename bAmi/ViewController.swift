//
//  ViewController.swift
//  bAmi
//
//  Created by 浅野総一郎 on 2021/10/23.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //デバイスからの入力と出力を管理するオブジェクトの作成
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
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            //最初の画像
            imageView.image = UIImage(named: "guidanceGirl")
        }
    }
    
    
    //画像の最後の回転角度
    var lastRotation:CGFloat = 0.0
    //画像の最後の大きさ
    var prevPinch:CGFloat = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func toAlbumButton(_ sender: Any) {
        //アルバムを開く処理を呼び出す
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func changeSlider(_ sender: UISlider) {
        imageView.alpha = CGFloat(sender.value)
    }
    
    //ビューをドラッグする
    @IBAction func drapping(_ sender: UIPanGestureRecognizer) {
        //指の座標を中心に合わせる
        imageView.center = sender.location(in: self.view)
    }
    
    //ビューを回転させる
    @IBAction func rotateImageView(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            //前回の角度から始める
            sender.rotation = lastRotation
        case .changed:
            //回転角度にimageViewを合わせる
            imageView.transform = CGAffineTransform(rotationAngle: sender.rotation)
        case .ended:
            //回転終了時の回転角度を保存する
            lastRotation = sender.rotation
        default:
            break
        }
    }
    
    //ビューを拡大、縮小する
    @IBAction func pinchAction(_ sender: UIPinchGestureRecognizer) {
        let rate = sender.scale - 1 + prevPinch
        //拡大縮小の反映
        imageView.transform = CGAffineTransform(scaleX: rate , y: rate )
        if(sender.state == .ended) {
            //終了時に拡大、縮小率を保存しておき次回に使う
            prevPinch = rate
        }
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
        let alert = UIAlertController(title: "確認",
                                      message: "画像を削除してもいいですか?",
                                      preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction) -> Void in
            
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
        //カメラの手ブレを補正
        settings.isAutoStillImageStabilizationEnabled = true
        //撮影された画像をdelegateメソッドで処理
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
        
        //コンテキスト開始
        UIGraphicsBeginImageContextWithOptions(UIScreen.main.bounds.size, false, 0.0)
        //viewを書き出す
        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        // imageにコンテキストの内容を書き出す
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        //コンテキストを閉じる
        UIGraphicsEndImageContext()
        // imageをカメラロールに保存
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

//MARK: AVCapturePhotoCaptureDelegateデリゲートメソッド
extension ViewController: AVCapturePhotoCaptureDelegate{
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            // Data型をUIImageオブジェクトに変換
            let uiImage = UIImage(data: imageData)
            // 写真ライブラリに画像を保存
            UIImageWriteToSavedPhotosAlbum(uiImage!, nil,nil,nil)
        }
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
        //指定したAVCaptureSessionでプレビューレイヤを初期化
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //プレビューレイヤが、カメラのキャプチャー縦横比を維持した状態で、表示するように設定
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //プレビューレイヤの表示の向きを設定
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        self.cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
}

