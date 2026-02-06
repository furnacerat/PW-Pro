import SwiftUI
@preconcurrency import AVFoundation

#if os(iOS)
/// Camera coordinator for real-time camera feed on iOS
@MainActor
class CameraCoordinator: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isAuthorized = false
    @Published var capturedImage: UIImage?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var isSetup = false
    private var isSettingUp = false
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    func setupCamera() {
        guard isAuthorized, !isSetup, !isSettingUp else { return }
        isSettingUp = true
        
        print("DEBUG: Starting Camera Setup detached task")
        Task.detached(priority: .userInitiated) {
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .photo
            
            // Get back camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("DEBUG: Failed to get camera device")
                session.commitConfiguration()
                await MainActor.run { self.isSettingUp = false }
                return
            }
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // Photo output
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            // Create preview layer on main thread since it's UI
            await MainActor.run {
                print("DEBUG: Finalizing camera setup on MainActor")
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.videoGravity = .resizeAspectFill
                
                self.captureSession = session
                self.photoOutput = output
                self.previewLayer = preview
                self.isSetup = true
                self.isSettingUp = false
            }
            
            // Start session
            print("DEBUG: Starting capture session...")
            session.startRunning()
            print("DEBUG: Capture session started.")
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraCoordinator: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        Task { @MainActor in
            self.capturedImage = image
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}
#endif
