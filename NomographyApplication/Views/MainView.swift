import UIKit


class MainView: UIView, NomogramDelegate, TopViewDelegate, BottomViewDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    let equationLabel = UILabel()
    let topView = TopView()
    let resetButton = UIButton()
    let bottomView = BottomView()
    let blackView = UIView()
    let menuView = MenuView()
    
    let nomograms: [Int: Nomogram] = [
        0 : Nomogram(
            type: "premade",
            name: "Simple nomogram for addition",
            operationType: OperationType.Addition,
            input1Initializer: (name: "A", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 0, endValue: 5)),
            input2Initializer: (name: "B", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 0, endValue: 10)),
            outputInitializer: (name: "C", unit: nil, factor: 1, exponent: 1, range: nil),
            constant: 0
        ),
        1 : Nomogram(
            type: "premade",
            name: "Simple nomogram for muliplication",
            operationType: OperationType.Multiplication,
            input1Initializer: (name: "A", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 2, endValue: 10)),
            input2Initializer: (name: "B", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 5, endValue: 15)),
            outputInitializer: (name: "C", unit: nil, factor: 1, exponent: 1, range: nil),
            constant: 1
        ),
        2 : Nomogram(
            type: "premade",
            name: "Equation of the second degree",
            operationType: OperationType.SecondDegree,
            input1Initializer: (name: "C", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 0, endValue: -10)),
            input2Initializer: (name: "B", unit: nil, factor: 1, exponent: 1, range: Range(startValue: 0, endValue: 10)),
            outputInitializer: (name: "X", unit: nil, factor: 1, exponent: 1, range: nil),
            constant: 0
        ),
        3 : Nomogram(
            type: "custom",
            name: "Inductive reactance",
            operationType: OperationType.Multiplication,
            input1Initializer: (name: "f", unit: "Hz", factor: 1, exponent: 1, range: Range(startValue: 2, endValue: 10)),
            input2Initializer: (name: "L", unit: "H", factor: 1, exponent: 1, range: Range(startValue: 5, endValue: 15)),
            outputInitializer: (name: "X", unit: "Ω", factor: 1, exponent: 1, range: nil),
            constant: 2 * Double.pi
        ),
        4 : Nomogram(
            type: "custom",
            name: "Body Mass Index (BMI)",
            operationType: OperationType.Multiplication,
            input1Initializer: (name: "Mass", unit: "Kg", factor: 1, exponent: 1, range: Range(startValue: 20, endValue: 150)),
            input2Initializer: (name: "Height", unit: "m", factor: 1, exponent: -2, range: Range(startValue: 1, endValue: 2)),
            outputInitializer: (name: "BMI", unit: nil, factor: 1, exponent: 1, range: nil),
            constant: 1
        )
    ]
    

    var selectedNomogramId = 0
    

    func initView() {
        
        // Init & position the equation label
        equationLabel.textColor = .black
        equationLabel.font = UIFont.systemFont(ofSize: 30)
        equationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(equationLabel)
        
        NSLayoutConstraint.activate([
            equationLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            equationLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        
        
        // Init & position the top View
        topView.backgroundColor = .white
        topView.translatesAutoresizingMaskIntoConstraints = false
        
        // Gesture recognizers
        let pinchRecognizer = UIPinchGestureRecognizer(target: topView, action: #selector(topView.handlePinchGesture(_:)))
        topView.addGestureRecognizer(pinchRecognizer)

        let panRecognizer = UIPanGestureRecognizer(target: topView, action: #selector(topView.handlePanGesture(_:)))
        topView.addGestureRecognizer(panRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: topView, action: #selector(topView.handleLongPressGesture(_:)))
        topView.addGestureRecognizer(longPressRecognizer)
        topView.delegate = self
        
        addSubview(topView)
        
        NSLayoutConstraint.activate([
            topView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            topView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            topView.topAnchor.constraint(equalTo: equationLabel.bottomAnchor, constant: 10),
            topView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
        ])
        topView.layoutIfNeeded()
        
        
        // Init & position the button to reset the top View
        resetButton.setTitle("Reset", for: .normal)
        resetButton.backgroundColor = .systemBlue
        resetButton.alpha = 0 // The reset button is hidden by default
        resetButton.layer.cornerRadius = 5
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetButtonPressed(_:)), for: .touchDown)
        
        addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            resetButton.trailingAnchor.constraint(equalTo: topView.trailingAnchor, constant: -10),
            resetButton.topAnchor.constraint(equalTo: topView.topAnchor, constant: 10),
            resetButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        
        // Init & position the bottom View
        let numberKeyboard = DigitKeyboard()
        numberKeyboard.bottomView = bottomView
        
        bottomView.backgroundColor = .white
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.digitKeyboard = numberKeyboard
        bottomView.delegate = self
        
        addSubview(bottomView)
        addSubview(numberKeyboard)
        
        NSLayoutConstraint.activate([
            bottomView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            bottomView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        
        // Init the black View (used to display a shadow when the menu is open)
        blackView.backgroundColor = UIColor.black
        blackView.frame = frame // The black View covers all the screen
        blackView.alpha = 0 // Initially, the black View is transparent
        
        // Tap recognizer used to close the menu when the black View is tapped
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBlackViewTap(_:)))
        blackView.addGestureRecognizer(tapRecognizer)
        addSubview(blackView)
        
        
        // Init & build the open menu icon
        let openMenuButton = UIButton()
        let openMenuButtonIcon = UIImageView(image: UIImage(systemName: "sidebar.left"))
        openMenuButtonIcon.contentMode = .scaleAspectFit
        openMenuButtonIcon.translatesAutoresizingMaskIntoConstraints = false
        openMenuButton.addSubview(openMenuButtonIcon)
        openMenuButton.translatesAutoresizingMaskIntoConstraints = false
        openMenuButton.addTarget(self, action: #selector(openMenuButtonTapped(_:)), for: .touchUpInside)
        addSubview(openMenuButton)
        
        NSLayoutConstraint.activate([
            openMenuButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            openMenuButton.widthAnchor.constraint(equalToConstant: 50),
            openMenuButton.heightAnchor.constraint(equalToConstant: 50),
            openMenuButton.centerYAnchor.constraint(equalTo: equationLabel.centerYAnchor),
            
            openMenuButtonIcon.centerXAnchor.constraint(equalTo: openMenuButton.centerXAnchor),
            openMenuButtonIcon.centerYAnchor.constraint(equalTo: openMenuButton.centerYAnchor),
            openMenuButtonIcon.widthAnchor.constraint(equalTo: openMenuButton.widthAnchor, multiplier: 0.8),
            openMenuButtonIcon.heightAnchor.constraint(equalTo: openMenuButton.heightAnchor, multiplier: 0.8)
        ])
        
    
        // Init & position the menu View
        for nomogram in nomograms.sorted(by: { $0.key < $1.key }) {
            let id = nomogram.key
            if nomogram.value.type == "premade" {
                menuView.premadeNomograms.append((id, nomogram.value.name))
            } else {
                menuView.customNomograms.append((id, nomogram.value.name))
            }
        }
        
        menuView.didSelectRow = { [weak self] selectedKey in
            self?.handleMenuSelection(selectedKey)
        }
        
        menuView.buildView() // The menu View is built here and not in the buildView() function since it only has to be built once
        menuView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(menuView)
        
        NSLayoutConstraint.activate([
            menuView.topAnchor.constraint(equalTo: topAnchor),
            menuView.bottomAnchor.constraint(equalTo: bottomAnchor),
            menuView.trailingAnchor.constraint(equalTo: leadingAnchor),
            menuView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.45)
        ])
        
        
        buildView(nomogram: nomograms[selectedNomogramId]!)
    }
    
    
    func buildView(nomogram: Nomogram) {
        nomogram.delegate = self
        nomogram.initNomographyScales(screenSize: topView.bounds.size)
        
        // Build the equation label
        buildEquationLabel()
        
        // Build the top View
        topView.nomogram = nomogram
        
        // Build the bottom View
        bottomView.nomogram = nomogram
        bottomView.buildBottomView()
        
        // Build the menu View
        menuView.selectedNomogramId = selectedNomogramId
    }
    
    
    func buildEquationLabel() {
        let selectedNomogram = nomograms[selectedNomogramId]!
        
        if selectedNomogram.name == "Inductive reactance" {
            // Custom nomogram #1
            equationLabel.text = "X = 2π⋅f⋅L"
        } else if selectedNomogram.name == "Body Mass Index (BMI)" {
            // Custom nomogram #2
            equationLabel.text = "BMI = Mass/Height²"
        } else if selectedNomogram.operationType == OperationType.SecondDegree {
            // Only second degree nomogram supported
            equationLabel.text = "X² + BX + C = 0"
        } else {
            
            // Generic addition & multiplication nomograms
            
            let A = selectedNomogram.getNomographyScale(variableEquation: "input1")!
            let B = selectedNomogram.getNomographyScale(variableEquation: "input2")!
            let C = selectedNomogram.getNomographyScale(variableEquation: "output")!
            
            // Tune the display of factors
            // Remove the decimals if the factor is a integer (example: "3.0" -> "3")
            var AFactor = (A.factor == Double(Int(A.factor))) ? "\(Int(A.factor))" : "\(A.factor)"
            var BFactor = (B.factor == Double(Int(B.factor))) ? "\(Int(B.factor))" : "\(B.factor)"
            var CFactor = (C.factor == Double(Int(C.factor))) ? "\(Int(C.factor))" : "\(C.factor)"
            
            // Do not show the factor if it is equal to 1
            AFactor = (AFactor == "1") ? "" : AFactor
            BFactor = (BFactor == "1") ? "" : BFactor
            CFactor = (CFactor == "1") ? "" : CFactor
            
            // Tune the display of the constant (added term for addition, factor for multiplication)
            let constant = (selectedNomogram.constant == Double(Int(selectedNomogram.constant))) ? "\(Int(selectedNomogram.constant))" : "\(selectedNomogram.constant)"
            
            if selectedNomogram.operationType == OperationType.Addition {
                // Addition nomogram
                let addedTerm = (selectedNomogram.constant == 0) ? "" : (selectedNomogram.constant > 0) ? " + " + constant : " - " + constant
                equationLabel.text = CFactor + C.variableName + " = " + AFactor + A.variableName + " + " + BFactor + B.variableName + addedTerm
            } else if selectedNomogram.operationType == OperationType.Multiplication {
                // Multiplication nomogram
                let factor = (selectedNomogram.constant == 1) ? "" : (selectedNomogram.constant > 0) ? constant : " -" + constant + "⋅"
                equationLabel.text = CFactor + C.variableName + " = " + factor + AFactor + A.variableName + "⋅" + BFactor + B.variableName
            }
        }
    }
    
    
    func reloadTopView() {
        topView.reloadView()
    }

    func reloadBottomView() {
        bottomView.reloadView()
    }
    
    
    func showResetButton() {
        UIView.animate(withDuration: 0.5) {
            self.resetButton.alpha = 1
        }
    }
    
    func hideResetButton() {
        UIView.animate(withDuration: 0.1) {
            self.resetButton.alpha = 0
        }
    }
    
    
    func openMenu() {
        UIView.animate(withDuration: 0.3) {
            self.menuView.frame.origin.x += self.menuView.frame.width
            self.blackView.alpha = 0.3
        }
    }
    
    func closeMenu() {
        UIView.animate(withDuration: 0.3) {
            self.menuView.frame.origin.x -= self.menuView.frame.width
            self.blackView.alpha = 0
        }
    }
    
    
    func handleMenuSelection(_ selectedKey: Int) {
        closeMenu()
        
        if selectedNomogramId == selectedKey {
            return // Do not perform any action if the user selects the same nomogram that is currently displayed
        }
            
        selectedNomogramId = selectedKey
        
        // Re-build the view
        buildView(nomogram: nomograms[selectedNomogramId]!)
        
        // Reload the top & bottom Views
        reloadTopView()
        reloadBottomView()
    }
    
    
    @objc func resetButtonPressed(_ sender: UIButton) {
        buildView(nomogram: nomograms[selectedNomogramId]!)
        reloadTopView()
        hideResetButton()
    }

    @objc func openMenuButtonTapped(_ sender: UIButton) {
        openMenu()
    }
    
    @objc func handleBlackViewTap(_ sender: UITapGestureRecognizer) {
        closeMenu()
    }
}
