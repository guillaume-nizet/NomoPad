import UIKit


protocol DigitKeyboardKeyDelegate: AnyObject {
    func keyPressed(keyType: KeyType, digit: String?)
}

enum KeyType {
    case Digit
    case Done
    case Dot
    case NegativeSign
    case Delete
}

class DigitKeyboardKey: UIButton {
    
    var label: UIView!
    var size: CGSize!
    var color: UIColor?
    var keyType: KeyType!
    weak var delegate: DigitKeyboardKeyDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func buildKey() {

        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 5
        
        if color != nil {
            backgroundColor = color
            layer.shadowColor = UIColor.systemGray.cgColor
            layer.shadowOpacity = 0.9
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 0
        }
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
        
        addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            label.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6)
        ])
        
        if let imageView = label as? UIImageView {
            imageView.contentMode = .scaleAspectFit
        }
        
        // Add button action
        addTarget(self, action: #selector(keyPressed(_:)), for: .touchDown)
        addTarget(self, action: #selector(keyReleased(_:)), for: .touchUpInside)
        addTarget(self, action: #selector(keyReleased(_:)), for: .touchDragExit)
    }
    
    
    // Action method to be called when the button is tapped
    @objc func keyPressed(_ sender: DigitKeyboardKey) {
        
        // Update key color
        if sender.keyType == .Digit {
            sender.backgroundColor = UIColor(red: 173/255, green: 179/255, blue: 188/255, alpha: 1)
        }
        
        // Send key pressed info
        if sender.keyType == .Digit, let digitLabel = sender.label as? UILabel {
            let digit: String? = digitLabel.text ?? ""
            delegate?.keyPressed(keyType: sender.keyType, digit: digit)
        } else {
            delegate?.keyPressed(keyType: sender.keyType, digit: nil)
        }
    }
    
    @objc func keyReleased(_ sender: DigitKeyboardKey) {
        
        // Update key color
        if sender.keyType == .Digit {
            sender.backgroundColor = UIColor.white
        }
    }
}
