import Foundation
import UIKit


class CurvedNomographyScale: NomographyScale {
    
    // For the moment, a curved nomography scale always depends on two straight nomography scales: C & B
    var C: StraightNomographyScale
    var B: StraightNomographyScale
    var bezierControlPoints: (Point, Point) = (
        Point(topView: CGPoint.zero, zoomedView: CGPoint.zero, zoomedViewForBezier: nil),
        Point(topView: CGPoint.zero, zoomedView: CGPoint.zero, zoomedViewForBezier: nil)
    )
    
    var scaleX: Double {
        return B.startPoint.topView.x - C.startPoint.topView.x
    }
    var scaleY: Double {
        return B.getPoint(variableValue: 0, position: "topView")!.y - B.getPoint(variableValue: 1, position: "topView")!.y
    }
    
    
    init(C: StraightNomographyScale, B: StraightNomographyScale, factor: Double, exponent: Double, variableValue: Double, startPoint: Point, endPoint: Point, startValue: Double, endValue: Double, variableName: String, variableUnit: String?, fixed: Bool, variableEquation: String, screenSize: CGSize, screenSizeZoomed: CGSize, logVariable: Bool) {
        
        self.C = C
        self.B = B
        
        super.init(factor: factor, exponent: exponent, variableValue: variableValue, startPoint: startPoint, endPoint: endPoint, startValue: startValue, endValue: endValue, variableName: variableName, variableUnit: variableUnit, fixed: fixed, variableEquation: variableEquation, screenSize: screenSize, screenSizeZoomed: screenSizeZoomed, logVariable: logVariable)
    }
    
    
    override func buildScale() {
        computeBezierPoints()
        buildGraduations(position: "topView")
        zoomThreshold["topView"] = 3.0
        zoomThreshold["zoomedView"] = 3.0
    }

    
    override func displayScale(in context: CGContext, position: String) {
        if position == "zoomedView" {
            // Get position of variable value
            let positionVariableValue = getPoint(variableValue: variableValue, position: "zoomedViewForBezier")!
            
            // Translate the line to center the variable value
            let centerPoint = CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2)
            let translation = CGPoint(x: centerPoint.x - positionVariableValue.x, y: centerPoint.y - positionVariableValue.y)
            translateScale(translation, position: "zoomedView")
            
            // Translate the 2 invisible straight lines C & B
            C.translateScale(translation, position: "zoomedViewForBezier")
            B.translateScale(translation, position: "zoomedViewForBezier")
            
            // Build graduationss if needed
            if graduations["zoomedView"]!.firstOrder.graduations.count == 0 {
                buildGraduations(position: position)
            }
        }
        
        
        // Display bezier curve
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)
        
        if position == "topView" {
            context.move(to: startPoint.topView)
            context.addCurve(to: endPoint.topView, control1: bezierControlPoints.0.topView, control2: bezierControlPoints.1.topView)
            
            
        } else if position == "zoomedView" {
            context.move(to: startPoint.zoomedView)
            context.addCurve(to: endPoint.zoomedView, control1: bezierControlPoints.0.zoomedView, control2: bezierControlPoints.1.zoomedView)
        }
        
        context.strokePath()
                
        // Display graduations
        displayGraduations(in: context, position: position)
        
        // Display variable name on the top view
        if position == "topView" {
            displayVariableName(in: context)
        }
        
        // Display the variable value
        displayVariableValue(in: context, position: position)
    }
    
    
    func buildGraduation(_ graduationValue: Double, position: String) -> Graduation {
        
        // Get point corresponding to the graduation value
        let graduationPoint = getPoint(variableValue: graduationValue, position: position)!
        
        // Get value of abscissa
        let abscissa = (position == "topView") ?
        (graduationPoint.x - C.startPoint.topView.x) / (B.startPoint.topView.x - C.startPoint.topView.x) :
        (graduationPoint.x - C.startPoint.zoomedViewForBezier!.x) / (B.startPoint.zoomedViewForBezier!.x - C.startPoint.zoomedViewForBezier!.x)

        // Get the value of the derivate at this abscissa
        var derivateValue = getDerivate(abscissa)

        // The derivate value needs to be scaled since x and y axis are not orthonormal
        derivateValue *= (position == "topView") ?
        (B.getPoint(variableValue: 0, position: "topView")!.y - B.getPoint(variableValue: 1, position: "topView")!.y) / (B.startPoint.topView.x - C.startPoint.topView.x) :
        (B.getPoint(variableValue: 0, position: "zoomedViewForBezier")!.y - B.getPoint(variableValue: 1, position: "zoomedViewForBezier")!.y) / (B.startPoint.zoomedViewForBezier!.x - C.startPoint.zoomedViewForBezier!.x)

        // Get the value of the perpendicular derivate
        let perpendicularDerivateValue = -1 / derivateValue

        // Compute the graduation start & end points
        let angle = atan(perpendicularDerivateValue)
        let dx = cos(angle)
        let dy = sin(angle)
        let displacementVector = CGPoint(x: dx * graduationLength, y: dy * graduationLength)
        let graduationStartPoint = CGPoint(x: graduationPoint.x - displacementVector.x, y: graduationPoint.y + displacementVector.y)
        let graduationEndPoint = CGPoint(x: graduationPoint.x + displacementVector.x, y: graduationPoint.y - displacementVector.y)
        
        // Calculate the size of the text
        let text = graduationValue.description
        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = text.size(withAttributes: attributes)
        
        // Calculate the position to center the text
        let textPoint = CGPoint(
            x: graduationPoint.x - displacementVector.x * 3.0 - textSize.width / 2.0,
            y: graduationPoint.y + displacementVector.y * 3.0 - textSize.height / 2.0
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
    
    
    override func zoomScale(_ zoom: Double, _ zoomCenter: CGPoint, position: String) {
        super.zoomScale(zoom, zoomCenter, position: position)
        
        // Apply zoom to bezier points
        if position == "topView" {
            bezierControlPoints.0.topView = Nomography.applyZoom(point: bezierControlPoints.0.topView, scale: zoom, center: zoomCenter)
            bezierControlPoints.1.topView = Nomography.applyZoom(point: bezierControlPoints.1.topView, scale: zoom, center: zoomCenter)
        } else if position == "zoomedView" {
            let screenCenter = CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2)
            bezierControlPoints.0.zoomedView = Nomography.applyZoom(point: bezierControlPoints.0.zoomedView, scale: zoom, center: screenCenter)
            bezierControlPoints.1.zoomedView = Nomography.applyZoom(point: bezierControlPoints.1.zoomedView, scale: zoom, center: screenCenter)

            // We also need to apply zoom to the invisible C & B straight scales
            C.zoomScale(zoom, screenCenter, position: "zoomedViewForBezier")
            B.zoomScale(zoom, screenCenter, position: "zoomedViewForBezier")
        }
    }
    

    override func translateScale(_ translation: CGPoint, position: String) {
        super.translateScale(translation, position: position)
        
        // Apply translation to bezier points
        if position == "topView" {
            bezierControlPoints.0.topView = Nomography.applyPan(point: bezierControlPoints.0.topView, translation: translation)
            bezierControlPoints.1.topView = Nomography.applyPan(point: bezierControlPoints.1.topView, translation: translation)
        } else if position == "zoomedView" {
            bezierControlPoints.0.zoomedView = Nomography.applyPan(point: bezierControlPoints.0.zoomedView, translation: translation)
            bezierControlPoints.1.zoomedView = Nomography.applyPan(point: bezierControlPoints.1.zoomedView, translation: translation)
        }
    }
    

    // Returns the position of a point given its value
    override func getPoint(variableValue: Double, position: String) -> CGPoint? {
        if variableValue == 0 {
            if position == "topView" {
                return startPoint.topView
            } else {
                return startPoint.zoomedView
            }
        }
        
        let valC = C.endValue
        let valB = -(valC/variableValue) - variableValue
        
        let lineBC = (position == "topView") ?
        (B.getPoint(variableValue: valB, position: "topView")!, C.getPoint(variableValue: valC, position: "topView")!) :
        (B.getPoint(variableValue: valB, position: "zoomedViewForBezier")!, C.getPoint(variableValue: valC, position: "zoomedViewForBezier")!)
        
        return findIntersectionWithBezier(line: lineBC, position: position)
    }

        
    // Returns variable value of the unfixed variable between B & C given a position projected on X
    func computeVariableValueFromProjection(_ point: CGPoint, position: String) -> Double {
        // Get the fixed variable between C & B
        if C.fixed {
            // C fixed
            
            // Get line connecting C value and given point
            let CPoint = (position == "topView") ?
            C.getPoint(variableValue: C.variableValue, position: "topView")! :
            C.getPoint(variableValue: C.variableValue, position: "zoomedViewForBezier")!
            
            let CtoPoint = (CPoint, point)
            
            // Get corresponding point on B
            let BPoint = (position == "topView") ?
            Nomography.findIntersection(line1: CtoPoint, line2: (B.startPoint.topView, B.endPoint.topView)) :
            Nomography.findIntersection(line1: CtoPoint, line2: (B.startPoint.zoomedViewForBezier!, B.endPoint.zoomedViewForBezier!))
            
            let BValue = (position == "topView") ?
            B.getVariableValue(point: BPoint, position: "topView") :
            B.getVariableValue(point: BPoint, position: "zoomedViewForBezier")
            
            return BValue
        } else {
            // B fixed
            
            // Get line connecting B value and given point
            let BPoint = (position == "topView") ?
            B.getPoint(variableValue: B.variableValue, position: "topView")! :
            B.getPoint(variableValue: B.variableValue, position: "zoomedViewForBezier")!
            
            let BtoPoint = (BPoint, point)
            
            // Get corresponding point on C
            let CPoint = (position == "topView") ?
            Nomography.findIntersection(line1: BtoPoint, line2: (C.startPoint.topView, C.endPoint.topView)) :
            Nomography.findIntersection(line1: BtoPoint, line2: (C.startPoint.zoomedViewForBezier!, C.endPoint.zoomedViewForBezier!))
            
            let CValue = (position == "topView") ?
            C.getVariableValue(point: CPoint, position: "topView") :
            C.getVariableValue(point: CPoint, position: "zoomedViewForBezier")
            
            return CValue
        }
    }
    
    
    // Computes start & end points of the bezier curve as well as the 2 control points
    func computeBezierPoints() {
        
        startPoint.topView = C.startPoint.topView
        startPoint.zoomedView = startPoint.topView

        // Compute start & end points
        // With startX = 0.0 and endX = 0.96
        // 0.96 is a decent value to have a bezier curve that follows the true curve
        var xEndPoint = 0.96
        var delta = 0.1
        let threshold = 0.01
        
        // Convergence search to find a good enough x end point so that the bezier curve ends as close as possible to its theoretical end value
        while true {
            
            // Build the bezier curve
            
            endPoint.topView = getPoint(xEndPoint)
            endPoint.zoomedView = endPoint.topView
            
            (bezierControlPoints.0.topView, bezierControlPoints.1.topView) = getBezierControlPoints(xStartPoint: 0.0, xEndPoint: xEndPoint)
            
            // Compute the intersection point between the line connecting the max values of both straight lines and the bezier curve
            if let intersectionPoint = findIntersectionWithBezier(line: (C.endPoint.topView, B.endPoint.topView), position: "topView") {
                // If it exists, check its distance to the end of the bezier curve
                let distanceToEnd = euclideanDistance(intersectionPoint, endPoint.topView)
                
                if distanceToEnd < threshold {
                    // If the distance is small enough, we stop the iteration
                    break
                } else {
                    // Else, we decrease xEndPoint by the current delta
                    xEndPoint -= delta
                }
            } else {
                // If the intersection does not exist, it means that we went too far
                // So we go backwards
                xEndPoint += delta
                
                // And we decrease the delta
                delta /= 2
            }
        }
        
        bezierControlPoints.0.zoomedView = bezierControlPoints.0.topView
        bezierControlPoints.1.zoomedView = bezierControlPoints.1.topView
    
        // Update start & end positions based on min & max values of C & B
        startValue = computeVariableValue(c: C.startValue, b: B.startValue)
        endValue = computeVariableValue(c: C.endValue, b: B.endValue)
    }
    
    
    // Computes the value of the variable represented by the curved nomography line
    // Based on given values of the straight nomography lines
    func computeVariableValue(c: Double, b: Double) -> Double {
        
        // For the moment, a curved nomography line can only represent the following equation:
        // x² + bx + c = 0
        // x being the variable represented by the nomography line
        
        // For the moment, c is always positive and b is always negative. Therefore, x is always negative
        // For that reason, we only keep the negative root for x
        
        let x1 = (-b + sqrt(b * b - 4 * c)) / 2
        let x2 = (-b - sqrt(b * b - 4 * c)) / 2
        
        // Keep the negative root
        if x1 <= 0.0 {
            return x1
        } else {
            return x2
        }
    }
    
    
    // Returns the coordinate of the point associated with the given x value for the true curve function
    func getPoint(_ x: Double) -> CGPoint {
        let y = getY(x)
        return CGPoint(x: C.startPoint.topView.x + x * scaleX, y: C.startPoint.topView.y - y * scaleY)
    }
    
    
    // Computes the y value associated with the given x value for the true curve function
    func getY(_ x: Double) -> Double {
        return -(x + 1 + 1/(x - 1))
    }
    
    
    // Implementation of the approximation of a curved line with a bezier curve: https://math.stackexchange.com/questions/1915708/easy-way-to-draw-conics-with-bezier-control-points
    func getBezierControlPoints(xStartPoint: Double, xEndPoint: Double) -> (CGPoint, CGPoint) {
        let P0 = getPoint(xStartPoint)
        let P1 = getPoint(xEndPoint)

        let derivateLineP0 = getDerivateLine(xStartPoint)
        let derivateLineP1 = getDerivateLine(xEndPoint)
        
        let slope = getY(xEndPoint) - getY(xStartPoint) / xEndPoint - xStartPoint
        
        let tangentP0P1 = getDerivateLine(getXFromSlope(slope))

        let PR = Nomography.findIntersection(line1: derivateLineP0, line2: tangentP0P1)
        let PS = Nomography.findIntersection(line1: derivateLineP1, line2: tangentP0P1)

        let bezierControlPoint1 = CGPoint(x: P0.x + 4/3 * (PR.x - P0.x), y: P0.y - 4/3 * (P0.y - PR.y))
        let bezierControlPoint2 = CGPoint(x: P1.x - 4/3 * (P1.x - PS.x), y: P1.y + 4/3 * (PS.y - P1.y))
        
        return (bezierControlPoint1, bezierControlPoint2)
    }
    
    
    // Returns a line with slope equal to the derivate of the true curve at given abscissa x
    func getDerivateLine(_ x: Double) -> (CGPoint, CGPoint) {
        let start = getPoint(x)
        let end = CGPoint(x: start.x + 1.0 * scaleX, y: start.y - 1.0 * getDerivate(x) * scaleY)
        
        return (start, end)
    }
    
    
    // Returns the value of the derivate of the true curve at given abscissa x
    func getDerivate(_ x: Double) -> Double {
        return 1/((x-1)*(x-1)) - 1
    }
    
    
    // Returns the abscissa of the true curved line which has the given slope
    func getXFromSlope(_ slope: Double) -> Double {
        let point1 = (slope + 1 + sqrt(slope + 1))/(slope + 1)
        let point2 = (slope + 1 - sqrt(slope + 1))/(slope + 1)
        
        // Return the point between 0 & 1
        if point1 >= 0 && point1 <= 1 {
            return point1
        } else {
            return point2
        }
    }

    
    // Computes the intersection between the bezier curve and the given line, if it exsits
    // Source: https://www.particleincell.com/wp-content/uploads/2013/08/cubic-line.svg
    func findIntersectionWithBezier(line: (CGPoint, CGPoint), position: String) -> CGPoint? {
        let lx = [line.0.x, line.1.x]
        let ly = [line.0.y, line.1.y]
        
        let px = (position == "topView") ?
        [startPoint.topView.x, bezierControlPoints.0.topView.x, bezierControlPoints.1.topView.x, endPoint.topView.x] :
        [startPoint.zoomedView.x, bezierControlPoints.0.zoomedView.x, bezierControlPoints.1.zoomedView.x, endPoint.zoomedView.x]
        
        let py = (position == "topView") ?
        [startPoint.topView.y, bezierControlPoints.0.topView.y, bezierControlPoints.1.topView.y, endPoint.topView.y] :
        [startPoint.zoomedView.y, bezierControlPoints.0.zoomedView.y, bezierControlPoints.1.zoomedView.y, endPoint.zoomedView.y]
        
                 
        let A = ly[1] - ly[0]
        let B = lx[0] - lx[1]
        let C = lx[0] * (ly[0] - ly[1]) + ly[0] * (lx[1] - lx[0])
     
        let bx = bezierCoeffs(P0: px[0], P1: px[1], P2: px[2], P3: px[3])
        let by = bezierCoeffs(P0: py[0], P1: py[1], P2: py[2], P3: py[3])
     
        var P: [Double] = [-1.0, -1.0, -1.0, -1.0]
        P[0] = A * bx[0] + B * by[0]
        P[1] = A * bx[1] + B * by[1]
        P[2] = A * bx[2] + B * by[2]
        P[3] = A * bx[3] + B * by[3] + C
     
        let r = cubicRoots(a: P[0], b: P[1], c: P[2], d: P[3])

        for i in 0...2 {
            let t = r[i]
            var X: [Double] = [-1.0, -1.0]
     
            X[0] = bx[0] * t * t * t + bx[1] * t * t + bx[2] * t + bx[3]
            X[1] = by[0] * t * t * t + by[1] * t * t + by[2] * t + by[3]
     
            var s: Double = -1.0
            
            if (lx[1] - lx[0]) != 0 {
                s = (X[0] - lx[0]) / (lx[1] - lx[0])
            } else {
                s = (X[1] - ly[0]) / (ly[1] - ly[0])
            }
     
            if !(t < 0 || t > 1.0 || s < 0 || s > 1.0) {
                return CGPoint(x: X[0], y: X[1])
            }

        }
        
        return nil
    }
    
    
    // Source: https://www.particleincell.com/wp-content/uploads/2013/08/cubic-line.svg
    func bezierCoeffs(P0: Double, P1: Double, P2: Double, P3: Double) -> [Double] {
        var Z: [Double] = [-1.0, -1.0, -1.0, -1.0]
        Z[0] = -P0 + 3 * P1 - 3 * P2 + P3
        Z[1] = 3 * P0 - 6 * P1 + 3 * P2
        Z[2] = -3 * P0 + 3 * P1
        Z[3] = P0
        return Z
    }
    
    
    // Compute the cubic roots of an polynom of the 3rd degree
    // Source: https://www.particleincell.com/wp-content/uploads/2013/08/cubic-line.svg
    func cubicRoots(a: Double, b: Double, c: Double, d: Double) -> [Double] {
        let A = b / a
        let B = c / a
        let C = d / a
        let Q = (3 * B - (A * A)) / 9
        let R = (9 * A * B - 27 * C - 2 * (A * A * A)) / 54
        let D = (Q * Q * Q) + (R * R)
     
        var t: [Double] = [-1.0, -1.0, -1.0]
        var Im = 0.0
        
        if (D >= 0) {
            let S = sign(R + sqrt(D)) * pow(abs(R + sqrt(D)), (1/3))
            let T = sign(R - sqrt(D)) * pow(abs(R - sqrt(D)), (1/3))
            
            t[0] = -A / 3 + (S + T)
            t[1] = -A / 3 - (S + T) / 2
            t[2] = -A / 3 - (S + T) / 2
            Im = abs(sqrt(3) * (S - T) / 2)
            
            if (Im != 0) {
                t[1] = -1
                t[2] = -1
            }
        } else {
            let th = acos(R / sqrt(-(Q * Q * Q)))
            t[0] = 2 * sqrt(-Q) * cos(th / 3) - A / 3
            t[1] = 2 * sqrt(-Q) * cos((th + 2 * Double.pi) / 3) - A / 3
            t[2] = 2 * sqrt(-Q) * cos((th + 4 * Double.pi) / 3) - A / 3
            Im = 0.0
        }
     
        for i in 0...2 {
            if t[i] < 0 || t[i] > 1 {
                t[i] = -1
            }
        }

        return t
    }
    
    
    func sign(_ x: Double) -> Double {
        if x < 0.0 {
            return -1.0
        } else {
            return 1.0
        }
    }
}
