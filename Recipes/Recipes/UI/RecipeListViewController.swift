import UIKit

final class RecipeListViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let filterTextField = UITextField()
    private let picker = UIPickerView()
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

        filterTextField.placeholder = "Filter by type"
        filterTextField.borderStyle = .roundedRect
        filterTextField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(filterTextField)

        picker.dataSource = self
        picker.delegate = self
        filterTextField.inputView = picker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearFilter)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneFilter))
        ]
        filterTextField.inputAccessoryView = toolbar

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            filterTextField.topAnchor.constraint(equalTo: container.topAnchor),
            filterTextField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            filterTextField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            filterTextField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterTextField.superview!.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadData() {
        let all = RecipeStore.shared.recipes
        if let typeId = selectedTypeId {
            filtered = all.filter { $0.typeId == typeId }
            let name = RecipeStore.shared.typeName(for: typeId)
            filterTextField.text = name
        } else {
            filtered = all
        }
        tableView.reloadData()
    }

    @objc private func clearFilter() {
        selectedTypeId = nil
        filterTextField.text = nil
        view.endEditing(true)
        reloadData()
    }

    @objc private func doneFilter() {
        view.endEditing(true)
    }
}

extension RecipeListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let r = filtered[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var conf = cell.defaultContentConfiguration()
        conf.text = r.title
        conf.secondaryText = RecipeStore.shared.typeName(for: r.typeId)
        if let img = RecipeStore.shared.image(for: r.imageFilename) {
            conf.image = img
            conf.imageProperties.maximumSize = CGSize(width: 44, height: 44)
            conf.imageProperties.cornerRadius = 6
        }
        cell.contentConfiguration = conf
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let r = filtered[indexPath.row]
        let vc = RecipeDetailViewController(recipe: r)
        vc.onChanged = { [weak self] in self?.reloadData() }
        navigationController?.pushViewController(vc, animated: true)
    }

    // swipe to delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let r = filtered[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { _,_,done in
            RecipeStore.shared.delete(id: r.id)
            self.reloadData()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}

extension RecipeListViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { RecipeStore.shared.recipeTypes.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        RecipeStore.shared.recipeTypes[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedTypeId = RecipeStore.shared.recipeTypes[row].id
        reloadData()
    }
}
