import UIKit


protocol BottomViewDelegate: AnyObject {
    func reloadTopView()
}


class BottomView: UIStackView, VariableDetailViewDelegate {
    
    weak var delegate: BottomViewDelegate?
    
    var nomogram: Nomogram!
    var currentlyFocusedTextField: UITextField?
    var currentlyFocusedTextFieldLastCorrectValue: String?
    var digitKeyboard: DigitKeyboard!
    var variableDetailViews: [VariableDetailView] = []

    
    func buildBottomView() {
        
        self.axis = .horizontal
        self.distribution = .fillEqually
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove old arranged subviews
        for subview in self.arrangedSubviews {
            self.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        // Build variable detail views
        variableDetailViews = []
        
        for nomographyScale in nomogram.nomographyScales {
            let variableDetailView = VariableDetailView()
            variableDetailView.nomographyScale = nomographyScale
            variableDetailView.nomogram = nomogram
            
            variableDetailViews.append(variableDetailView)
        }
        
        // Add the variable detail views to the stack view
        variableDetailViews.forEach { addArrangedSubview($0) }
        variableDetailViews.forEach { $0.delegate = self }
        variableDetailViews.forEach { $0.buildVariableDetailView() }
    }
    
    
    func reloadView() {
        variableDetailViews.forEach { $0.reloadView() }
    }
    
    
    func openKeyboard(keyboard: DigitKeyboard, position: CGPoint) {
        // Animate the keyboard into position
        UIView.animate(withDuration: 0.3) {
            keyboard.frame.origin.x = position.x
            keyboard.frame.origin.y = position.y
        }
    }
    
    
    // This function is called when a text field becomes focused
    func textFieldDidBeginEditing(textField: UITextField) {
        currentlyFocusedTextField = textField
        currentlyFocusedTextFieldLastCorrectValue = textField.text!
        openKeyboard(keyboard: digitKeyboard, position: CGPoint(x: 215, y: 850))
    }
    
    
    func loseFocus() {
        
        // Unfocus the textField
        currentlyFocusedTextField!.resignFirstResponder()
        
        if let textFieldValue = Double(currentlyFocusedTextField!.text!) {
            for nomographyScale in nomogram.nomographyScales {
                if currentlyFocusedTextField == nomographyScale.valueTextField {
                    
                    // Update variable value
                    if !nomogram.updateVariableValue(nomographyScale: nomographyScale, variableValue: textFieldValue) {
                        undoTextField()
                    }
                } else if currentlyFocusedTextField == nomographyScale.rangeStartTextField {
                    
                    // Perform check
                    
                    // Update lower range
                    nomogram.updateRange(nomographyScale: nomographyScale, lowerRange: textFieldValue, upperRange: nil)
                    
                    // Rebuild bottom view
                    buildBottomView()
                } else if currentlyFocusedTextField == nomographyScale.rangeEndTextField {
                    
                    // Perform check
                    
                    // Update lower range
                    nomogram.updateRange(nomographyScale: nomographyScale, lowerRange: nil, upperRange: textFieldValue)
                    
                    // Rebuild bottom view
                    buildBottomView()
                }
            }
        } else {
            // If the value of the textField is incorrect (cannot be cast to Double), put it back to its old value
            undoTextField()
        }
    }
    
    
    func undoTextField() {
        currentlyFocusedTextField!.text = currentlyFocusedTextFieldLastCorrectValue!
    }
    
    
    func addDigit(digit: String) {
        currentlyFocusedTextField!.text! += digit
    }
    
    
    func addNegativeSign() {
        // The negative sign can only be added at the beginning
        if currentlyFocusedTextField!.text! == "" {
            currentlyFocusedTextField!.text! += "-"
        }
    }
    
    
    func addDot() {
        // A dot can only be added if it follows a digit
        if currentlyFocusedTextField!.text! != "" {
            if currentlyFocusedTextField!.text!.last! != "-" {
                // And there can only be one dot
                if !currentlyFocusedTextField!.text!.contains(".") {
                    currentlyFocusedTextField!.text! += "."
                }
            }
        }
    }
    
    func removeCharacter() {
        if !currentlyFocusedTextField!.text!.isEmpty {
            currentlyFocusedTextField!.text!.removeLast()
        }
    }
    
    
    @objc func fixButtonPressed(_ sender: UIButton) {
        for nomographyScale in nomogram.nomographyScales {
            if nomographyScale.fixButton == sender {
                
                // Disable the button
                sender.isEnabled = false
                sender.setTitle("Fixed variable", for: .normal)
                sender.setTitleColor(.systemGray, for: .normal)
                sender.backgroundColor = .systemGray4
                nomographyScale.setFixed(true)
            } else {
                
                // Enable the other buttons
                nomographyScale.fixButton.isEnabled = true
                nomographyScale.fixButton.setTitle("Fix variable", for: .normal)
                nomographyScale.fixButton.setTitleColor(.white, for: .normal)
                nomographyScale.fixButton.backgroundColor = .systemBlue
                nomographyScale.setFixed(false)
            }
        }

        // Reload views
        reloadView()
        delegate?.reloadTopView()
    }
}
