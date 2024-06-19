// this is version 0.02. It currently:
// only spins wheel if p is pressed
// gray is lighter gray on buttons
// record is grayed out until p is pressed
// s will stop all record + p that is grayed out
// haptics applied to the wheel and buttons
// TO DO: add files access to the buttons

import UIKit

class ViewController: UIViewController {
    
    var circleView: UIView!
    var squareView: UIView!
    var dotView: UIView!
    var button1: UIButton!
    var button2: UIButton!
    var button3: UIButton!
    
    var rotationAngle: CGFloat = 0.0
    var isRotating = false
    var rotationSpeed: CGFloat = 1.0
    var rotationTimer: Timer?
    
    var isButton1Active = false
    var isButton2Active = false
    var isButton3Active = false
    
    var isButton2Tapped = false
    
    let circleFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy) // Feedback for circle (heavy style)
    let buttonFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy) // Feedback for buttons (heavy style)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
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
        squareView.center = CGPoint(x: circleDiameter / 2, y: circleDiameter / 2)
        squareView.backgroundColor = .white
        squareView.layer.borderWidth = 2.0
        squareView.layer.borderColor = UIColor.black.cgColor
        squareView.layer.cornerRadius = 5.0
        circleView.addSubview(squareView)
        
        let dotSize: CGFloat = squareSize * 0.1
        dotView = UIView(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        dotView.center = CGPoint(x: squareSize / 2, y: squareSize / 2)
        dotView.backgroundColor = .black
        dotView.layer.cornerRadius = dotSize / 2
        squareView.addSubview(dotView)
        
        let buttonWidth = view.bounds.width / 3.0
        let buttonHeight = (view.bounds.height - circleView.frame.maxY - 20.0)
        let buttonY = circleView.frame.maxY + 20.0
        
        button1 = UIButton(frame: CGRect(x: 0, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button1, isActive: isButton1Active)
        button1.setTitle("R", for: .normal)
        button1.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button1)
        
        button2 = UIButton(frame: CGRect(x: buttonWidth, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button2, isActive: isButton2Active)
        button2.setTitle("P", for: .normal)
        button2.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button2)
        
        button3 = UIButton(frame: CGRect(x: buttonWidth * 2, y: buttonY, width: buttonWidth, height: buttonHeight))
        updateButtonAppearance(button: button3, isActive: isButton3Active)
        button3.setTitle("S", for: .normal)
        button3.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        view.addSubview(button3)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        circleView.addGestureRecognizer(panGesture)
        
        // Prepare the haptic feedback generators
        circleFeedbackGenerator.prepare()
        buttonFeedbackGenerator.prepare()
        
        // Add version label
        let versionLabel = UILabel(frame: CGRect(x: view.bounds.width - 120, y: 20, width: 100, height: 30))
        versionLabel.text = "v0.02 (spin logic update to buttons only, record button gray out)"
        versionLabel.textColor = .black
        versionLabel.font = UIFont.systemFont(ofSize: 10)
        versionLabel.textAlignment = .right
        view.addSubview(versionLabel)
    }
    
    func startRotation() {
        if !isRotating {
            isRotating = true
            rotationTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateRotation), userInfo: nil, repeats: true)
        }
    }
    
    func stopRotation() {
        isRotating = false
        rotationTimer?.invalidate()
        rotationTimer = nil
    }
    
    
    @objc func updateRotation() {
        rotationAngle += rotationSpeed
        if rotationAngle >= 360 {
            rotationAngle = 0
        }
        let rotation = CGAffineTransform(rotationAngle: rotationAngle * .pi / 180.0)
        circleView.transform = rotation
    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
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

    @objc func buttonTapped(_ sender: UIButton) {
        switch sender {
        case button1:
            if isButton2Active {
                isButton1Active.toggle()
                updateButtonAppearance(button: button1, isActive: isButton1Active)
                print("Button 1 (Record) tapped!")
                provideButtonHapticFeedback()
                
                // Turn off other buttons
                isButton3Active = false
                updateButtonAppearance(button: button3, isActive: isButton3Active)
            } else {
                // Optionally provide feedback or handle the case where Play is not active
                print("Cannot record without Play active!")
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
                
                // Turn off record button
                isButton1Active = false
                updateButtonAppearance(button: button1, isActive: isButton1Active)
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
            button.setTitleColor(isButton2Active ? .black : UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), for: .normal) // Lighter gray for inactive state
            button.isUserInteractionEnabled = isButton2Active
        }
    }

    
    func provideButtonHapticFeedback() {
        buttonFeedbackGenerator.prepare()
        buttonFeedbackGenerator.impactOccurred()
    }
    
    func provideContinuousCircleHapticFeedback(with velocity: CGPoint) {
        let intensity = abs(velocity.x / 275.0) // Adjust the divisor to control the sensitivity
        circleFeedbackGenerator.impactOccurred(intensity: intensity)
    }
    
    deinit {
        rotationTimer?.invalidate()
    }
}
