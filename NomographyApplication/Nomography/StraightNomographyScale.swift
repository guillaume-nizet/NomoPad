import Foundation
import CoreGraphics
import UIKit


class StraightNomographyScale: NomographyScale {
    
    var directionVector = CGVector(dx: 0, dy: 0)

    
    init(factor: Double, exponent: Double, startPoint: Point, endPoint: Point, startValue: CGFloat, endValue: CGFloat, variableValue: CGFloat, variableName: String, variableUnit: String?, fixed: Bool, screenSize: CGSize, screenSizeZoomed: CGSize, variableEquation: String, logVariable: Bool) {

        
        super.init(factor: factor, exponent: exponent, variableValue: variableValue, startPoint: startPoint, endPoint: endPoint, startValue: startValue, endValue: endValue, variableName: variableName, variableUnit: variableUnit, fixed: fixed, variableEquation: variableEquation, screenSize: screenSize, screenSizeZoomed: screenSizeZoomed, logVariable: logVariable)
    }
    
    
    override func buildScale() {
        
        if startValue > endValue {
            direction = -1.0
        }
        
        buildGraduations(position: "topView")
        graduations["zoomedView"] = graduations["topView"]
    }
    
    
    override func displayScale(in context: CGContext, position: String) {
        
        if position == "zoomedView" {

            // Get position of variable value
            let positionVariableValue = getPoint(variableValue: variableValue, position: position)!
 
            // Translate the line to center the variable value
            let centerPoint = CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2)

            let translation = CGPoint(x: centerPoint.x - positionVariableValue.x, y: centerPoint.y - positionVariableValue.y)
            translateScale(translation, position: "zoomedView")
        }
        
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)
        
        if position == "topView" {
            context.move(to: startPoint.topView)
            context.addLine(to: endPoint.topView)
        } else if position == "zoomedView" {
            context.move(to: startPoint.zoomedView)
            context.addLine(to: endPoint.zoomedView)
        }
        
        context.strokePath()
        
        displayGraduations(in: context, position: position)
        
        // Display variable name on the top view
        if position == "topView" {
            displayVariableName(in: context)
        }
        
        // Display the variable value
        displayVariableValue(in: context, position: position)
    }
    

    // Get coordinates associated with the variable value on the scale
    override func getPoint(variableValue: Double, position: String) -> CGPoint? {
        
        var distanceFraction = (variableValue - startValue) / (endValue - startValue)
        
        if logVariable {
            let logVar = log(variableValue)
            let logStart = log(startValue)
            let logEnd = log(endValue)
            
            distanceFraction = (logVar - logStart) / (logEnd - logStart)
        }
        
        if position == "topView" {
            return CGPoint(x: startPoint.topView.x, y: startPoint.topView.y - distanceFraction * (startPoint.topView.y - endPoint.topView.y))
        } else if position == "zoomedView" {
            return CGPoint(x: startPoint.zoomedView.x, y: startPoint.zoomedView.y - distanceFraction * (startPoint.zoomedView.y - endPoint.zoomedView.y))
        } else {
            return CGPoint(x: startPoint.zoomedViewForBezier!.x, y: startPoint.zoomedViewForBezier!.y - distanceFraction * (startPoint.zoomedViewForBezier!.y - endPoint.zoomedViewForBezier!.y))
        }
    }
    
    
    override func findIntersectionWithScale(line: (CGPoint, CGPoint), position: String) -> CGPoint {
        if position == "topView" {
            return Nomography.findIntersection(line1: line, line2: (startPoint.topView, endPoint.topView))
        } else if position == "zoomedView" {
            return Nomography.findIntersection(line1: line, line2: (startPoint.zoomedView, endPoint.zoomedView))
        } else {
            return Nomography.findIntersection(line1: line, line2: (startPoint.zoomedViewForBezier!, endPoint.zoomedViewForBezier!))
        }
    }
    
    
    func getVariableValue(point: CGPoint, position: String) -> Double {
        let directionVector = (position == "topView") ?
        CGVector(dx: endPoint.topView.x - startPoint.topView.x, dy: endPoint.topView.y - startPoint.topView.y) :
        (position == "zoomedView") ?
        CGVector(dx: endPoint.zoomedView.x - startPoint.zoomedView.x, dy: endPoint.zoomedView.y - startPoint.zoomedView.y) :
        CGVector(dx: endPoint.zoomedViewForBezier!.x - startPoint.zoomedViewForBezier!.x, dy: endPoint.zoomedViewForBezier!.y - startPoint.zoomedViewForBezier!.y)
        
        let pointVector = (position == "topView") ?
        CGVector(dx: point.x - startPoint.topView.x, dy: point.y - startPoint.topView.y) :
        (position == "zoomedView") ?
        CGVector(dx: point.x - startPoint.zoomedView.x, dy: point.y - startPoint.zoomedView.y) :
        CGVector(dx: point.x - startPoint.zoomedViewForBezier!.x, dy: point.y - startPoint.zoomedViewForBezier!.y)

        let distanceFraction: CGFloat
        if directionVector.dx != 0 {
            distanceFraction = pointVector.dx / directionVector.dx
        } else if directionVector.dy != 0 {
            distanceFraction = pointVector.dy / directionVector.dy
        } else {
            // Edge case: startPoint and endPoint are the same
            return startValue
        }

        var variableValue = startValue + distanceFraction * (endValue - startValue)
        
        if logVariable {
            variableValue = exp(log(startValue) + distanceFraction * (log(endValue) - log(startValue)))
        }
        
        return variableValue
    }
    
    
    func buildGraduation(_ graduationValue: Double, position: String, textPosition: String) -> Graduation {
        let graduationValue = graduationValue.rounded(toDecimalPlaces: 10)
        let graduationPoint = getPoint(variableValue: graduationValue, position: position)!
        
        // Compute the graduation start & end points
        let graduationStartPoint = CGPoint(x: graduationPoint.x - graduationLength, y: graduationPoint.y)
        let graduationEndPoint = CGPoint(x: graduationPoint.x + graduationLength, y: graduationPoint.y)
        
        // Calculate the size of the text
        let text = graduationValue.description
        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = text.size(withAttributes: attributes)
        
        // Calculate the position to center the text
        let textPoint = CGPoint(
            x: (textPosition == "left") ? graduationStartPoint.x - 20 - textSize.width / 2.0 : graduationStartPoint.x + 20 + textSize.width / 2.0,
            y: graduationStartPoint.y - textSize.height / 2.0
        )
        
        let graduation: Graduation = (
            value: graduationValue,
            point: graduationPoint,
            startPoint: CGPoint(x: graduationPoint.x - graduationStartPoint.x, y: graduationPoint.y - graduationStartPoint.y),
            endPoint: CGPoint(x: graduationPoint.x - graduationEndPoint.x, y: graduationPoint.y - graduationEndPoint.y),
            textPoint: CGPoint(x: graduationPoint.x - textPoint.x, y: graduationPoint.y - textPoint.y)
        )
        
        return graduation
    }
    
    
    // Computes the orthogonal projection of a point onto a nomography scale
    func computeProjection(point: CGPoint, position: String) -> CGPoint {
        let lineVector = (position == "topView") ?
        CGVector(dx: endPoint.topView.x - startPoint.topView.x, dy: endPoint.topView.y - startPoint.topView.y) :
        CGVector(dx: endPoint.zoomedView.x - startPoint.zoomedView.x, dy: endPoint.zoomedView.y - startPoint.zoomedView.y)
        
        let pointVector = (position == "topView") ?
        CGVector(dx: point.x - startPoint.topView.x, dy: point.y - startPoint.topView.y) :
        CGVector(dx: point.x - startPoint.zoomedView.x, dy: point.y - startPoint.zoomedView.y)
        
        let dotProduct = pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy
        let lineVectorLengthSquared = lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy
        
        
        let projection = (position == "topView") ?
        CGPoint(x: startPoint.topView.x + (dotProduct / lineVectorLengthSquared) * lineVector.dx, y: startPoint.topView.y + (dotProduct / lineVectorLengthSquared) * lineVector.dy) :
        CGPoint(x: startPoint.zoomedView.x + (dotProduct / lineVectorLengthSquared) * lineVector.dx, y: startPoint.zoomedView.y + (dotProduct / lineVectorLengthSquared) * lineVector.dy)

        return projection
    }
}
