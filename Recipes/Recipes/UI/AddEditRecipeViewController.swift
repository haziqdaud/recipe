import UIKit

final class AddEditRecipeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    enum Mode { case add(Recipe?), edit(Recipe) }
    private let mode: Mode
    var onSaved: (() -> Void)?

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let titleField = UITextField()
    private let typeField = UITextField()
    private let picker = UIPickerView()
    private let imageView = UIImageView()
    private let chooseImageButton = UIButton(type: .system)
    private let ingredientsView = UITextView()
    private let stepsView = UITextView()

    // Data
    private var selectedTypeId: Int?
    private var currentImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        fillIfEditing()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        title = (isEditingMode ? "Edit Recipe" : "Add Recipe")
    }

    private var isEditingMode: Bool { if case .edit = mode { return true } else { return false } }

    private func setupUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical; stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        func labeled(_ label: String, _ view: UIView) -> UIStackView {
            let l = UILabel(); l.text = label; l.font = .preferredFont(forTextStyle: .subheadline)
            let v = UIStackView(arrangedSubviews: [l, view]); v.axis = .vertical; v.spacing = 6
            return v
        }

        titleField.borderStyle = .roundedRect
        stack.addArrangedSubview(labeled("Title", titleField))

        typeField.borderStyle = .roundedRect
        picker.dataSource = self; picker.delegate = self
        typeField.inputView = picker
        let tb = UIToolbar(); tb.sizeToFit()
        tb.items = [UIBarButtonItem(systemItem: .flexibleSpace),
                    UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))]
        typeField.inputAccessoryView = tb
        stack.addArrangedSubview(labeled("Type", typeField))

        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        chooseImageButton.setTitle("Choose Image", for: .normal)
        chooseImageButton.addTarget(self, action: #selector(chooseImage), for: .touchUpInside)
        let imgStack = UIStackView(arrangedSubviews: [imageView, chooseImageButton])
        imgStack.axis = .vertical; imgStack.spacing = 8
        stack.addArrangedSubview(labeled("Picture", imgStack))

        ingredientsView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        ingredientsView.layer.borderWidth = 1; ingredientsView.layer.cornerRadius = 8
        ingredientsView.layer.borderColor = UIColor.separator.cgColor
        ingredientsView.font = .preferredFont(forTextStyle: .body)
        stack.addArrangedSubview(labeled("Ingredients (one per line)", ingredientsView))

        stepsView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        stepsView.layer.borderWidth = 1; stepsView.layer.cornerRadius = 8
        stepsView.layer.borderColor = UIColor.separator.cgColor
        stepsView.font = .preferredFont(forTextStyle: .body)
        stack.addArrangedSubview(labeled("Steps (one per line)", stepsView))
    }

    private func fillIfEditing() {
        switch mode {
        case .add(let suggestion):
            if let s = suggestion {
                titleField.text = s.title
                selectedTypeId = s.typeId
                typeField.text = RecipeStore.shared.typeName(for: s.typeId)
            }
        case .edit(let recipe):
            titleField.text = recipe.title
            selectedTypeId = recipe.typeId
            typeField.text = RecipeStore.shared.typeName(for: recipe.typeId)
            ingredientsView.text = recipe.ingredients.joined(separator: "\n")
            stepsView.text = recipe.steps.joined(separator: "\n")
            if let img = RecipeStore.shared.image(for: recipe.imageFilename) {
                imageView.image = img
                currentImage = img
            }
            // position picker on current type
            if let row = RecipeStore.shared.recipeTypes.firstIndex(where: { $0.id == recipe.typeId }) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }

    @objc private func donePicker() { view.endEditing(true) }

    @objc private func chooseImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        if let img = info[.originalImage] as? UIImage {
            currentImage = img
            imageView.image = img
        }
    }

    @objc private func saveTapped() {
        guard let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            showAlert("Please enter a title"); return
        }
        guard let typeId = selectedTypeId else { showAlert("Please choose a recipe type"); return }

        let ingredients = ingredientsView.text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let steps = stepsView.text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        var imageFilename: String? = nil
        if let img = currentImage { imageFilename = RecipeStore.shared.saveImage(img) }

        switch mode {
        case .add:
            let recipe = Recipe(title: title, typeId: typeId, imageFilename: imageFilename, ingredients: ingredients, steps: steps)
            RecipeStore.shared.add(recipe)
        case .edit(var recipe):
            recipe.title = title
            recipe.typeId = typeId
            recipe.ingredients = ingredients
            recipe.steps = steps
            if let file = imageFilename { recipe.imageFilename = file }
            RecipeStore.shared.update(recipe)
        }
        onSaved?()
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(_ msg: String) {
        let ac = UIAlertController(title: "Missing Info", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

extension AddEditRecipeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { RecipeStore.shared.recipeTypes.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        RecipeStore.shared.recipeTypes[row].name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let t = RecipeStore.shared.recipeTypes[row]
        selectedTypeId = t.id
        typeField.text = t.name
    }
}
