import UIKit


class ZoomedView: UIView {
    var nomographyScale: NomographyScale!
    var nomogram: Nomogram!
    var updatingValue: Bool = false

    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        nomographyScale.screenSizeZoomed = bounds.size
        nomographyScale.displayScale(in: context, position: "zoomedView")
    }
    
    
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .changed {
            let zoom = gestureRecognizer.scale
            nomographyScale.zoomScale(zoom, CGPoint.zero, position: "zoomedView") // The zoom center is computed inside the zoomScale() function
            nomographyScale.handleMovement(position: "zoomedView")
            setNeedsDisplay()
            gestureRecognizer.scale = 1.0
        }
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .changed {
            let fingerPoint = gestureRecognizer.location(in: self)

            if !nomographyScale.fixed {
                let currentValuePoint = nomographyScale.getPoint(variableValue: nomographyScale.variableValue, position: "zoomedView")!
                if Nomography.isInHitbox(target: currentValuePoint, point: fingerPoint) {
                    updatingValue = true
                }
                
                if updatingValue {
                    
                    if let straightNomographyScale = nomographyScale as? StraightNomographyScale {
                        // For a straight scale, take the projection of the finger position on the scale to get the new value
                        let projectionPoint = straightNomographyScale.computeProjection(point: fingerPoint, position: "zoomedView")
                        let projectionValue = straightNomographyScale.getVariableValue(point: projectionPoint, position: "zoomedView")
                        
                        // Update the value
                        nomogram.updateVariableValue(nomographyScale: straightNomographyScale, variableValue: projectionValue)
                        
                    } else if let curvedNomographyScale = nomographyScale as? CurvedNomographyScale {
                        // For a curved scale, since the curved scale does not represent the underlying variable perfectly, we use finger position in order to compute the new variable value for the unfixed variable represented by one of the 2 straight scales
                        for otherNomographyScale in nomogram.nomographyScales {
                            if (!otherNomographyScale.fixed) && otherNomographyScale.variableEquation != curvedNomographyScale.variableEquation {
                                let newValue = curvedNomographyScale.computeVariableValueFromProjection(fingerPoint, position: "zoomedView")
                                
                                // Update the value
                                nomogram.updateVariableValue(nomographyScale: otherNomographyScale, variableValue: newValue)
                            }
                        }
                    }
                    
                    for nomographyScale in nomogram.nomographyScales {
                        nomographyScale.handleMovement(position: "zoomedView")
                    }
                }
            }
            
            gestureRecognizer.setTranslation(CGPoint.zero, in: self)
        }
        
        if gestureRecognizer.state == .ended {
            // Finger released, mark the value as not being updated
            updatingValue = false
        }
    }
}
