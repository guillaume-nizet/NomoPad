import UIKit

class MenuView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var selectedNomogramId: Int = -1
    var premadeNomograms: [(id: Int, name: String)] = []
    var customNomograms: [(id: Int, name: String)] = []
    
    var didSelectRow: ((Int) -> Void)?
    var selectedIndexPathPremade: IndexPath?
    var selectedIndexPathCustom: IndexPath?
    
    let premadesTableView = UITableView()
    let customsTableView = UITableView()
    
    
    func buildView() {
        backgroundColor = UIColor.systemGray6
        
        // Build the label for the title of the menu
        let nomogramListLabel = UILabel()
        nomogramListLabel.text = "Nomograms"
        nomogramListLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        nomogramListLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(nomogramListLabel)
        
        NSLayoutConstraint.activate([
            nomogramListLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            nomogramListLabel.topAnchor.constraint(equalTo: topAnchor, constant: 60)
        ])
        
        // Build the label for the list of premade nomograms
        let premadeNomogramsLabel = UILabel()
        premadeNomogramsLabel.text = "Premade nomograms"
        premadeNomogramsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        premadeNomogramsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(premadeNomogramsLabel)

        NSLayoutConstraint.activate([
            premadeNomogramsLabel.leadingAnchor.constraint(equalTo: nomogramListLabel.leadingAnchor, constant: 10),
            premadeNomogramsLabel.topAnchor.constraint(equalTo: topAnchor, constant: 150),
        ])
        
        
        // Build the list of premade nomograms
        premadesTableView.translatesAutoresizingMaskIntoConstraints = false
        premadesTableView.dataSource = self
        premadesTableView.delegate = self
        premadesTableView.rowHeight = 70
        premadesTableView.layer.cornerRadius = 8
        premadesTableView.isScrollEnabled = false
        
        addSubview(premadesTableView)

        NSLayoutConstraint.activate([
            premadesTableView.topAnchor.constraint(equalTo: premadeNomogramsLabel.bottomAnchor, constant: 20),
            premadesTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            premadesTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            premadesTableView.bottomAnchor.constraint(equalTo: premadeNomogramsLabel.bottomAnchor, constant: 19 + 70 * Double(premadeNomograms.count))
        ])

        
        // Build the label for the list of custom nomograms
        let customNomogramsLabel = UILabel()
        customNomogramsLabel.text = "Custom nomograms"
        customNomogramsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        customNomogramsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(customNomogramsLabel)

        NSLayoutConstraint.activate([
            customNomogramsLabel.leadingAnchor.constraint(equalTo: nomogramListLabel.leadingAnchor, constant: 10),
            customNomogramsLabel.topAnchor.constraint(equalTo: premadesTableView.bottomAnchor, constant: 50),
        ])
        
        
        // Build the list of custom nomograms
        customsTableView.translatesAutoresizingMaskIntoConstraints = false
        customsTableView.dataSource = self
        customsTableView.delegate = self
        customsTableView.rowHeight = 70
        customsTableView.layer.cornerRadius = 8
        customsTableView.isScrollEnabled = false
        
        addSubview(customsTableView)

        NSLayoutConstraint.activate([
            customsTableView.topAnchor.constraint(equalTo: customNomogramsLabel.bottomAnchor, constant: 20),
            customsTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            customsTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            customsTableView.bottomAnchor.constraint(equalTo: customNomogramsLabel.bottomAnchor, constant: 19 + 70 * Double(customNomograms.count))
        ])
    }
       

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == premadesTableView {
            return premadeNomograms.count
        } else {
            return customNomograms.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if tableView == premadesTableView {
            cell.textLabel?.text = premadeNomograms[indexPath.row].name
            
            if premadeNomograms[indexPath.row].id == selectedNomogramId {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                selectedIndexPathPremade = indexPath
            }
        } else {
            cell.textLabel?.text = customNomograms[indexPath.row].name
            
            if customNomograms[indexPath.row].id == selectedNomogramId {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                selectedIndexPathCustom = indexPath
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedKey = (tableView == premadesTableView) ? premadeNomograms[indexPath.row].id : customNomograms[indexPath.row].id
        didSelectRow?(selectedKey)
        
        if tableView == premadesTableView {
            selectedIndexPathPremade = indexPath
            if let selectedIndexPathCustom {
                customsTableView.deselectRow(at: selectedIndexPathCustom, animated: false)
            }
        } else {
            selectedIndexPathCustom = indexPath
            if let selectedIndexPathPremade {
                premadesTableView.deselectRow(at: selectedIndexPathPremade, animated: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == premadesTableView {
            selectedIndexPathPremade = nil
        } else {
            selectedIndexPathCustom = nil
        }
    }
}
