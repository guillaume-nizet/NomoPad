import UIKit


class DigitKeyboard: UIView, DigitKeyboardKeyDelegate {
    
    var bottomView: BottomView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        
        backgroundColor = UIColor.systemGray4
        layer.cornerRadius = 10.0
        layer.masksToBounds = true
        
        let buttonSize = CGSize(width: 90, height: 45)
        
        // Set initial position at the bottom of the screen
        frame = CGRect(x: 215, y: UIScreen.main.bounds.height, width: 5 * 7 + 4 * buttonSize.width, height: 5 * 7 + 4 * buttonSize.height)
        
        // Add the digit keys 1-9
        for i in 1...9 {
            let xPosition: CGFloat = buttonSize.width * CGFloat((i - 1) % 3) + CGFloat(7 * CGFloat((i - 1) % 3))
            let yPosition: CGFloat = buttonSize.height * CGFloat((i - 1) / 3) + CGFloat(7 * CGFloat((i - 1) / 3))

            let key = DigitKeyboardKey()
            let label = UILabel()
            label.text = String(i)
            label.font = UIFont.systemFont(ofSize: 20)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            key.label = label
            key.size = buttonSize
            key.color = UIColor.white
            key.keyType = KeyType.Digit
            key.delegate = self
            key.buildKey()

            addSubview(key)

            key.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                key.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7 + xPosition),
                key.topAnchor.constraint(equalTo: topAnchor, constant: 7 + yPosition)
            ])
        }
        
        
        // Add the digit key 0
        let zeroKey = DigitKeyboardKey()
        let zeroKeyLabel = UILabel()
        zeroKeyLabel.text = "0"
        zeroKeyLabel.font = UIFont.systemFont(ofSize: 20)
        zeroKeyLabel.textAlignment = .center
        zeroKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        zeroKey.label = zeroKeyLabel
        zeroKey.size = buttonSize
        zeroKey.color = UIColor.white
        zeroKey.keyType = KeyType.Digit
        zeroKey.delegate = self
        zeroKey.buildKey()

        addSubview(zeroKey)

        zeroKey.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zeroKey.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14 + buttonSize.width),
            zeroKey.topAnchor.constraint(equalTo: topAnchor, constant: 28 + 3 * buttonSize.height)
        ])
        
        
        // Add the negative sign key
        let negativeSignKey = DigitKeyboardKey()
        let negativeSignKeyLabel = UILabel()
        negativeSignKeyLabel.text = "-"
        negativeSignKeyLabel.font = UIFont.systemFont(ofSize: 20)
        negativeSignKeyLabel.textAlignment = .center
        negativeSignKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        negativeSignKey.label = negativeSignKeyLabel
        negativeSignKey.size = buttonSize
        negativeSignKey.keyType = KeyType.NegativeSign
        negativeSignKey.delegate = self
        negativeSignKey.buildKey()

        addSubview(negativeSignKey)

        negativeSignKey.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            negativeSignKey.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            negativeSignKey.topAnchor.constraint(equalTo: zeroKey.topAnchor)
        ])
        
        
        // Add the dot key
        let dotKey = DigitKeyboardKey()
        let dotKeyLabel = UILabel()
        dotKeyLabel.text = "."
        dotKeyLabel.font = UIFont.systemFont(ofSize: 20)
        dotKeyLabel.textAlignment = .center
        dotKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dotKey.label = dotKeyLabel
        dotKey.size = buttonSize
        dotKey.keyType = KeyType.Dot
        dotKey.delegate = self
        dotKey.buildKey()

        addSubview(dotKey)

        dotKey.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotKey.leadingAnchor.constraint(equalTo: zeroKey.trailingAnchor, constant: 7),
            dotKey.topAnchor.constraint(equalTo: zeroKey.topAnchor)
        ])
        
        
        // Add the delete key
        let deleteKey = DigitKeyboardKey()
        let deleteKeyLabel = UIImageView(image: UIImage(systemName: "delete.left"))
        deleteKeyLabel.tintColor = .black
        
        deleteKey.label = deleteKeyLabel
        deleteKey.size = buttonSize
        deleteKey.keyType = KeyType.Delete
        deleteKey.delegate = self
        deleteKey.buildKey()

        addSubview(deleteKey)

        deleteKey.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteKey.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28 + 3 * buttonSize.width),
            deleteKey.topAnchor.constraint(equalTo: topAnchor, constant: 7)
        ])
        

        // Add the "Done" key
        let doneKey = DigitKeyboardKey()
        let doneKeyLabel = UILabel()
        doneKeyLabel.text = "Done"
        doneKeyLabel.font = UIFont.systemFont(ofSize: 20)
        doneKeyLabel.textAlignment = .center
        doneKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        doneKey.label = doneKeyLabel
        doneKey.size = buttonSize
        doneKey.color = UIColor(red: 173/255, green: 179/255, blue: 188/255, alpha: 1)
        doneKey.keyType = KeyType.Done
        doneKey.delegate = self
        doneKey.buildKey()
        
        addSubview(doneKey)
        
        doneKey.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneKey.leadingAnchor.constraint(equalTo: deleteKey.leadingAnchor),
            doneKey.topAnchor.constraint(equalTo: zeroKey.topAnchor)
        ])
    }
    
    func keyPressed(keyType: KeyType, digit: String?) {
        switch keyType {
        case .Digit:
            bottomView.addDigit(digit: digit!)
        case .Done:
            closeKeyboard()
        case .Dot:
            bottomView.addDot()
        case .NegativeSign:
            bottomView.addNegativeSign()
        case .Delete:
            bottomView.removeCharacter()
        }
    }
    
    func closeKeyboard() {
        
        // Animate the sliding into position
        UIView.animate(withDuration: 0.3) {
            self.frame.origin.y = UIScreen.main.bounds.height
        }
        
        // Lose focus on textFields
        bottomView.loseFocus()
    }
    
}
