import UIKit

final class RecipeListViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let filterSegmentedControl = UISegmentedControl()
    private var filtered: [Recipe] = []
    private var selectedTypeId: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recipes"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            let vc = AddEditRecipeViewController(mode: .add(nil))
            vc.onSaved = { [weak self] in self?.reloadData() }
            self.navigationController?.pushViewController(vc, animated: true)
        })

        configureFilter()
        configureTable()
        reloadData()
    }

    private func configureFilter() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        filterSegmentedControl.insertSegment(withTitle: "All", at: 0, animated: false)
        
        for (index, type) in RecipeStore.shared.recipeTypes.enumerated() {
            filterSegmentedControl.insertSegment(withTitle: type.name, at: index + 1, animated: false)
        }
        
        filterSegmentedControl.selectedSegmentIndex = 0
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        filterSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(filterSegmentedControl)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.heightAnchor.constraint(equalToConstant: 40),

            filterSegmentedControl.topAnchor.constraint(equalTo: container.topAnchor),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            filterSegmentedControl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    @objc private func filterChanged() {
        if filterSegmentedControl.selectedSegmentIndex == 0 {
            selectedTypeId = nil
        } else {
            let typeIndex = filterSegmentedControl.selectedSegmentIndex - 1
            selectedTypeId = RecipeStore.shared.recipeTypes[typeIndex].id
        }
        reloadData()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterSegmentedControl.superview!.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadData() {
        let all = RecipeStore.shared.recipes.sorted { $0.title < $1.title }
        if let typeId = selectedTypeId {
            filtered = all.filter { $0.typeId == typeId }
        } else {
            filtered = all
        }
        tableView.reloadData()
        
        if filtered.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = selectedTypeId == nil ? "No recipes yet" : "No recipes in this category"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
    }
}

final class RecipeTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView?.layer.cornerRadius = 8
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .scaleAspectFill
        textLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        detailTextLabel?.font = .systemFont(ofSize: 14)
        detailTextLabel?.textColor = .secondaryLabel
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = CGRect(x: 16, y: 8, width: 56, height: 56)
    }
}

extension RecipeListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = filtered[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = r.title
        cell.detailTextLabel?.text = RecipeStore.shared.typeName(for: r.typeId)
        
        if let img = RecipeStore.shared.image(for: r.imageFilename) {
            cell.imageView?.image = img
        } else {
            cell.imageView?.image = UIImage(systemName: "photo")?
                .withTintColor(.secondarySystemBackground, renderingMode: .alwaysOriginal)
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let r = filtered[indexPath.row]
        let vc = RecipeDetailViewController(recipe: r)
        vc.onChanged = { [weak self] in self?.reloadData() }
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }

    // swipe to delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let r = filtered[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { _,_,done in
            RecipeStore.shared.delete(id: r.id)
            self.reloadData()
            done(true)
        }
        action.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [action])
    }
}
