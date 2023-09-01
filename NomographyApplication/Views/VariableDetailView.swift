import UIKit


protocol VariableDetailViewDelegate: AnyObject {
    func textFieldDidBeginEditing(textField: UITextField)
    func fixButtonPressed(_ sender: UIButton)
}

class VariableDetailView: UIView, UITextFieldDelegate {

    weak var delegate: VariableDetailViewDelegate?

    var nomographyScale: NomographyScale!
    var nomogram: Nomogram!
    let zoomedView = ZoomedView()


    func buildVariableDetailView() {
        

        // Init & position the variableDetailView
        let variableDetailView = UIView()
        variableDetailView.translatesAutoresizingMaskIntoConstraints = false
        variableDetailView.backgroundColor = .white
        variableDetailView.layer.borderWidth = 1
        variableDetailView.layer.borderColor = UIColor.black.cgColor
        
        addSubview(variableDetailView)
        
        NSLayoutConstraint.activate([
            variableDetailView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            variableDetailView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            variableDetailView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            variableDetailView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3)
        ])
        

        // Init & position the "Fix variable" button
        nomographyScale.fixButton.setTitle((nomographyScale.fixed) ? "Fixed variable" : "Fix variable", for: .normal)
        nomographyScale.fixButton.setTitleColor((nomographyScale.fixed) ? .systemGray : .white, for: .normal)
        nomographyScale.fixButton.backgroundColor = (nomographyScale.fixed) ? .systemGray4 : .systemBlue
        nomographyScale.fixButton.layer.cornerRadius = 5
        nomographyScale.fixButton.isEnabled = !nomographyScale.fixed
        nomographyScale.fixButton.translatesAutoresizingMaskIntoConstraints = false
        nomographyScale.fixButton.addTarget(self, action: #selector(fixButtonPressed(_:)), for: .touchDown)
        
        addSubview(nomographyScale.fixButton)

        NSLayoutConstraint.activate([
            nomographyScale.fixButton.centerXAnchor.constraint(equalTo: variableDetailView.centerXAnchor),
            nomographyScale.fixButton.topAnchor.constraint(equalTo: variableDetailView.topAnchor, constant: 10),
            nomographyScale.fixButton.leadingAnchor.constraint(equalTo: variableDetailView.leadingAnchor, constant: 60),
            nomographyScale.fixButton.trailingAnchor.constraint(equalTo: variableDetailView.trailingAnchor, constant: -60)
        ])


        // Init & position the textField for the variable value
        let valueTextFieldLabel = UILabel()
        valueTextFieldLabel.text = "Value for \(nomographyScale.variableName) :"
        valueTextFieldLabel.textColor = .black
        valueTextFieldLabel.translatesAutoresizingMaskIntoConstraints = false
                
        nomographyScale.valueTextField.placeholder = "Value for \(nomographyScale.variableName)"
        nomographyScale.valueTextField.backgroundColor = .white
        nomographyScale.valueTextField.translatesAutoresizingMaskIntoConstraints = false
        nomographyScale.valueTextField.borderStyle = UITextField.BorderStyle.roundedRect
        nomographyScale.valueTextField.attributedText = NSAttributedString(string: "\(nomographyScale.variableValue)")
        nomographyScale.valueTextField.inputView = UIView() // Needed to prevent the default keyboard from opening
        nomographyScale.valueTextField.keyboardType = UIKeyboardType.decimalPad // Needed to prevent the speech-to-text from opening
        nomographyScale.valueTextField.delegate = self
        
        variableDetailView.addSubview(valueTextFieldLabel)
        variableDetailView.addSubview(nomographyScale.valueTextField)
        
        // Set a maximum width constraint for the textField
        let maxWidthConstraint = NSLayoutConstraint(
            item: nomographyScale.valueTextField,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 120
        )

        // Activate the constraint
        maxWidthConstraint.isActive = true

        NSLayoutConstraint.activate([
            valueTextFieldLabel.leadingAnchor.constraint(equalTo: variableDetailView.leadingAnchor, constant: 10),
            valueTextFieldLabel.topAnchor.constraint(equalTo: nomographyScale.fixButton.bottomAnchor, constant: 17),
            
            nomographyScale.valueTextField.leadingAnchor.constraint(equalTo: valueTextFieldLabel.trailingAnchor, constant: 10),
            nomographyScale.valueTextField.topAnchor.constraint(equalTo: nomographyScale.fixButton.bottomAnchor, constant: 10),
            nomographyScale.valueTextField.trailingAnchor.constraint(equalTo: variableDetailView.trailingAnchor, constant: -10)
        ])


        // Init & position the textFields for the range of the variable
        let rangeLabel = UILabel()
        rangeLabel.text = "Range :"
        rangeLabel.translatesAutoresizingMaskIntoConstraints = false

        let toLabel = UILabel()
        toLabel.text = "to"
        toLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nomographyScale.rangeStartTextField.backgroundColor = .white
        nomographyScale.rangeStartTextField.translatesAutoresizingMaskIntoConstraints = false
        nomographyScale.rangeStartTextField.borderStyle = UITextField.BorderStyle.roundedRect
        nomographyScale.rangeStartTextField.attributedText = NSAttributedString(string: "\(nomographyScale.startValue)")
        nomographyScale.rangeStartTextField.inputView = UIView()
        nomographyScale.rangeStartTextField.keyboardType = UIKeyboardType.decimalPad
        nomographyScale.rangeStartTextField.delegate = self
        
        nomographyScale.rangeEndTextField.backgroundColor = .white
        nomographyScale.rangeEndTextField.translatesAutoresizingMaskIntoConstraints = false
        nomographyScale.rangeEndTextField.borderStyle = UITextField.BorderStyle.roundedRect
        nomographyScale.rangeEndTextField.attributedText = NSAttributedString(string: "\(nomographyScale.endValue)")
        nomographyScale.rangeEndTextField.inputView = UIView()
        nomographyScale.rangeEndTextField.keyboardType = UIKeyboardType.decimalPad
        nomographyScale.rangeEndTextField.delegate = self
        
        variableDetailView.addSubview(rangeLabel)
        variableDetailView.addSubview(toLabel)
        variableDetailView.addSubview(nomographyScale.rangeStartTextField)
        variableDetailView.addSubview(nomographyScale.rangeEndTextField)

        NSLayoutConstraint.activate([
            rangeLabel.leadingAnchor.constraint(equalTo: variableDetailView.leadingAnchor, constant: 10),
            rangeLabel.topAnchor.constraint(equalTo: nomographyScale.valueTextField.bottomAnchor, constant: 17),

            nomographyScale.rangeStartTextField.leadingAnchor.constraint(equalTo: rangeLabel.trailingAnchor, constant: 10),
            nomographyScale.rangeStartTextField.topAnchor.constraint(equalTo: rangeLabel.topAnchor, constant: -7),
            nomographyScale.rangeStartTextField.widthAnchor.constraint(equalToConstant: 70),

            toLabel.leadingAnchor.constraint(equalTo: nomographyScale.rangeStartTextField.trailingAnchor, constant: 5),
            toLabel.topAnchor.constraint(equalTo: rangeLabel.topAnchor),

            nomographyScale.rangeEndTextField.leadingAnchor.constraint(equalTo: toLabel.trailingAnchor, constant: 5),
            nomographyScale.rangeEndTextField.topAnchor.constraint(equalTo: nomographyScale.rangeStartTextField.topAnchor),
            nomographyScale.rangeEndTextField.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        
        // Init & position the zoomed view
        zoomedView.nomographyScale = nomographyScale
        zoomedView.nomogram = nomogram
        zoomedView.translatesAutoresizingMaskIntoConstraints = false
        zoomedView.backgroundColor = .white
        zoomedView.layer.borderWidth = 1
        zoomedView.layer.borderColor = UIColor.black.cgColor
        
        // Pinch & pan recognizers for the zoomed view
        let pinchRecognizer = UIPinchGestureRecognizer(target: zoomedView, action: #selector(zoomedView.handlePinchGesture(_:)))
        zoomedView.addGestureRecognizer(pinchRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: zoomedView, action: #selector(zoomedView.handlePanGesture(_:)))
        zoomedView.addGestureRecognizer(panRecognizer)
        
        addSubview(zoomedView)

        NSLayoutConstraint.activate([
            zoomedView.topAnchor.constraint(equalTo: variableDetailView.bottomAnchor, constant: -1),
            zoomedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            zoomedView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            zoomedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50)
        ])
    }
    
    
    func reloadView() {
        zoomedView.setNeedsDisplay()
    }

    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldDidBeginEditing(textField: textField)
    }


    @objc private func fixButtonPressed(_ sender: UIButton) {
        delegate?.fixButtonPressed(sender)
    }
}

