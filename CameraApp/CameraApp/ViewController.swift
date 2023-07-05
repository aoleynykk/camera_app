//
//  ViewController.swift
//  CameraApp
//
//  Created by Олександр Олійник on 04.07.2023.
//


import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    private var filtedString = "CISepiaTone"
    
    var photoOutput: AVCapturePhotoOutput?
    
    let context = CIContext()
    
    private let firstFilterButton: UIButton = {
        let obj = UIButton()
        obj.backgroundColor = .gray
        obj.setTitle("sepia", for: .normal)
        obj.setTitleColor(.black, for: .normal)
        obj.setTitleColor(.blue, for: .selected)
        obj.layer.cornerRadius = 4
        obj.layer.borderWidth = 1
        obj.layer.borderColor = UIColor.black.cgColor
        obj.translatesAutoresizingMaskIntoConstraints = false
        return obj
    }()
    
    private let secondFilterButton: UIButton = {
        let obj = UIButton()
        obj.backgroundColor = .gray
        obj.setTitle("comic", for: .normal)
        obj.setTitleColor(.black, for: .normal)
        obj.setTitleColor(.blue, for: .selected)
        obj.layer.cornerRadius = 4
        obj.layer.borderWidth = 1
        obj.layer.borderColor = UIColor.black.cgColor
        obj.translatesAutoresizingMaskIntoConstraints = false
        return obj
    }()
    
    private let thirdFilterButton: UIButton = {
        let obj = UIButton()
        obj.backgroundColor = .gray
        obj.setTitle("blend", for: .normal)
        obj.setTitleColor(.black, for: .normal)
        obj.setTitleColor(.blue, for: .selected)
        obj.layer.cornerRadius = 4
        obj.layer.borderWidth = 1
        obj.layer.borderColor = UIColor.black.cgColor
        obj.translatesAutoresizingMaskIntoConstraints = false
        return obj
    }()
    
    private lazy var stackView: UIStackView = {
        let obj = UIStackView(arrangedSubviews: [firstFilterButton, secondFilterButton, thirdFilterButton])
        obj.axis = .horizontal
        obj.distribution = .equalCentering
        obj.translatesAutoresizingMaskIntoConstraints = false
        return obj
    }()
    
    private let filteredImage: UIImageView = {
        let obj = UIImageView()
        obj.translatesAutoresizingMaskIntoConstraints = false
        obj.contentMode = .scaleAspectFill
        return obj
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(filteredImage)
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            filteredImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filteredImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            filteredImage.topAnchor.constraint(equalTo: view.topAnchor),
            filteredImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstFilterButton.heightAnchor.constraint(equalToConstant: 30),
            firstFilterButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/3.5),
            
            secondFilterButton.heightAnchor.constraint(equalToConstant: 30),
            secondFilterButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/3.5),
            
            thirdFilterButton.heightAnchor.constraint(equalToConstant: 30),
            thirdFilterButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/3.5)
        ])
        
        firstFilterButton.addTarget(self, action: #selector(didFirstFiltedTapped), for: .touchUpInside)
        secondFilterButton.addTarget(self, action: #selector(didSecondFiltedTapped
                                                            ), for: .touchUpInside)
        thirdFilterButton.addTarget(self, action: #selector(didThirdButtonTapped), for: .touchUpInside)
        
        setupDevice()
        setupInputOutput()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (authorized) in
                DispatchQueue.main.async {
                    if authorized {
                        self.setupInputOutput()
                    } else {
                        self.alertCameraAccessNeeded()
                    }
                }
            })
        }
    }
    
    func alertCameraAccessNeeded() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        
        let alert = UIAlertController(
            title: "Need Camera Access",
            message: "Camera access is required to make full use of this app.",
            preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow Camera", style: .cancel, handler: { (alert) -> Void in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    

    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    @objc func didFirstFiltedTapped(_ sender: UIButton) {
        filtedString = "CISepiaTone"
        sender.isSelected = true
        secondFilterButton.isSelected = false
        thirdFilterButton.isSelected = false
        setupInputOutput()
    }
    
    @objc func didSecondFiltedTapped(_ sender: UIButton) {
        filtedString = "CIComicEffect"
        sender.isSelected = true
        firstFilterButton.isSelected = false
        thirdFilterButton.isSelected = false
        setupInputOutput()
    }
    
    @objc private func didThirdButtonTapped(_ sender: UIButton) {
        filtedString = "CIPhotoEffectNoir"
        sender.isSelected = true
        secondFilterButton.isSelected = false
        firstFilterButton.isSelected = false
        setupInputOutput()
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        let effect = CIFilter(name: filtedString)//"CISepiaTone")//"CIComicEffect")
        effect!.setValue(cameraImage, forKey: kCIInputImageKey)
        
        let cgImage = self.context.createCGImage(effect!.outputImage!, from: cameraImage.extent)!
        
        DispatchQueue.main.async {
            let filteredImage = UIImage(cgImage: cgImage)
            self.filteredImage.image = filteredImage
        }
    }
}
