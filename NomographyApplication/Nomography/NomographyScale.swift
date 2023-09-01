import UIKit


extension Double {
    
    // This rounding appears several times in the code where products or divisions are performed on Double values: in Swift, some products and divisions are wrong because of floating point precision, for instance: 10.0 / 5.0 can give the value 2.00000000001. Rounding to 10 decimal places provides a fix to this problem but limits the precision. This can lead to bugs with very small values (with a precision < 1^(-10))
    func rounded(toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


typealias Point = (
    topView: CGPoint,
    zoomedView: CGPoint,
    zoomedViewForBezier: CGPoint?
)

typealias Graduation = (
    value: Double,
    point: CGPoint,
    startPoint: CGPoint,
    endPoint: CGPoint,
    textPoint: CGPoint
)

typealias GraduationOrder = (
    graduations: [Graduation],
    step: Double,
    divider: Double
)


class NomographyScale {
    
    let graduationLength = 10.0
    var direction: Double = 1.0
    var zoom = ["topView": 1.0, "zoomedView": 1.0]
    var zoomLevel = ["topView": 1, "zoomedView": 1]
    var zoomThreshold = ["topView": 2.0, "zoomedView": 2.0]
    var dezoomThreshold = ["topView": 1.0, "zoomedView": 1.0]
    var graduations: [String: (firstOrder: GraduationOrder, secondOrder: GraduationOrder)] = [
        "topView": (firstOrder: (graduations: [], step: 0, divider: 0), secondOrder: (graduations: [], step: 0, divider: 0)),
        "zoomedView": (firstOrder: (graduations: [], step: 0, divider: 0), secondOrder: (graduations: [], step: 0, divider: 0))
    ]
    var adjustedVariableValue = ["topView": 0.0, "zoomedView": 0.0]
    var index = -1 // The index is used to place the VariableDetailView of the scale on the screen: 0 = left, 1 = center, 2 = right
    var fixButton = UIButton()
    var valueTextField = UITextField()
    var rangeStartTextField = UITextField()
    var rangeEndTextField = UITextField()

    var factor: Double
    var exponent: Double
    var variableValue: Double
    var startPoint: Point
    var endPoint: Point
    var startValue: Double
    var endValue: Double
    var variableName: String
    var variableUnit: String?
    var fixed: Bool
    var variableEquation: String
    var screenSize: CGSize
    var screenSizeZoomed: CGSize
    var logVariable: Bool
    
    init(factor: Double, exponent: Double, variableValue: Double, startPoint: Point, endPoint: Point, startValue: CGFloat, endValue: CGFloat, variableName: String, variableUnit: String?, fixed: Bool, variableEquation: String, screenSize: CGSize, screenSizeZoomed: CGSize, logVariable: Bool) {
        self.factor = factor
        self.exponent = exponent
        self.variableValue = variableValue
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.startValue = startValue
        self.endValue = endValue
        self.variableName = variableName
        self.variableUnit = variableUnit
        self.fixed = fixed
        self.variableEquation = variableEquation
        self.screenSize = screenSize
        self.screenSizeZoomed = screenSizeZoomed
        self.logVariable = logVariable
    }
    
    // Functions specific to the type of the nomography line, they are overridden in the specific classes
    func buildScale() {}
    func displayScale(in context: CGContext, position: String) {}
    func getPoint(variableValue: Double, position: String) -> CGPoint? {return nil}
    
    
    // Displays the name of the variable represented by the scale on top of it
    func displayVariableName(in context: CGContext) {
        let fontSize: CGFloat = 24
        let offset: CGFloat = 30
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        let variableUnitString = (variableUnit != nil) ? " (\(String(describing: variableUnit!)))" : ""
        let variableNameString = NSAttributedString(string: variableName + variableUnitString, attributes: attributes)
        
        // Center the text on the coordinates
        let size = variableNameString.size()
        let variableNamePoint = CGPoint(x: endPoint.topView.x - size.width/2, y: endPoint.topView.y - size.height/2 - offset)
        
        variableNameString.draw(at: variableNamePoint)
    }


    // Displays the firstOrder and secondOrder graduations along the scale,
    // Displays the value of the firstOrder graduations next to them
    func displayGraduations(in context: CGContext, position: String) {
        // Display the firstOrder graduations
        for graduation in graduations[position]!.firstOrder.graduations {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(2)
            context.move(to: CGPoint(x: graduation.point.x + graduation.startPoint.x, y: graduation.point.y + graduation.startPoint.y))
            context.addLine(to: CGPoint(x: graduation.point.x + graduation.endPoint.x, y: graduation.point.y + graduation.endPoint.y))
            context.strokePath()
            
            // Display the graduation value
            let text = graduation.value.description
            let font = UIFont.systemFont(ofSize: 14)
            
            text.draw(at: CGPoint(x: graduation.point.x - graduation.textPoint.x, y: graduation.point.y - graduation.textPoint.y), withAttributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: UIColor.black])
        }
        
        // Display the secondOrder graduations
        for graduation in graduations[position]!.secondOrder.graduations {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: graduation.point.x + graduation.startPoint.x/2, y: graduation.point.y + graduation.startPoint.y/2))
            context.addLine(to: CGPoint(x: graduation.point.x + graduation.endPoint.x/2, y: graduation.point.y + graduation.endPoint.y/2))
            context.strokePath()
        }
    }
    
    
    // Displays the value of the variable represented by the scale,
    // Displays a red dot at the location of the value. The red dot is filled if the value can be updated (= unfixed) and empty otherwise
    func displayVariableValue(in context: CGContext, position: String) {
        
        // Display red dot at the variable value
        let dotPoint = (position == "topView") ?
        getPoint(variableValue: variableValue, position: "topView")! : // Display it at the variable position on the top view
        CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2) // Display it on the center of the zoomed view since the variable value will always be centered
        
        let strokeColor = UIColor.red
        let circlePath = UIBezierPath(arcCenter: dotPoint, radius: 7, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        
        if !fixed {
            // Display filled dot
            strokeColor.setFill()
            circlePath.fill()
        } else {
            // Display empty dot
            strokeColor.setStroke()
            circlePath.stroke()
        }
        
        // Adjust the displayed variable value based on the zoom: the farther the zoom level, the more decimals will be shown
        let magnitude = log10(abs(endValue - startValue) / zoom[position]!)
        let roundedMagnitude = round(magnitude) - 3
        if roundedMagnitude >= 0 {
            adjustedVariableValue[position]! = variableValue.rounded(toDecimalPlaces: 0)
        } else {
            adjustedVariableValue[position]! = variableValue.rounded(toDecimalPlaces: abs(Int(roundedMagnitude)))
        }
        
        let text = adjustedVariableValue[position]!.description
        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.red]
        
        // Display the adjusted variable value at the bottom right of the dot
        let textPoint = CGPoint(
            x: dotPoint.x + 4,
            y: dotPoint.y + 4
        )
        
        text.draw(at: textPoint, withAttributes: attributes)
    }
    
    
    // Builds the initial graduations for the scale
    func buildGraduations(position: String) {
        
        // Define the direction of the scale
        if startValue > endValue {
            direction = -1.0
        }
        
        // Compute the step between the first firstOrder graduations
        // This step will be a power of 10
        let magnitude = round(log10(abs(endValue - startValue)))
        let step = pow(10, magnitude)/10
        
        // Given this step value, compute the start and end value of the firstOrder graduations
        var startGraduation = findClosestValidGraduationValue(graduationValue: startValue, step: step)
        if !isInsideBounds(variableValue: startGraduation) {
            startGraduation += step * direction
        }
        
        var endGraduation = findClosestValidGraduationValue(graduationValue: endValue, step: step)
        if !isInsideBounds(variableValue: endGraduation) {
            endGraduation -= step * direction
        }
        
        graduations[position]!.firstOrder.graduations = []
        graduations[position]!.secondOrder.graduations = []
        
        // Generate the firstOrder graduations
        for firstOrderGraduationValue in stride(from: startGraduation, to: endGraduation + step * direction, by: step * direction) {
            let firstOrderGraduation = buildGraduation(graduationValue: firstOrderGraduationValue, position: position)!
            graduations[position]!.firstOrder.graduations.append(firstOrderGraduation)
            graduations[position]!.firstOrder.step = step
            graduations[position]!.firstOrder.divider = 2.0
        }
        
        // Generate the secondOrder graduations
        graduations[position]!.secondOrder = generateNextOrder(previousOrder: graduations[position]!.firstOrder, position: position)
    }
    

    // Builds a graduation based on its value and its position (position = either top View or zoomed View). The actual coordinates of the graduation are computed in the function
    func buildGraduation(graduationValue: Double, position: String) -> Graduation? {
        if let straightScale = self as? StraightNomographyScale {
            return straightScale.buildGraduation(graduationValue, position: position, textPosition: "left")
        } else if let curvedScale = self as? CurvedNomographyScale {
            return curvedScale.buildGraduation(graduationValue, position: position)
        } else {
            return nil
        }
    }
    
    
    // Returns the closest valid graduation value based on a graduation value & step value
    func findClosestValidGraduationValue(graduationValue: Double, step: Double) -> Double {
        let count = graduationValue / step
        let roundedCount = count.rounded()

        let belowGraduation: Double = roundedCount * step
        let aboveGraduation: Double = (roundedCount + 1) * step

        if abs(graduationValue - belowGraduation) < abs(graduationValue - aboveGraduation) {
            return belowGraduation
        } else {
            return aboveGraduation
        }
    }
    
    
    // Returns the graduations that belong to the next (= deeper) order, given an order
    // For instance, given graduations with step = 1.0, like [1.0, 2.0, 3.0, 4.0],
    // The next order graduations will have a step = 0.5, and will be equal to [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]
    func generateNextOrder(previousOrder: GraduationOrder, position: String) -> GraduationOrder {
        let nextStep = previousOrder.step / previousOrder.divider
        let nextDivider = (previousOrder.divider == 2.0) ? 5.0 : 2.0
        
        var nextOrder: GraduationOrder = (graduations: [], step: nextStep, divider: nextDivider)
        
        let firstValue = graduations[position]!.firstOrder.graduations.first!.value
        let lastValue = graduations[position]!.firstOrder.graduations.last!.value
        
        for graduationValue in stride(from: firstValue, to: lastValue + nextStep * direction, by: nextStep * direction) {
            let roundedGraduationValue = graduationValue.rounded(toDecimalPlaces: 10)
            let graduation = buildGraduation(graduationValue: roundedGraduationValue, position: position)!
            nextOrder.graduations.append(graduation)
        }
        
        return nextOrder
    }
    
    
    // Performs the translation of the whole scale by translating the scale and the graduations
    func translateScale(_ translation: CGPoint, position: String) {

        // Apply the translation to the scale
        if position == "topView" {
            startPoint.topView = Nomography.applyPan(point: startPoint.topView, translation: translation)
            endPoint.topView = Nomography.applyPan(point: endPoint.topView, translation: translation)
        } else if position == "zoomedView" {
            startPoint.zoomedView = Nomography.applyPan(point: startPoint.zoomedView, translation: translation)
            endPoint.zoomedView = Nomography.applyPan(point: endPoint.zoomedView, translation: translation)
        } else if position == "zoomedViewForBezier" {
            startPoint.zoomedViewForBezier = Nomography.applyPan(point: startPoint.zoomedViewForBezier!, translation: translation)
            endPoint.zoomedViewForBezier = Nomography.applyPan(point: endPoint.zoomedViewForBezier!, translation: translation)
        }
        

        // Apply the translation to the graduations
        if position != "zoomedViewForBezier" { // No graduations in zoomedViewForBezier
            for i in 0..<graduations[position]!.firstOrder.graduations.count {
                graduations[position]!.firstOrder.graduations[i].point = Nomography.applyPan(point: graduations[position]!.firstOrder.graduations[i].point, translation: translation)
            }
            for i in 0..<graduations[position]!.secondOrder.graduations.count {
                graduations[position]!.secondOrder.graduations[i].point = Nomography.applyPan(point: graduations[position]!.secondOrder.graduations[i].point, translation: translation)
            }
        }
    }
    
    
    // Performs the translation of the whole scale by applying zoom to the scale and the graduations
    func zoomScale(_ zoom: Double, _ zoomCenter: CGPoint, position: String) {
        
        // Apply zoom to the line
        if position == "topView" {
            self.zoom["topView"]! *= zoom
            startPoint.topView = Nomography.applyZoom(point: startPoint.topView, scale: zoom, center: zoomCenter)
            endPoint.topView = Nomography.applyZoom(point: endPoint.topView, scale: zoom, center: zoomCenter)
        } else if position == "zoomedView" {
            self.zoom["zoomedView"]! *= zoom
            let screenCenter = CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2)
            startPoint.zoomedView = Nomography.applyZoom(point: startPoint.zoomedView, scale: zoom, center: screenCenter)
            endPoint.zoomedView = Nomography.applyZoom(point: endPoint.zoomedView, scale: zoom, center: screenCenter)
        } else if position == "zoomedViewForBezier" {
            startPoint.zoomedViewForBezier = Nomography.applyZoom(point: startPoint.zoomedViewForBezier!, scale: zoom, center: zoomCenter)
            endPoint.zoomedViewForBezier = Nomography.applyZoom(point: endPoint.zoomedViewForBezier!, scale: zoom, center: zoomCenter)
        }
        
        // Apply zoom to the graduations
        if position != "zoomedViewForBezier" {
            var zoomCenter = zoomCenter
            if position == "zoomedView" {
                zoomCenter = CGPoint(x: screenSizeZoomed.width/2, y: screenSizeZoomed.height/2) // screen center
            }
            
            for i in 0..<graduations[position]!.firstOrder.graduations.count {
                graduations[position]!.firstOrder.graduations[i].point = Nomography.applyZoom(point: graduations[position]!.firstOrder.graduations[i].point, scale: zoom, center: zoomCenter)
            }
            for i in 0..<graduations[position]!.secondOrder.graduations.count {
                graduations[position]!.secondOrder.graduations[i].point = Nomography.applyZoom(point: graduations[position]!.secondOrder.graduations[i].point, scale: zoom, center: zoomCenter)
            }
        }
    }
    
    
    // This function ensures that the graduation list only includes the graduations that are currently shown on the screen
    // This is an important optimization to ensure a fluid application as the zoom level increases
    func handleMovement(position: String) {
        
        // Always keep either at last 2 firstOrder graduations or none
        
        if graduations[position]!.firstOrder.graduations.count > 0 {
            
            // If the 2 first firstOrder graduations got out of screen, remove the first one from the list
            if !isInsideScreen(graduations[position]!.firstOrder.graduations[0], screenSize: screenSize) && !isInsideScreen(graduations[position]!.firstOrder.graduations[1], screenSize: screenSize) {
                
                graduations[position]!.firstOrder.graduations.removeFirst()
                
                // If there is only one graduation left after removing the first one, remove the other one as well
                // Since we always keep either at least 2 graduations or none
                if graduations[position]!.firstOrder.graduations.count == 1 {
                    graduations[position]!.firstOrder.graduations.removeFirst()
                    graduations[position]!.secondOrder.graduations.removeAll()
                } else {
                    removeSecondOrder(upTo: graduations[position]!.firstOrder.graduations.first!.value, order: "ascending", position: position)
                }
            }
        } else {
            tryAddingGraduations(position: position)
        }
        
        
        if graduations[position]!.firstOrder.graduations.count > 0 {
            
            // If the 2 last firstOrder graduations got out of screen, remove the last one from the list
            let lastIndex = graduations[position]!.firstOrder.graduations.indices.last!
            let secondToLastIndex = graduations[position]!.firstOrder.graduations.index(before: lastIndex)
            
            if !isInsideScreen(graduations[position]!.firstOrder.graduations[lastIndex], screenSize: screenSize) && !isInsideScreen(graduations[position]!.firstOrder.graduations[secondToLastIndex], screenSize: screenSize) {
                graduations[position]!.firstOrder.graduations.removeLast()
                
                // If there is only one graduation left after removing the last one, remove the other one as well
                // Since we always keep either at least 2 graduations or none
                if graduations[position]!.firstOrder.graduations.count == 1 {
                    graduations[position]!.firstOrder.graduations.removeFirst()
                    graduations[position]!.secondOrder.graduations.removeAll()
                } else {
                    removeSecondOrder(upTo: graduations[position]!.firstOrder.graduations.last!.value, order: "descending", position: position)
                }
            }
        }
        
    
        if graduations[position]!.firstOrder.graduations.count > 0 {
            
            // Try to add a firstOrder graduation before the first one
            let firstfirstOrderGraduation = graduations[position]!.firstOrder.graduations.first!
            
            if isInsideScreen(firstfirstOrderGraduation, screenSize: screenSize) {
                // Only try to add a firstOrder graduation if the current first firstOrder graduation is inside the screen
                let graduationValue = (firstfirstOrderGraduation.value - (direction * graduations[position]!.firstOrder.step)).rounded(toDecimalPlaces: 10)
                
                if isInsideBounds(variableValue: graduationValue) {
                    // Add the graduation
                    let graduation = buildGraduation(graduationValue: graduationValue, position: position)!
                    graduations[position]!.firstOrder.graduations.insert(graduation, at: 0)
                    
                    // Add the secondOrder graduations
                    addSecondOrder(from: graduation.value, to: firstfirstOrderGraduation.value, order: "ascending", position: position)
                }
            }
            
            
            // Try to add a firstOrder graduation after the last one
            let lastfirstOrderGraduation = graduations[position]!.firstOrder.graduations.last!
            
            if isInsideScreen(lastfirstOrderGraduation, screenSize: screenSize) {
                // Only try to add a firstOrder graduation if the current first firstOrder graduation is inside the screen
                let graduationValue = (lastfirstOrderGraduation.value + (direction * graduations[position]!.firstOrder.step)).rounded(toDecimalPlaces: 10)
                
                if isInsideBounds(variableValue: graduationValue) {

                    // Add the graduation
                    let graduation = buildGraduation(graduationValue: graduationValue, position: position)!
                    graduations[position]!.firstOrder.graduations.append(graduation)
                    
                    // Add the secondOrder graduations
                    addSecondOrder(from: graduation.value, to: lastfirstOrderGraduation.value, order: "descending", position: position)
                }
            }
        }
        
        if graduations[position]!.firstOrder.graduations.count > 0 {
            
            // Compute the average distance between two secondOrder graduations
            let averageDistance = averageDistanceSecondOrder(position: position)
            
            if averageDistance > 200.0 / graduations[position]!.firstOrder.divider {
                // Perform zoom
                zoomGraduations(position: position)
                zoomLevel[position]! += 1
            }
            
            if zoomLevel[position]! > 1 && averageDistance < 20.0 {
                dezoomGraduations(position: position)
                zoomLevel[position]! -= 1
            }
        }
    }
    
    
    // Performs a zoom on the graduations by assigning the secondOrder graduations to the new firstOrder graduations
    // And computing the new secondOrder graduations using generateNextOrder()
    func zoomGraduations(position: String) {
        let secondOrderValues = graduations[position]!.secondOrder.graduations.map { $0.value }
        
        // Build the new firstOrder graduations
        graduations[position]!.firstOrder.graduations = []
        
        for graduationValue in secondOrderValues.sorted(by: direction == 1.0 ? { $0 < $1 } : { $0 > $1 }) {
            let graduation = buildGraduation(graduationValue: graduationValue, position: position)!
            graduations[position]!.firstOrder.graduations.append(graduation)
        }
        
        graduations[position]!.firstOrder.step = graduations[position]!.secondOrder.step
        graduations[position]!.firstOrder.divider = graduations[position]!.secondOrder.divider
        
        // Build the new secondOrder
        graduations[position]!.secondOrder = generateNextOrder(previousOrder: graduations[position]!.firstOrder, position: position)
    }
    
    
    // Performs a dezoom on the graduations by assigning the firstOrder graduations to the new secondOrder graduations
    // And selecting the correct new firstOrder graduations among the new secondOrder graduations
    func dezoomGraduations(position: String) {
        
        let secondOrderDivider = Int(graduations[position]!.secondOrder.divider)
        
        // Build the new secondOrder
        graduations[position]!.secondOrder = graduations[position]!.firstOrder
        
        // Build the new firstOrder
        // Update step & divider
        graduations[position]!.firstOrder.divider = Double(secondOrderDivider) // pas sûr de cette ligne
        graduations[position]!.firstOrder.step *= Double(secondOrderDivider)
        
        graduations[position]!.firstOrder.graduations = []
        
        for graduation in graduations[position]!.secondOrder.graduations {
            let div = graduation.value / graduations[position]!.firstOrder.step
            if div == Double(Int(div)) { // If div can be casted to int
                graduations[position]!.firstOrder.graduations.append(graduation)
            }
        }
    }
    
    
    func tryAddingGraduations(position: String) {

        // The scale is out of screen, wait for it to reappear
        
        // Define the lines corresponding to the screen borders
        let topLine = (CGPoint(x: 0, y: 0), CGPoint(x: screenSize.width, y: 0))
        let bottomLine = (CGPoint(x: 0, y: screenSize.height), CGPoint(x: screenSize.width, y: screenSize.height))
        let leftLine = (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: screenSize.height))
        let rightLine = (CGPoint(x: screenSize.width, y: 0), CGPoint(x: screenSize.width, y: screenSize.height))
        
        // To detect that the line is back on screen, we compute the intersection point between each of the for lines defining the screen borders and the line itself, and if the intersection is inside the screen, it means that the line is inside the screen
        
        if isInsideScreen(startPoint.topView, screenSize: screenSize) && isInsideScreen(endPoint.topView, screenSize: screenSize) {
            // Edge case: the straight scale reappeared in the screen through one of the vertical sides of the screen
            buildGraduations(position: position)
        } else {
            for line in [topLine, bottomLine, leftLine, rightLine] {

                let intersectionPoint = findIntersectionWithScale(line: line, position: position)
                
                if intersectionPoint == nil {
                    continue
                }
                
                // If the scale is a curved scale, no need to check if the intersection is inside the bounds
                if let curvedScale = self as? CurvedNomographyScale {
                    if !isInsideScreen(intersectionPoint!, screenSize: screenSize) {
                        continue
                    } else {
                        buildGraduations(position: position)
                    }
                } else if let straightScale = self as? StraightNomographyScale {
                    // For each possible intersection, we compute the value of the scale that should be displayed at this intersection point
                    let valueAtIntersection = straightScale.getVariableValue(point: intersectionPoint!, position: "topView")
                    
                    if !isInsideBounds(variableValue: valueAtIntersection) || !isInsideScreen(intersectionPoint!, screenSize: screenSize) {
                        continue
                    } else {
                        buildGraduations(position: position)
                    }
                }
            }
        }
    }
    
    
    func removeSecondOrder(upTo: Double, order: String, position: String) {
        
        var removedCount = 0
    
        if order == "ascending" {
            for i in 0..<graduations[position]!.secondOrder.graduations.count {
                if graduations[position]!.secondOrder.graduations[i].value == upTo {
                    break
                }
                removedCount += 1
            }
            graduations[position]!.secondOrder.graduations.removeFirst(removedCount)
        } else if order == "descending" {
            for i in (0..<graduations[position]!.secondOrder.graduations.count).reversed() {
                if graduations[position]!.secondOrder.graduations[i].value == upTo {
                    break
                }
                removedCount += 1
            }
            graduations[position]!.secondOrder.graduations.removeLast(removedCount)
        }
    }
    
    
    func addSecondOrder(from: Double, to: Double, order: String, position: String) {
        
        var newGraduations: [Graduation] = []
        let dir = (order == "ascending") ? 1.0 : -1.0
        
        for graduationValue in stride(from: from, to: to, by: graduations[position]!.secondOrder.step * direction * dir) {
            let roundedGraduationValue = graduationValue.rounded(toDecimalPlaces: 10) // To avoid weird values
            let graduation = buildGraduation(graduationValue: roundedGraduationValue, position: position)!
            newGraduations.append(graduation)
        }
        
        if order == "ascending" {
            graduations[position]!.secondOrder.graduations.insert(contentsOf: newGraduations, at: 0)
        } else if order == "descending" {
            graduations[position]!.secondOrder.graduations.append(contentsOf: newGraduations.reversed())
        }
    }
    
    
    // Returns the intersection point between the scale and a given line, if it exists
    func findIntersectionWithScale(line: (CGPoint, CGPoint), position: String) -> CGPoint? {
        if let straightScale = self as? StraightNomographyScale {
            return straightScale.findIntersectionWithScale(line: line, position: position)
        } else if let curvedScale = self as? CurvedNomographyScale {
            return curvedScale.findIntersectionWithBezier(line: line, position: position)
        } else {
            return nil
        }
    }
    
        

    func euclideanDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        return sqrt((point2.x - point1.x) * (point2.x - point1.x) + (point2.y - point1.y) * (point2.y - point1.y))
    }
    
    
    func setFixed(_ fixed: Bool) {
        self.fixed = fixed
    }
    
    
    // We need to implement the "true" modulus operator since Swift does not support negative modulus
    func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
    
    
    func isInsideScreen(_ point: CGPoint, screenSize: CGSize, tolerance: Double = 0.1) -> Bool {
        return !(
            point.x < 0 - tolerance ||
            point.x > screenSize.width + tolerance ||
            point.y < 0 - tolerance ||
            point.y > screenSize.height + tolerance
        )
    }
    
    
    func isInsideScreen(_ graduation: Graduation, screenSize: CGSize) -> Bool {
        // Build the hitbox of the graduation
        let graduationHitBox = buildHitBox(graduation)
        
        // Check if the hitbox is completely outside of the screen borders
        return !(
            graduationHitBox.maxX < 0 ||
            graduationHitBox.minX > screenSize.width ||
            graduationHitBox.maxY < 0 ||
            graduationHitBox.minY > screenSize.height
        )
    }
    
    
    func findClosestGraduationValue(_ value: Double, _ graduationValues: [Double]) -> Double {
        var previousDifference = abs(graduationValues[0] - value)
        
        for i in 1..<graduationValues.count {
            let difference = abs(graduationValues[i] - value)
            
            if difference > previousDifference {
                return graduationValues[i-1]
            }
            previousDifference = difference
        }
        return graduationValues.last!
    }
    
    
    func buildHitBox(_ graduation: Graduation) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        
        let graduationStartPoint = CGPoint(x: graduation.point.x + graduation.startPoint.x, y: graduation.point.y + graduation.startPoint.y)
        let graduationEndPoint = CGPoint(x: graduation.point.x + graduation.endPoint.x, y: graduation.point.y + graduation.endPoint.y)
        let graduationTextPoint = CGPoint(x: graduation.point.x - graduation.textPoint.x, y: graduation.point.y - graduation.textPoint.y)
        
        
        // Calculate the size of the graduation
        let graduationMinX = min(graduationStartPoint.x, graduationEndPoint.x)
        let graduationMinY = min(graduationStartPoint.y, graduationEndPoint.y)
        let graduationMaxX = max(graduationStartPoint.x, graduationEndPoint.x)
        let graduationMaxY = max(graduationStartPoint.y, graduationEndPoint.y)
        
        // Calculate the size of the text
        let text = graduation.value.description
        let font = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = text.size(withAttributes: attributes)
        
        let textMinX = graduationTextPoint.x
        let textMinY = graduationTextPoint.y
        let textMaxX = textMinX + textSize.width
        let textMaxY = textMinY + textSize.height
        
        return(
            minX: min(graduationMinX, textMinX),
            minY: min(graduationMinY, textMinY),
            maxX: max(graduationMaxX, textMaxX),
            maxY: max(graduationMaxY, textMaxY)
        )
    }
    
    
    func averageDistanceSecondOrder(position: String) -> Double {
        var averageDistance = 0.0
        
        for i in 1..<graduations[position]!.secondOrder.graduations.count {
            averageDistance += euclideanDistance(graduations[position]!.secondOrder.graduations[i].point, graduations[position]!.secondOrder.graduations[i-1].point)
        }
        
        averageDistance /= Double(graduations[position]!.secondOrder.graduations.count-1)
        
        return averageDistance
    }
    
    
    func isInsideBounds(variableValue: CGFloat) -> Bool {
        var lowerBound = startValue
        var upperBound = endValue
        
        if lowerBound > upperBound {
            lowerBound = upperBound
            upperBound = startValue
        }
        
        return variableValue >= lowerBound && variableValue <= upperBound
    }
    
    
    func getFirstGraduationValue(position: String) -> Double {
        
        let firstValueFirstOrder = graduations[position]!.firstOrder.graduations.first!.value
        let firstValueSecondOrder = graduations[position]!.secondOrder.graduations.first!.value
        
        if firstValueFirstOrder < firstValueSecondOrder {
            return (direction == 1) ? firstValueFirstOrder : firstValueSecondOrder
        } else {
            return (direction == 1) ? firstValueSecondOrder : firstValueFirstOrder
        }
    }
    
    
    func getLastGraduationValue(position: String) -> Double {
        
        let lastValueFirstOrder = graduations[position]!.firstOrder.graduations.last!.value
        let lastValueSecondOrder = graduations[position]!.secondOrder.graduations.last!.value
        
        if lastValueFirstOrder > lastValueSecondOrder {
            return (direction == 1) ? lastValueFirstOrder : lastValueSecondOrder
        } else {
            return (direction == 1) ? lastValueSecondOrder : lastValueFirstOrder
        }
    }
}
