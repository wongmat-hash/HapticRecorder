import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, AVAudioRecorderDelegate {

    // MARK: - Properties

    // Views
    var circleView: UIView!
    var squareView: UIView!
    var dotView: UIView!
    
    // Buttons
    var button1: UIButton!
    var button2: UIButton!
    var button3: UIButton!
    
    // Rotation
    var rotationAngle: CGFloat = 0.0
    var isRotating = false
    var rotationSpeed: CGFloat = 1.0
    var rotationTimer: Timer?
    
    // Button States
    var isButton1Active = false
    var isButton2Active = false
    var isButton3Active = false
    
    // Feedback Generators
    let circleFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    let buttonFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // Audio Recorder
    var audioRecorder: AVAudioRecorder?
    var audioURL: URL?
    
    // Timer elements
    var elapsedTimeLabel: UILabel!
    var recordingTimer: Timer?
    var elapsedTime: TimeInterval = 0
    
    // Properties and views
    var audioLevelMeter: DualChannelAudioLevelMeter!
    var levelTimer: Timer?

    var sensitivity: Float = 1.0 // Initial sensitivity value
    
    // Document Picker
    var documentPickerActive = false // Track if document picker is active

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupCircleView()
        setupElapsedTimeLabel()
        setupButtons()
        setupGestures()
        setupVersionLabel()
        setupAudioLevelMeter()
        // Setup audio recorder
        setupAudioRecorder()
    }
    // MARK: - Setup Methods

    private func setupCircleView() {
        // Setup circle view and related views (square and dot)
        // Also sets up rotation and gestures related to the circle view
        // Adjusts UI based on view dimensions
        let circleDiameter = min(view.bounds.width, view.bounds.height) * 0.95
                
                circleView = UIView(frame: CGRect(x: 0, y: 0, width: circleDiameter, height: circleDiameter))
                circleView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY - 150)
                circleView.layer.cornerRadius = circleDiameter / 2
                circleView.clipsToBounds = true
                circleView.backgroundColor = .white
                circleView.layer.borderWidth = 2.0
                circleView.layer.borderColor = UIColor.black.cgColor
                view.addSubview(circleView)
        let squareSize: CGFloat = circleDiameter * 0.1
                squareView = UIView(frame: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
                squareView.center = CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY)
                squareView.backgroundColor = .white
                squareView.layer.borderWidth = 2.0
                squareView.layer.borderColor = UIColor.black.cgColor
                squareView.layer.cornerRadius = 5.0
                circleView.addSubview(squareView)
        let dotSize: CGFloat = squareSize * 0.1
                dotView = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
                dotView.center = CGPoint(x: squareView.bounds.midX, y: squareView.bounds.midY)
                dotView.backgroundColor = .black
                dotView.layer.cornerRadius = dotSize / 2
                squareView.addSubview(dotView)
    }
    
    //MARK: - Button Setup
    private func setupButtons() {
        // Sets up buttons for Record, Play, and Stop functionalities
        // Configures button appearance based on state (active/inactive)
        // Adds tap gesture recognizers for button actions
        let buttonWidth = (view.bounds.width * 0.9) / 3.0 // Equal width for 1x3 buttons
        let buttonHeight = (view.bounds.height - circleView.frame.maxY - 20.0)
        let buttonY = circleView.frame.maxY + 20.0
        // Adjust the shift to the left
        let paddingToEdge: CGFloat = 40.0 // Extra space between last button and edge

        button1 = UIButton(frame: CGRect(x: paddingToEdge, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button1, isActive: isButton1Active)
        button1.setTitle("R", for: .normal)
        button1.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button1)
        
        button2 = UIButton(frame: CGRect(x: button1.frame.maxX, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button2, isActive: isButton2Active)
        button2.setTitle("P", for: .normal)
        button2.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button2)
        
        button3 = UIButton(frame: CGRect(x: button2.frame.maxX, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button3, isActive: isButton3Active)
        button3.setTitle("S", for: .normal)
        button3.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button3)
    }
    // MARK: - Circle Rotation Control
    func startRotation() {
        // Starts rotating the circle view continuously
        if !isRotating {
            isRotating = true
            rotationTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateRotation), userInfo: nil, repeats: true)
        }
    }
            
    func stopRotation() {
        // Stops rotating the circle view
        isRotating = false
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    @objc func updateRotation() {
        // Updates the rotation angle of the circle view
        guard !documentPickerActive else { return } // Prevent rotation when document picker is active
        
        rotationAngle += rotationSpeed
        if rotationAngle >= 360 {
            rotationAngle = 0
        }
        let rotation = CGAffineTransform(rotationAngle: rotationAngle * .pi / 180.0)
        circleView.transform = rotation
    }
    //MARK: - Gesture Setup
    private func setupGestures() {
        // Sets up gestures (pan and double tap) for the circle view
        // Manages gesture interactions and haptic feedback
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        circleView.addGestureRecognizer(panGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        circleView.addGestureRecognizer(doubleTapGesture)
        // Prepare the haptic feedback generators
        circleFeedbackGenerator.prepare()
        buttonFeedbackGenerator.prepare()
    }
    // MARK: - Gesture Recognizers
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // Handles pan gesture on circle view to rotate it
        guard !documentPickerActive else { return } // Prevent handling gestures when document picker is active
                
        switch gesture.state {
        case .began:
            stopRotation()
            provideContinuousCircleHapticFeedback(with: gesture.velocity(in: circleView))
        case .changed:
            let translation = gesture.translation(in: circleView)
            let angleOffset = translation.x / circleView.bounds.width * 360.0
            rotationAngle += angleOffset
            let rotation = CGAffineTransform(rotationAngle: rotationAngle * .pi / 180.0)
            circleView.transform = rotation
            gesture.setTranslation(.zero, in: circleView)
            provideContinuousCircleHapticFeedback(with: gesture.velocity(in: circleView))
        case .ended, .cancelled, .failed:
            if isButton2Active {
                startRotation()
            }
        default:
            break
        }
    }
    // MARK: - VER. Setup
    private func setupVersionLabel() {
        // Add version label
        let versionLabel = UILabel(frame: CGRect(x: view.bounds.width - 120, y: 20, width: 100, height: 30))
        versionLabel.text = "v0.03 [Timecode, Buttons]"
        versionLabel.textColor = .black
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textAlignment = .right
        view.addSubview(versionLabel)
    }
    
    //MARK: - Setup Audio Recorder
    private func setupAudioRecorder() {
        // Configures audio session and recorder settings
        // Handles errors during audio setup
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFileName = "recordedAudio.wav" // Adjust file format as needed
            audioURL = documentsPath.appendingPathComponent(audioFileName)
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL!, settings: audioSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            // Start updating the levels
            startUpdatingLevels()
            audioRecorder?.prepareToRecord()
            
        } catch {
            // Handle audio session or recorder setup error
            print("Error setting up audio session/recorder: \(error.localizedDescription)")
        }
    }
    
    //MARK: - Audio level updater
    private func startUpdatingLevels() {
        levelTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateAudioLevels), userInfo: nil, repeats: true)
    }
        
    @objc private func updateAudioLevels() {
        guard let recorder = audioRecorder else { return }

        recorder.updateMeters()

        // Get the current levels, not the max
        let leftChannelLevel = levelFromPower(power: recorder.averagePower(forChannel: 0))
        let rightChannelLevel = levelFromPower(power: recorder.averagePower(forChannel: 1))

        audioLevelMeter.setLevels(left: leftChannelLevel, right: rightChannelLevel)
    }

    private func levelFromPower(power: Float) -> CGFloat {
        // Typical range is from -80 dB to 0 dB
        let minDb: Float = -80.0
        let maxDb: Float = 0.0
        
        if power < minDb {
            return 0.0
        } else if power >= maxDb {
            return 1.0
        } else {
            return CGFloat((power - minDb) / (maxDb - minDb))
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - Audio Level Meter
    private func setupAudioLevelMeter() {
        // Calculate meter dimensions and position
        let meterWidth: CGFloat = 40
        let paddingFromLeft: CGFloat = 0
        let paddingFromBottom: CGFloat = 0
        let cornerRadius: CGFloat = 5 // Adjust as needed
        
        // Calculate x-position based on button1's frame
        let meterX: CGFloat = button1.frame.minX - meterWidth - paddingFromLeft
        
        // Calculate y-position and height based on screen height and button1's position
        let screenHeight = view.frame.height
        let meterHeight = screenHeight - button1.frame.minY - paddingFromBottom
        
        // Calculate y-position based on button1's top edge
        let meterY: CGFloat = button1.frame.minY
        
        audioLevelMeter = DualChannelAudioLevelMeter(frame: CGRect(x: meterX, y: meterY, width: meterWidth, height: meterHeight))
        audioLevelMeter.layer.cornerRadius = cornerRadius
        audioLevelMeter.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Round top left and top right corners
        audioLevelMeter.clipsToBounds = true // Ensure content does not exceed rounded corners
        view.addSubview(audioLevelMeter)
    }
    
    // MARK: - Dual Channel Audio Level Meter
    class DualChannelAudioLevelMeter: UIView {
        private var leftLevel: CGFloat = 0.0
        private var rightLevel: CGFloat = 0.0

        private let numberOfSegments: Int = 20 // Number of segments for each meter

        func setLevels(left: CGFloat, right: CGFloat) {
            // Ensure levels are within 0 to 1 range
            self.leftLevel = max(0.0, min(1.0, left))
            self.rightLevel = max(0.0, min(1.0, right))
            setNeedsDisplay() // Request a redraw
        }

        override func draw(_ rect: CGRect) {
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.clear(rect)

            let segmentWidth = rect.width / 2
            let segmentHeight = rect.height / CGFloat(numberOfSegments)

            // Draw left channel in shades of yellow
            for i in 0..<numberOfSegments {
                let y = rect.height - CGFloat(i + 1) * segmentHeight
                let colorIntensity = CGFloat(i) / CGFloat(numberOfSegments)
                let color = UIColor(red: 1.0, green: colorIntensity, blue: 0.0, alpha: 1.0) // Yellow shades

                color.setFill()
                if CGFloat(i) / CGFloat(numberOfSegments) < leftLevel {
                    let barRect = CGRect(x: 0, y: y, width: segmentWidth, height: segmentHeight)
                    context.fill(barRect)
                }
            }

            // Draw right channel in shades of green
            for i in 0..<numberOfSegments {
                let y = rect.height - CGFloat(i + 1) * segmentHeight
                let colorIntensity = CGFloat(i) / CGFloat(numberOfSegments)
                let color = UIColor(red: 0.0, green: colorIntensity * 0.5, blue: 0.0, alpha: 1.0) // Green shades

                color.setFill()
                if CGFloat(i) / CGFloat(numberOfSegments) < rightLevel {
                    let barRect = CGRect(x: segmentWidth, y: y, width: segmentWidth, height: segmentHeight)
                    context.fill(barRect)
                }
            }
        }
    }
    // MARK: - Timer Setup
    private func setupElapsedTimeLabel() {
        // Calculate the centerY position above the circle
        let centerY = circleView.frame.minY - 50.0 // Adjust the vertical offset as needed
        
        // Position the label centered horizontally and above the circle
        elapsedTimeLabel = UILabel(frame: CGRect(x: 20, y: centerY, width: view.bounds.width - 40, height: 40))
        elapsedTimeLabel.font = UIFont.systemFont(ofSize: 24)
        elapsedTimeLabel.textColor = .black
        elapsedTimeLabel.textAlignment = .center
        elapsedTimeLabel.text = "00:00:00"
        view.addSubview(elapsedTimeLabel)
    }

    // Update Timer
    func updateElapsedTimeLabel() {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        elapsedTimeLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    func startTimer() {
        if recordingTimer == nil {
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.elapsedTime += 1
                self?.updateElapsedTimeLabel()
            }
        }
    }

    func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    func resetTimer() {
        elapsedTime = 0
        updateElapsedTimeLabel()
    }
    // MARK: - Timer Color Change Methods

    private func setTimecodeColorToRed() {
        elapsedTimeLabel.textColor = .red
    }

    private func setTimecodeColorToBlack() {
        elapsedTimeLabel.textColor = .black
    }
    // MARK: - AVAudioRecorderDelegate
        
        func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
            // Handle successful completion of recording
            if flag {
                print("Recording finished successfully")
            } else {
                print("Recording failed")
            }
        }
        
        func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
            // Handle encoding error
            if let error = error {
                print("Recording error occurred: \(error)")
            }
        }

    // MARK: - Audio Recording Methods

    func startRecording() {
        guard let recorder = audioRecorder else {
            print("Audio recorder not initialized.")
            return
        }

        if !recorder.isRecording {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                recorder.record()
                print("Recording started.")
                startTimer()
                setTimecodeColorToRed() // Change color to red when recording
            } catch {
                print("Error starting recording: \(error.localizedDescription)")
            }
        }
    }

    func pauseRecording() {
        guard let recorder = audioRecorder else {
            print("Audio recorder not initialized.")
            return
        }

        if recorder.isRecording {
            recorder.pause()
            print("Recording paused.")
            stopTimer()
            setTimecodeColorToBlack() // Change color to black when paused
        }
    }

    func resumeRecording() {
        guard let recorder = audioRecorder else {
            print("Audio recorder not initialized.")
            return
        }

        if !recorder.isRecording {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                recorder.record()
                print("Recording resumed.")
                startTimer()
                setTimecodeColorToRed() // Change color to red when recording
            } catch {
                print("Error resuming recording: \(error.localizedDescription)")
            }
        }
    }

    func stopRecording() {
        // Stops audio recording if recorder is initialized and currently recording
        // Updates button states and prompts user to save recorded audio
        guard let recorder = audioRecorder else {
                print("Audio recorder not initialized.")
                return
            }
            
            if recorder.isRecording {
                recorder.stop()
                print("Recording stopped.")
                stopTimer()
                setTimecodeColorToBlack() // Change color to black when paused
                resetTimer()
                // Change button states after stopping recording
                isButton1Active = false
                updateButtonAppearance(button: button1, isActive: isButton1Active)
                
                isButton2Active = false
                updateButtonAppearance(button: button2, isActive: isButton2Active)
                
                isButton3Active = false
                updateButtonAppearance(button: button3, isActive: isButton3Active)
                
                // Prompt user to save recorded audio
                saveAudioToFiles()
                
                do {
                    try AVAudioSession.sharedInstance().setActive(false)
                } catch {
                    print("Error deactivating audio session: \(error.localizedDescription)")
                }
            }
    }

    func saveAudioToFiles() {
        // Presents document picker for exporting recorded audio file
        let documentPicker = UIDocumentPickerViewController(forExporting: [audioURL!])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - Document Picker <<INCOMPLETE>>
    func openFiles() {
        // Presents document picker for opening audio files
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Handles double tap gesture on circle view to open files
        guard gesture.state == .ended, !isRotating else { return }
                
        // Handle double tap to open files
        openFiles()
    }

    
    // MARK: - Button Actions
    @objc func buttonTapped(_ sender: UIButton) {
        // Handles tap events for Record, Play, and Stop buttons
        // Updates button states and performs corresponding actions
        guard !documentPickerActive else { return } // Prevent button actions when document picker is active
                
        switch sender {
        case button1:
            if isButton2Active {
                isButton1Active.toggle()
                updateButtonAppearance(button: button1, isActive: isButton1Active)
                updateRecordButtonColor()
                
                if isButton1Active {
                    if !audioRecorder!.isRecording {
                        resumeRecording()
                    } else {
                        startRecording()
                    }
                } else {
                    pauseRecording()
                }
            }
            
        case button2:
            if !isButton2Active {
                isButton2Active.toggle()
                updateButtonAppearance(button: button2, isActive: isButton2Active)
                updateButtonAppearance(button: button1, isActive: isButton1Active) // Enable record button
                print("Button 2 (Play) tapped!")
                provideButtonHapticFeedback()
                
                // Start rotation when playback starts
                startRotation()
                
                // Turn off stop button if it was active
                if isButton3Active {
                    isButton3Active.toggle()
                    updateButtonAppearance(button: button3, isActive: isButton3Active)
                }
            }
            
        case button3:
            if isButton2Active {
                isButton2Active.toggle()
                updateButtonAppearance(button: button2, isActive: isButton2Active)
                print("Button 3 (Stop) tapped!")
                provideButtonHapticFeedback()
                
                // Stop rotation when stopping playback
                stopRotation()
                
                // Stop recording if it's active
                stopRecording()
            }
            
            // Turn off other buttons
            isButton1Active = false
            updateButtonAppearance(button: button1, isActive: isButton1Active)
            isButton2Active = false
            updateButtonAppearance(button: button2, isActive: isButton2Active)
            
            isButton3Active.toggle()
            updateButtonAppearance(button: button3, isActive: isButton3Active)
            
        default:
            break
        }
    }
    
    func updateButtonAppearance(button: UIButton, isActive: Bool) {
        // Updates the appearance (color, state) of the given button based on its activity
        if isActive {
            button.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) // Lighter gray color
        } else {
            button.backgroundColor = .white
        }
        button.layer.cornerRadius = 5.0
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor.black.cgColor
        button.setTitleColor(.black, for: .normal)
        
        if button == button1 {
            button.setTitleColor(isButton1Active && isButton2Active ? .red : UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), for: .normal)
            button.isUserInteractionEnabled = isButton2Active || isButton3Active
        }
    }
    
    func updateRecordButtonColor() {
        // Updates the color of the Record button based on Play button state
        // Ensures it's grayed out when Play is off, black when Play is on, and red when recording
        button1.setTitleColor(isButton1Active && isButton2Active ? .red : .black, for: .normal)
    }
    
    // MARK: - Haptic Feedback

    func provideButtonHapticFeedback() {
        // Provides haptic feedback for button taps
        buttonFeedbackGenerator.prepare()
        buttonFeedbackGenerator.impactOccurred()
    }
    
    func provideContinuousCircleHapticFeedback(with velocity: CGPoint) {
        // Provides continuous haptic feedback while panning the circle view
        let intensity = abs(velocity.x / 275.0) // Adjust the divisor to control the sensitivity
        circleFeedbackGenerator.impactOccurred(intensity: intensity)
    }
}

// MARK: - Extensions

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Handles document picker delegate method when documents are picked
        if let pickedURL = urls.first {
            print("Picked document: \(pickedURL)")
            // Handle opening the track from pickedURL
            // Example: You might want to load the track from this URL
            
            // Display a message only if a track is opened, not when saving
            if controller.documentPickerMode == .open {
                let alertController = UIAlertController(title: "Track Opened", message: "Track opened successfully from \(pickedURL.lastPathComponent)", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Handles document picker cancellation
        print("Document picker cancelled.")
    }
}

// MARK: - Custom Views

// Custom view for audio meter
class AudioMeterView: UIView {
    
    var level: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var meterHeight: CGFloat = 0.0 // Height of the meter
    
    convenience init(frame: CGRect, meterHeight: CGFloat) {
        self.init(frame: frame)
        self.meterHeight = meterHeight
    }
    
    override func draw(_ rect: CGRect) {
        // Draws audio meter with background and current level
        super.draw(rect)
                    
            let meterPath = UIBezierPath()
            let meterWidth = rect.width
            let meterX = rect.minX
            let meterY = rect.minY
            
            // Draw meter background
            UIColor.lightGray.setFill()
            meterPath.move(to: CGPoint(x: meterX, y: meterY))
            meterPath.addLine(to: CGPoint(x: meterX + meterWidth, y: meterY))
            meterPath.addLine(to: CGPoint(x: meterX + meterWidth, y: meterY + meterHeight))
            meterPath.addLine(to: CGPoint(x: meterX, y: meterY + meterHeight))
            meterPath.close()
            meterPath.fill()
            
            // Draw meter level
            let levelHeight = meterHeight * (1 - level)
            UIColor.green.setFill()
            meterPath.move(to: CGPoint(x: meterX, y: meterY + meterHeight))
            meterPath.addLine(to: CGPoint(x: meterX + meterWidth, y: meterY + meterHeight))
            meterPath.addLine(to: CGPoint(x: meterX + meterWidth, y: meterY + levelHeight))
            meterPath.addLine(to: CGPoint(x: meterX, y: meterY + levelHeight))
            meterPath.close()
            meterPath.fill()
    }
}


