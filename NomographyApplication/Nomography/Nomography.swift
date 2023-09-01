import UIKit


typealias Range = (
    startValue: Double,
    endValue: Double
)


// Static class offering useful functions used for nomography operations
class Nomography {
    
    
    // Scales the given point based on a center point
    static func applyZoom(point: CGPoint, scale: CGFloat, center: CGPoint) -> CGPoint {
        var newPoint = point
        newPoint = newPoint.applying(CGAffineTransform(translationX: -center.x, y: -center.y))
        newPoint = newPoint.applying(CGAffineTransform(scaleX: scale, y: scale))
        newPoint = newPoint.applying(CGAffineTransform(translationX: center.x, y: center.y))
        return newPoint
    }
    
    
    // Translates the given point
    static func applyPan(point: CGPoint, translation: CGPoint) -> CGPoint {
        var newPoint = point
        newPoint = newPoint.applying(CGAffineTransform(translationX: translation.x, y: translation.y))
        return newPoint
    }
    
    
    // Computes the intersection point between two lines
    static func findIntersection(line1: (CGPoint, CGPoint), line2: (CGPoint, CGPoint)) -> CGPoint {
        let matrix1 = [
            [line1.0.x, line1.1.x, -1],
            [line1.0.y, line1.1.y, -1],
            [1, 1, 1]
        ]
        let matrix2 = [
            [line2.0.x, line2.1.x, -1],
            [line2.0.y, line2.1.y, -1],
            [1, 1, 1]
        ]
                
        let coefsLine1 = Nomography.applySarrus(matrix: matrix1)
        let coefsLine2 = Nomography.applySarrus(matrix: matrix2)
        
        let x1 = (-coefsLine2.2 - coefsLine2.1 * (-coefsLine1.2 / coefsLine1.1))/(coefsLine2.0 + coefsLine2.1 * (-coefsLine1.0 / coefsLine1.1))
        let x2 = (-coefsLine1.2 - coefsLine1.0 * x1) / coefsLine1.1
        
        return CGPoint(x: x1, y: x2)
    }
    
    
    // Applies Sarrus method to matrix and returns the coef. for x1 and x2, as well as the indep. term
    // by putting the determinant of the matrix = 0
    // => coef_x1 * coef_x2 = indep_term
    static func applySarrus(matrix: [[CGFloat]]) -> (Double, Double, Double) {
        
        
        let coef_x1 = matrix[1][0] * matrix[2][1] - matrix[2][0] * matrix[1][1]
        let coef_x2 = matrix[0][1] * matrix[2][0] - matrix[2][1] * matrix[0][0]
        let indep_term = matrix[0][0] * matrix[1][1] - matrix[1][0] * matrix[0][1]
        
        return (coef_x1, coef_x2, indep_term)
    }
    
    
    // Computes if the given point is in the hitbox of the target point (= if it is within a given distance of the target point)
    static func isInHitbox(target: CGPoint, point: CGPoint, tolerance: Double = 40.0) -> Bool {
        let distance = sqrt((point.x - target.x) * (point.x - target.x) + (point.y - target.y) * (point.y - target.y))
        return distance < tolerance
    }
    

    // Returns the 3 nomography scales for the addition equation:
    // f(C) = f(A) + f(B) + addedTerm
    static func getNomographyScalesAddition(_ initA: NomographyScaleInitializer, _ initB: NomographyScaleInitializer, _ initC: NomographyScaleInitializer, addedTerm: Double, screenSize: CGSize) -> [NomographyScale] {
        
        // Define the nomography scales
        let A = StraightNomographyScale(
            factor: initA.factor,
            exponent: initA.exponent,
            
            // Initialize the A scale position on the left of the screen
            startPoint: Point(topView: CGPoint(x: 0, y: 100), zoomedView: CGPoint(x: 0, y: 100), zoomedViewForBezier: nil),
            endPoint: Point(topView: CGPoint(x: 0, y: 0), zoomedView: CGPoint(x: 0, y: 0), zoomedViewForBezier: nil),
            
            startValue: initA.range!.startValue,
            endValue: initA.range!.endValue,
            variableValue: (initA.range!.startValue + initA.range!.endValue) / 2, // Initialize the value at the middle of the range
            variableName: initA.name,
            variableUnit: initA.unit,
            fixed: false,
            screenSize: screenSize,
            screenSizeZoomed: CGSize.zero, // The screen size of the zoomed view will be updated once the zoom view is loaded
            variableEquation: "input1",
            logVariable: false
        )
        
        let B = StraightNomographyScale(
            factor: initB.factor,
            exponent: initB.exponent,
            
            // Initialize the B scale position on the right of the screen
            startPoint: Point(topView: CGPoint(x: 100, y: 100), zoomedView: CGPoint(x: 100, y: 100), zoomedViewForBezier: nil),
            endPoint: Point(topView: CGPoint(x: 100, y: 0), zoomedView: CGPoint(x: 100, y: 0), zoomedViewForBezier: nil),
            
            startValue: initB.range!.startValue,
            endValue: initB.range!.endValue,
            variableValue: (initB.range!.startValue + initB.range!.endValue) / 2,
            variableName: initB.name,
            variableUnit: initB.unit,
            fixed: false,
            screenSize: screenSize,
            screenSizeZoomed: screenSize,
            variableEquation: "input2",
            logVariable: false
        )
        
        
        // Compute the start & end points of the 3rd nomography scale
        let bValue = (A.factor * A.endValue + B.factor * B.startValue - A.factor * A.startValue) / B.factor
        let bPoint = B.getPoint(variableValue: bValue, position: "topView")!
        
        let intersectionPoint = Nomography.findIntersection(line1: (A.endPoint.topView, B.startPoint.topView), line2: (A.startPoint.topView, bPoint))
        let startPointC = CGPoint(x: intersectionPoint.x, y: A.startPoint.topView.y)
        let endPointC = CGPoint(x: intersectionPoint.x, y: A.endPoint.topView.y)
        
        // Define the 3rd nomography scale
        let C = StraightNomographyScale(
            factor: initC.factor,
            exponent: initC.exponent,
            startPoint: Point(topView: startPointC, zoomedView: startPointC, zoomedViewForBezier: nil),
            endPoint: Point(topView: endPointC, zoomedView: endPointC, zoomedViewForBezier: nil),
            startValue: (A.factor * A.startValue + B.factor * B.startValue + addedTerm) / initC.factor,
            endValue: (A.factor * A.endValue + B.factor * B.endValue + addedTerm) / initC.factor,
            variableValue: (A.factor * A.variableValue + B.factor * B.variableValue + addedTerm) / initC.factor,
            variableName: initC.name,
            variableUnit: initC.unit,
            fixed: true,
            screenSize: screenSize,
            screenSizeZoomed: CGSize.zero,
            variableEquation: "output",
            logVariable: false
        )
        

        // Re-arrange lines (3rd scale may not end up in the middle of the 2 others)
        
        let paddingX = screenSize.width / 9
        let paddingY = screenSize.height / 9
        
        let bottomLeft = CGPoint(x: paddingX, y: screenSize.height - paddingY)
        let topLeft = CGPoint(x: paddingX, y: paddingY)
        let bottomRight = CGPoint(x: screenSize.width - paddingX, y: screenSize.height - paddingY)
        let topRight = CGPoint(x: screenSize.width - paddingX, y: paddingY)
        
        
        // Get the x coordinate of the leftmost and rightmost nomography lines
        let minPosition = min(A.startPoint.topView.x, B.startPoint.topView.x, C.startPoint.topView.x)
        let maxPosition = max(A.startPoint.topView.x, B.startPoint.topView.x, C.startPoint.topView.x)
        
        for straightNomographyScale in [A, B, C] {
            let xPosition = straightNomographyScale.startPoint.topView.x
            
            // Move the leftmost line to the left side of the screen
            if xPosition == minPosition {
                straightNomographyScale.startPoint.topView = bottomLeft
                straightNomographyScale.endPoint.topView = topLeft
                straightNomographyScale.startPoint.zoomedView = bottomLeft
                straightNomographyScale.endPoint.zoomedView = topLeft
                straightNomographyScale.index = 0 // Index 0 = left scale
                straightNomographyScale.buildScale()
            }
            
            // Move the rightmost line to the right side of the screen
            else if xPosition == maxPosition {
                straightNomographyScale.startPoint.topView = bottomRight
                straightNomographyScale.endPoint.topView = topRight
                straightNomographyScale.startPoint.zoomedView = bottomRight
                straightNomographyScale.endPoint.zoomedView = topRight
                straightNomographyScale.index = 2 // Index 2 = right scale
                straightNomographyScale.buildScale()
            }
            
            // Move the center line by keeping the proportions
            else {
                let scaleFactor = (xPosition - minPosition) / (maxPosition - minPosition)
                let newXPosition = bottomLeft.x + scaleFactor * (bottomRight.x - bottomLeft.x)
                straightNomographyScale.startPoint.topView = CGPoint(x: newXPosition, y: bottomLeft.y)
                straightNomographyScale.endPoint.topView = CGPoint(x: newXPosition, y: topLeft.y)
                straightNomographyScale.startPoint.zoomedView = CGPoint(x: newXPosition, y: bottomLeft.y)
                straightNomographyScale.endPoint.zoomedView = CGPoint(x: newXPosition, y: topLeft.y)
                straightNomographyScale.index = 1 // Index 1 = middle scale
                straightNomographyScale.buildScale()
            }
        }
        
        return [A, B, C].sorted(by: {$0.index < $1.index})
    }
    
    
    
    
    // Returns the 3 nomography scales for the multiplication equation:
    // f(C) = factor * f(A) * f(B)
    static func getNomographyScalesMultiplication(_ initA: NomographyScaleInitializer, _ initB: NomographyScaleInitializer, _ initC: NomographyScaleInitializer, factor: Double, screenSize: CGSize) -> [NomographyScale] {
        
        // By taking log on both sides of the multiplication equation, we get:
        //
        // log(f(C)) = log(factor * f(A) * f(B))
        // log(f(C)) = log(factor) + log(f(A)) + log(f(B))
        //
        // Thus, we can take the logarithms of the variables and the factor and use them to get the nomography scales for addition
        // And get back the original values by taking the exponential of the variables once the nomography scales are computed
        
        // Logarithm of variables
        var newInitA = initA
        var newInitB = initB
        
        newInitA.range = Range(startValue: log(initA.range!.startValue), endValue: log(initA.range!.endValue))
        newInitA.factor = initA.factor * initA.exponent
        
        newInitB.range = Range(startValue: log(initB.range!.startValue), endValue: log(initB.range!.endValue))
        newInitB.factor = initB.factor * initB.exponent
        
        // Logarithm of factor
        let addedTerm = log(factor)

        // Get the scales for addition
        let nomographyScales = getNomographyScalesAddition(newInitA, newInitB, initC, addedTerm: addedTerm, screenSize: screenSize)

        // Replace by exponential values
        for nomographyScale in nomographyScales {
            if nomographyScale.variableEquation == "input1" {
                nomographyScale.startValue = initA.range!.startValue
                nomographyScale.endValue = initA.range!.endValue
                nomographyScale.variableValue = exp(nomographyScale.variableValue)
                nomographyScale.factor = initA.factor
                nomographyScale.exponent = initA.exponent
                nomographyScale.logVariable = true
                nomographyScale.buildScale()
            } else if nomographyScale.variableEquation == "input2" {
                nomographyScale.startValue = initB.range!.startValue
                nomographyScale.endValue = initB.range!.endValue
                nomographyScale.variableValue = exp(nomographyScale.variableValue)
                nomographyScale.factor = initB.factor
                nomographyScale.exponent = initB.exponent
                nomographyScale.logVariable = true
                nomographyScale.buildScale()
            } else if nomographyScale.variableEquation == "output" {
                nomographyScale.startValue = exp(nomographyScale.startValue).rounded(toDecimalPlaces: 10)
                nomographyScale.endValue = exp(nomographyScale.endValue).rounded(toDecimalPlaces: 10)
                nomographyScale.variableValue = exp(nomographyScale.variableValue)
                nomographyScale.factor = initC.factor
                nomographyScale.exponent = initC.exponent
                nomographyScale.logVariable = true
                nomographyScale.buildScale()
            }
        }

        return nomographyScales
    }
    
    
    // Returns the 3 nomography scales for the second degree equation:
    // X² + BX + C = 0
    static func getNomographyScalesSecondDegree(_ initC: NomographyScaleInitializer, _ initB: NomographyScaleInitializer, _ initX: NomographyScaleInitializer, screenSize: CGSize) -> [NomographyScale] {
        
        // Define & build the straight nomography lines
        
        let paddingX = screenSize.width / 9
        let paddingY = screenSize.height / 9
        
        let CStartPoint = CGPoint(x: paddingX, y: screenSize.height - paddingY)
        let CEndPoint = CGPoint(x: paddingX, y: paddingY)
        
        let C = StraightNomographyScale(
            factor: 1,
            exponent: 1,
            startPoint: Point(topView: CStartPoint, zoomedView: CStartPoint, zoomedViewForBezier: CStartPoint),
            endPoint: Point(topView: CEndPoint, zoomedView: CEndPoint, zoomedViewForBezier: CEndPoint),
            startValue: initC.range!.startValue,
            endValue: initC.range!.endValue,
            variableValue: (initC.range!.startValue + initC.range!.endValue) / 2,
            variableName: initC.name,
            variableUnit: initC.unit,
            fixed: false,
            screenSize: screenSize,
            screenSizeZoomed: CGSize.zero,
            variableEquation: "input1",
            logVariable: false
        )
        
        C.buildScale()
        
        
        let BStartPoint = CGPoint(x: screenSize.width - paddingX, y: screenSize.height - paddingY)
        let BEndPoint = CGPoint(x: screenSize.width - paddingX, y: paddingY)
        
        let B = StraightNomographyScale(
            factor: 1,
            exponent: 1,
            startPoint: Point(topView: BStartPoint, zoomedView: BStartPoint, zoomedViewForBezier: BStartPoint),
            endPoint: Point(topView: BEndPoint, zoomedView: BEndPoint, zoomedViewForBezier: BEndPoint),
            startValue: initB.range!.startValue,
            endValue: initB.range!.endValue,
            variableValue: (initB.range!.startValue + initB.range!.endValue) / 2,
            variableName: initB.name,
            variableUnit: initB.unit,
            fixed: false,
            screenSize: screenSize,
            screenSizeZoomed: CGSize.zero,
            variableEquation: "input2",
            logVariable: false
        )
        
        B.buildScale()


        // Compute the value of X
        let x1 = (-B.variableValue + sqrt(B.variableValue * B.variableValue - 4 * C.variableValue)) / 2
        let x2 = (-B.variableValue - sqrt(B.variableValue * B.variableValue - 4 * C.variableValue)) / 2
        
        // Keep the negative root
        let XValue = (x1 <= 0) ? x1 : x2
        
        // Define & build the curved nomography line
        // Start/end points & values are initialized to default values - they will be computed in the initialization of the CurvedNomographyScale
        let X = CurvedNomographyScale(
            C: C,
            B: B,
            factor: 1,
            exponent: 1,
            variableValue: XValue,
            startPoint: Point(topView: CGPoint(x: 0, y: 0), zoomedView: CGPoint(x: 0, y: 0), zoomedViewForBezier: nil),
            endPoint: Point(topView: CGPoint(x: 0, y: 0), zoomedView: CGPoint(x: 0, y: 0), zoomedViewForBezier: nil),
            startValue: 0,
            endValue: 0,
            variableName: initX.name,
            variableUnit: initX.unit,
            fixed: true,
            variableEquation: "output",
            screenSize: screenSize,
            screenSizeZoomed: CGSize.zero,
            logVariable: false
        )
        
        X.buildScale()

        return [C, X, B]
    }
}
