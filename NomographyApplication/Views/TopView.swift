import UIKit


protocol TopViewDelegate: AnyObject {
    func showResetButton()
    func reloadBottomView()
}


class TopView: UIView {
    
    weak var delegate: TopViewDelegate?
    
    var nomogram: Nomogram!
    var updatingValues = ["output" : false, "input1" : false, "input2" : false]
    var zoomCenter: CGPoint = CGPoint.zero
    
    
    // Draws the index line as a red line on the screen
    func drawIndexLine(indexLine: IndexLine) {
        let indexLinePath = UIBezierPath()
        let strokeColor = UIColor.red
        indexLinePath.move(to: indexLine.startPoint)
        indexLinePath.addLine(to: indexLine.endPoint)
        strokeColor.setStroke()
        indexLinePath.stroke()
    }
    

    override func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw the border of the view
        let borderPath = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
        UIColor.black.setStroke()
        borderPath.lineWidth = 2.0
        borderPath.stroke()

        // Draw the nomography scales
        for nomographyScale in nomogram.nomographyScales {
            nomographyScale.displayScale(in: context, position: "topView")
        }
                
        drawIndexLine(indexLine: nomogram.indexLine)
    }
    
    
    // This function handles the zoom on the nomogram associated with a pinch gesture
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            // Register the zoom center only at the beginning of the pinch to ensure natural user interaction
            zoomCenter = gestureRecognizer.location(in: self)
        }
        if gestureRecognizer.state == .changed {
            let zoom = gestureRecognizer.scale
                            
            // Apply zoom to each scale
            for nomographyScale in nomogram.nomographyScales {
                nomographyScale.zoomScale(zoom, zoomCenter, position: "topView")
            }
            
            // handleMovement() must be called whenever the position of the scales is modified, and after the modification
            for nomographyScale in nomogram.nomographyScales {
                nomographyScale.handleMovement(position: "topView")
            }
            
            // Apply zoom to index line
            nomogram.indexLine.startPoint = Nomography.applyZoom(point: nomogram.indexLine.startPoint, scale: zoom, center: zoomCenter)
            nomogram.indexLine.endPoint = Nomography.applyZoom(point: nomogram.indexLine.endPoint, scale: zoom, center: zoomCenter)
            
            gestureRecognizer.scale = 1.0
            
            delegate?.showResetButton()
            reloadView()
        }
    }
    
    
    // This function handles the 2 uses of a pan gesture:
    // - Updating the value of a variable: if the variable is unfixed and the finger is close enough to the value of the variable
    // or - Translating the nomogram
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self)
            let fingerPoint = gestureRecognizer.location(in: self)
            
            for nomographyScale in nomogram.nomographyScales {
                if !nomographyScale.fixed {
                    
                    // Check if the pan gesture corresponds to an update of the value of a scale
                    var updatingValue = false
                    
                    // Case #1: the user is already updating the value (he started updating the value and did not release his finger yet)
                    if updatingValues[nomographyScale.variableEquation]! {
                        updatingValue = true
                    }
                    
                    // Case #2: the user's finger is close enough to the position of the current value of the scale
                    let currentValuePoint = nomographyScale.getPoint(variableValue: nomographyScale.variableValue, position: "topView")!
                    if Nomography.isInHitbox(target: currentValuePoint, point: fingerPoint) {
                        updatingValue = true
                    }
                    
                    if updatingValue {
                        updatingValues[nomographyScale.variableEquation] = true // Mark the value as being updated
                        
                        if let straightNomographyScale = nomographyScale as? StraightNomographyScale {
                            // For a straight scale, take the projection of the finger position on the scale to get the new value
                            let projectionPoint = straightNomographyScale.computeProjection(point: fingerPoint, position: "topView")
                            let projectionValue = straightNomographyScale.getVariableValue(point: projectionPoint, position: "topView")
                            
                            // Update the value
                            nomogram.updateVariableValue(nomographyScale: straightNomographyScale, variableValue: projectionValue)
                            
                        } else if let curvedNomographyScale = nomographyScale as? CurvedNomographyScale {
                            // For a curved scale, since the curved scale does not represent the underlying variable perfectly, we use finger position in order to compute the new variable value for the unfixed variable represented by one of the 2 straight scales
                            for otherNomographyScale in nomogram.nomographyScales {
                                if (!otherNomographyScale.fixed) && otherNomographyScale.variableEquation != curvedNomographyScale.variableEquation {
                                    let newValue = curvedNomographyScale.computeVariableValueFromProjection(fingerPoint, position: "topView")
                                    
                                    // Update the value
                                    nomogram.updateVariableValue(nomographyScale: otherNomographyScale, variableValue: newValue)
                                }
                            }
                        }
                    }
                }
            }
                
            if !updatingValues["output"]! && !updatingValues["input1"]! && !updatingValues["input2"]! {
                
                // If no value was updated, the pan gesture corresponds to a translation of the nomogram
                delegate?.showResetButton()
                
                // Translate the scales
                for nomographyScale in nomogram.nomographyScales {
                    nomographyScale.translateScale(translation, position: "topView")
                }
                
                // Translate the indexLine
                nomogram.indexLine.translateLine(translation)
                
                // handleMovement() must be called whenever the position of the scales is modified, and after the modification
                for nomographyScale in nomogram.nomographyScales {
                    nomographyScale.handleMovement(position: "topView")
                }
            } else {
                
                // If a value was updated, call handleMovement("zoomedView") because updating makes the zoomedView lines translate
                for nomographyScale in nomogram.nomographyScales {
                    nomographyScale.handleMovement(position: "zoomedView")
                }
            }
            
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
            
            reloadView()
            delegate?.reloadBottomView()
        }
        
        if gestureRecognizer.state == .ended {
            // Finger released, mark all values as not being updated
            updatingValues = ["output" : false, "input1" : false, "input2" : false]
        }
    }
    
    
    // This function is used to fix a variable by applying a long press near an unfixed value of a variable
    @objc func handleLongPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .ended {
            let fingerPoint = gestureRecognizer.location(in: self)

            for nomographyScale in nomogram.nomographyScales {
                if !nomographyScale.fixed {
                    if Nomography.isInHitbox(target: fingerPoint, point: nomographyScale.getPoint(variableValue: nomographyScale.variableValue, position: "topView")!) {
                        
                        // If the variable is unfixed and the finger is close enough to the value of the variable, fix the variable and unfix the other variables
                        for otherNomographyScale in nomogram.nomographyScales {
                            if otherNomographyScale.variableEquation == nomographyScale.variableEquation {
                                // Disable the button
                                otherNomographyScale.fixButton.isEnabled = false
                                otherNomographyScale.fixButton.setTitle("Fixed variable", for: .normal)
                                otherNomographyScale.fixButton.setTitleColor(.systemGray, for: .normal)
                                otherNomographyScale.fixButton.backgroundColor = .systemGray4
                                otherNomographyScale.setFixed(true)
                            } else {
                                // Enable the other buttons
                                otherNomographyScale.fixButton.isEnabled = true
                                otherNomographyScale.fixButton.setTitle("Fix variable", for: .normal)
                                otherNomographyScale.fixButton.setTitleColor(.white, for: .normal)
                                otherNomographyScale.fixButton.backgroundColor = .systemBlue
                                otherNomographyScale.setFixed(false)
                            }
                        }
                        reloadView()
                        delegate?.reloadBottomView()
                    }
                }
            }
        }
    }
    
    
    func reloadView() {
        setNeedsDisplay()
    }
}
