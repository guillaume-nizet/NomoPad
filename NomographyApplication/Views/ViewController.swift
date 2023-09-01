import UIKit


// Starting point of the app
class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }
        
        
    // Builds the starting View of the app by creating the MainView (UIView) that will contain all the other Views
    func buildView() {
        let mainView = MainView(frame: view.frame)
        mainView.initView()
        view.addSubview(mainView)
    }
}
