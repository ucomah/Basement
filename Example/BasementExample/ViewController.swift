import UIKit
import Combine
import Basement

class ViewController: UIViewController {
    
    enum Section: Int { case main }
    
    typealias Item = Color
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    
    // MARK: -
    
    lazy final var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        table.delegate = self
        view.addSubview(table)
        return table
    }()
    
    final lazy private(set) var dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)
        cell.textLabel?.text = formatter.string(from: Date(timeIntervalSinceReferenceDate: itemIdentifier.time))
        cell.backgroundColor = itemIdentifier.color
        return cell
    }
    
    lazy final private var footer: UIStackView = {
        let label1 = UILabel()
        let label2 = UILabel()
        label1.textAlignment = .center
        label2.textAlignment = .center
        let stackView = UIStackView(arrangedSubviews: [label1, label2])
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        return stackView
    }()
    
    lazy final private var header: UILabel = {
        let label = UILabel()
        label.text = "Delete objects by tapping on them"
        label.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
        label.textAlignment = .center
        return label
    }()
    
    lazy final private var tickButton = UIBarButtonItem(title: "Tick", style: .done, target: nil, action: nil)
    lazy final private var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    
    private var subscriptions: Set<AnyCancellable> = []
    
    // MARK: -
    
    lazy var colors: Results<Color> = {
        try! Container().items(Color.self).sorted(byKeyPath: "time", ascending: false)
    }()
    
    lazy var ticker: TickCounter = {
        let ticker = TickCounter()
        try! Container().write { transaction in
            transaction.add(ticker, update: .error)
        }
        return ticker
    }()
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupActions()
    }
    
    private func setup() {
        view.backgroundColor = .white
        tableView.frame = view.bounds
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = tickButton
        navigationController?.navigationBar.prefersLargeTitles = true
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func setupActions() {
        addButton.actionPublisher().sink { _ in
            try! Container().write { transaction in
                transaction.add(Color(), update: .error)
            }
        }.store(in: &subscriptions)
        
        tickButton.actionPublisher().sink { [unowned self]  _ in
            let ticker = self.ticker
            try! Container().write { transaction in
                ticker.ticks += 1
            }
        }.store(in: &subscriptions)
        
        colors.collectionPublisher.map { results in
            "Colors count \(results.count)"
        }.sink { completion in
            print("Collection Publisher Completed")
        } receiveValue: { [weak self] value in
            self?.navigationItem.title = value
        }.store(in: &subscriptions)

        colors.changesetPublisher.sink { _ in
            print("Changeset Publisher Completed")
        } receiveValue: { [unowned self] changes in
            switch changes {
            case .initial(let items):
                self.applyUpdates(items: items.map { $0 })
            case .update(let items, _, _, _):
                self.applyUpdates(items: items.map { $0 })
            case .error(let error):
                print("😱", error)
            }
        }.store(in: &subscriptions)
        
        try! Container().items(TickCounter.self).collectionPublisher.scan(0, { result, _ in
            result + 1
        }).map {
            "\($0) changes"
        }.sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] count in
            (self.footer.arrangedSubviews[0] as! UILabel).text = "Ticks"
            (self.footer.arrangedSubviews[1] as! UILabel).text = count
        }
        ).store(in: &subscriptions)
    }
    
    private func applyUpdates(items: [Color], animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animated) {
            print("UI updated")
        }
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(indexPath)")
        let item = dataSource.itemIdentifier(for: indexPath)!
        try! Container().write { transaction in
            transaction.delete(item)
        }
    }
}

// MARK: - Cell

final class Cell: UITableViewCell {
    static let reuseId = "cell"
}
