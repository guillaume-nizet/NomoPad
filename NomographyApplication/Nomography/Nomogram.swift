import Foundation
import UIKit


enum OperationType {
    case Addition
    case Multiplication
    case SecondDegree
}


typealias NomographyScaleInitializer = (
    name: String,
    unit: String?,
    factor: Double,
    exponent: Double,
    range: Range?
)


protocol NomogramDelegate: AnyObject {
    func buildView(nomogram: Nomogram)
    func reloadTopView()
    func reloadBottomView()
}


class Nomogram {
    
    weak var delegate: NomogramDelegate?
    
    var type: String // "premade" or "custom"
    var name: String
    var operationType: OperationType
    var input1Initializer: NomographyScaleInitializer
    var input2Initializer: NomographyScaleInitializer
    var outputInitializer: NomographyScaleInitializer
    var constant: Double

    var nomographyScales: [NomographyScale]!
    var indexLine: IndexLine = IndexLine(startPoint: CGPoint.zero, endPoint: CGPoint.zero)
    
    
    init(type: String, name: String, operationType: OperationType, input1Initializer: NomographyScaleInitializer, input2Initializer: NomographyScaleInitializer, outputInitializer: NomographyScaleInitializer, constant: Double) {
        self.type = type
        self.name = name
        self.operationType = operationType
        self.input1Initializer = input1Initializer
        self.input2Initializer = input2Initializer
        self.outputInitializer = outputInitializer
        self.constant = constant
    }
    
    
    // Computes the nomography scales representing the nomogram
    func initNomographyScales(screenSize: CGSize) {
        switch operationType {
        case .Addition:
            nomographyScales = Nomography.getNomographyScalesAddition(input1Initializer, input2Initializer, outputInitializer, addedTerm: constant, screenSize: screenSize)
        case .Multiplication:
            nomographyScales = Nomography.getNomographyScalesMultiplication(input1Initializer, input2Initializer, outputInitializer, factor: constant, screenSize: screenSize)
        case .SecondDegree:
            nomographyScales = Nomography.getNomographyScalesSecondDegree(input1Initializer, input2Initializer, outputInitializer, screenSize: screenSize)
        }
        updateIndexLine()
    }
    
    
    // Updates the value of the given nomography scale with the new given value
    // Also updates the variable value of the other unfixed nomography scale accordingly
    // If any of these updates leads to an outside-bounds value, the variables values are not updated
    // Returns true if the update was successful and false otherwise
    func updateVariableValue(nomographyScale: NomographyScale, variableValue: Double) -> Bool {
        if !nomographyScale.isInsideBounds(variableValue: variableValue) || nomographyScale.fixed {
            // Do not update the variable value if it is outside the range of the scale or if it is fixed
            return false
        }
        
        let oldValue = nomographyScale.variableValue
        
        // Update variable value
        nomographyScale.variableValue = variableValue
                
        // Compute the new value for the other unfixed variable
        for otherNomographyScale in nomographyScales {
            if otherNomographyScale.variableEquation != nomographyScale.variableEquation && otherNomographyScale.fixed == false {
                
                let otherVariableValue = computeVariableValue(nomographyScale: otherNomographyScale)

                if !otherNomographyScale.isInsideBounds(variableValue: otherVariableValue) {
                    
                    // Cancel the change if updating the initial value leads to an outside-bounds value for the other unfixed variable
                    nomographyScale.variableValue = oldValue
                    return false
                }

                // Update value & textField of the other unfixed variable
                otherNomographyScale.variableValue = otherVariableValue
                otherNomographyScale.valueTextField.attributedText = NSAttributedString(string: "\(otherVariableValue)")
            }
        }
        
        // Update textField
        nomographyScale.valueTextField.attributedText = NSAttributedString(string: "\(variableValue)")
        
        // Update index line
        updateIndexLine()
        
        // Reload views
        delegate?.reloadTopView()
        delegate?.reloadBottomView()
        
        return true // The variable was correctly updated
    }
    
    
    // Computes the correct variable value represented by the given nomography scale based on the values of the other variables
    func computeVariableValue(nomographyScale: NomographyScale) -> Double {
        switch operationType {
            
        case .Addition:
            let A = getNomographyScale(variableEquation: "input1")!
            let B = getNomographyScale(variableEquation: "input2")!
            let C = getNomographyScale(variableEquation: "output")!
            
            if nomographyScale.variableEquation == "output" {
                return A.variableValue * A.factor + B.variableValue * B.factor + constant
            } else if nomographyScale.variableEquation == "input1" {
                return (C.variableValue * C.factor - B.variableValue * B.factor - constant) / A.factor
            } else if nomographyScale.variableEquation == "input2" {
                return (C.variableValue * C.factor - A.variableValue * A.factor - constant) / B.factor
            }
            
        case .Multiplication:
            let A = getNomographyScale(variableEquation: "input1")!
            let B = getNomographyScale(variableEquation: "input2")!
            let C = getNomographyScale(variableEquation: "output")!
            
            if nomographyScale.variableEquation == "output" {
                return exp((A.exponent * log(A.variableValue) + B.exponent * log(B.variableValue) + log(A.factor) + log(B.factor) + log(constant) - log(C.factor)) / C.exponent)
            } else if nomographyScale.variableEquation == "input1" {
                return exp((C.exponent * log(C.variableValue) - B.exponent * log(B.variableValue) - log(A.factor) - log(B.factor) + log(C.factor) - log(constant)) / A.exponent)
            } else if nomographyScale.variableEquation == "input2" {
                return exp((C.exponent * log(C.variableValue) - A.exponent * log(A.variableValue) - log(A.factor) - log(B.factor) + log(C.factor) - log(constant)) / B.exponent)
            }
            
        case .SecondDegree:
            let C = getNomographyScale(variableEquation: "input1")!.variableValue
            let B = getNomographyScale(variableEquation: "input2")!.variableValue
            let X = getNomographyScale(variableEquation: "output")!.variableValue
            
            if nomographyScale.variableEquation == "input2" {
                // Computing B
                // X² + BX + C = 0
                // Bx = -C - X²
                // B = -(C + X²)/X
                return -(C + X * X) / X
            } else if nomographyScale.variableEquation == "input1" {
                // Computing C
                // X² + BX + C = 0
                // C = -X² - BX
                return -(X * X) - B * X
            } else if nomographyScale.variableEquation == "output" {
                // Computing X
                let X1 = (-B + sqrt(B * B - 4 * C)) / 2
                let X2 = (-B - sqrt(B * B - 4 * C)) / 2
                
                // Keep the negative root
                if X1 <= 0.0 {
                    return X1
                } else {
                    return X2
                }
            }
        }
        
        return 0
    }
    
    
    // Updates the index line by assigning its start point to the value of the scale on the left and its end point to the value of the scale on the right
    func updateIndexLine() {
        if operationType == OperationType.Addition || operationType == OperationType.Multiplication {
            for nomographyScale in nomographyScales {
                if nomographyScale.index == 0 {
                    indexLine.startPoint = nomographyScale.getPoint(variableValue: nomographyScale.variableValue, position: "topView")!
                } else if nomographyScale.index == 2 {
                    indexLine.endPoint = nomographyScale.getPoint(variableValue: nomographyScale.variableValue, position: "topView")!
                }
            }
        } else if operationType == OperationType.SecondDegree {
            
            let C = getNomographyScale(variableEquation: "input1")!
            let B = getNomographyScale(variableEquation: "input2")!
            
            indexLine.startPoint = C.getPoint(variableValue: C.variableValue, position: "topView")!
            indexLine.endPoint = B.getPoint(variableValue: B.variableValue, position: "topView")!
        }
    }
    
    
    // Updates the range of the given scale
    // Returns true if the range update was successful and false otherwise
    func updateRange(nomographyScale: NomographyScale, lowerRange: CGFloat?, upperRange: CGFloat?) -> Bool {
        
        if operationType == OperationType.SecondDegree {
            // Special case of the second degree equation nomogram:
            // - The start values of both straight scales (C & B) must be 0 (and therefore cannot be updated)
            // - The end value of C must be negative
            // - The end value of B must be the opposite of C's
            // - The end value of C and B must not exceed -60 and 60: the current approximation with the Bézier curve does not allow to go further
            
            if lowerRange != nil {
                return false // Cannot update the start value
            }
            
            if upperRange != nil {
                if abs(upperRange!) > 60 {
                    return false // Cannot exceed -60 and 60
                }
                if upperRange! == nomographyScale.startValue {
                    return false // Start & end values cannot be the same
                }
                if nomographyScale.variableEquation == "input1" {
                    if upperRange! < 0 {
                        input1Initializer.range!.endValue = upperRange!
                        input2Initializer.range!.endValue = -upperRange! // The end value of B must be the opposite of C's
                    } else {
                        return false // The end value of C cannot be positive
                    }
                } else if nomographyScale.variableEquation == "input2" {
                    if upperRange! > 0 {
                        input2Initializer.range!.endValue = upperRange!
                        input1Initializer.range!.endValue = -upperRange!
                    } else {
                        return false
                    }
                } else {
                    // The range of the output variable cannot be directly modified as it depends on the 2 input variables
                    return false
                }
            }
        }
        
        
        // Case of addition or mutiplication nomogram: less constraints
        
        if lowerRange != nil {
            if lowerRange! == nomographyScale.endValue {
                return false // Start & end values cannot be the same
            }
            if nomographyScale.variableEquation == "input1" {
                input1Initializer.range!.startValue = lowerRange!
            } else if nomographyScale.variableEquation == "input2" {
                input2Initializer.range!.startValue = lowerRange!
            } else {
                return false
            }
        }
        
        if upperRange != nil {
            if upperRange! == nomographyScale.startValue {
                return false // start & end values cannot be the same
            }
            if nomographyScale.variableEquation == "input1" {
                input1Initializer.range!.endValue = upperRange!
            } else if nomographyScale.variableEquation == "input2" {
                input2Initializer.range!.endValue = upperRange!
            } else {
                return false
            }
        }

        
        // Rebuild and reload the whole view
        delegate?.buildView(nomogram: self)
        delegate?.reloadTopView()
        delegate?.reloadBottomView()

        return true
    }


    func getNomographyScale(variableEquation: String) -> NomographyScale? {
        for nomographyScale in nomographyScales {
            if nomographyScale.variableEquation == variableEquation {
                return nomographyScale
            }
        }
        return nil
    }
}
