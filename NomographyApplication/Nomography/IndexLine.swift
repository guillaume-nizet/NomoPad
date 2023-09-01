import Foundation

class IndexLine {
    
    // Start and end coordinates of the index line
    var startPoint: CGPoint
    var endPoint: CGPoint

    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    
    func translateLine(_ translation: CGPoint) {
        startPoint = Nomography.applyPan(point: startPoint, translation: translation)
        endPoint = Nomography.applyPan(point: endPoint, translation: translation)
    }
}

