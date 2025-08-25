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

    //UI components
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleField = UITextField()
    private let typeField = UITextField()
    private let picker = UIPickerView()
    private let imageView = UIImageView()
    private let chooseImageButton = UIButton(type: .system)
    private let ingredientsTextView = UITextView()
    private let stepsTextView = UITextView()
    private let imageContainer = UIView()

    //data
    private var selectedTypeId: Int?
    private var currentImage: UIImage?

    //constants
    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowOpacity: Float = 0.1
        static let shadowRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let contentInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let spacing: CGFloat = 16
        static let imageHeight: CGFloat = 200
        static let textViewHeight: CGFloat = 120
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLayout()
        fillIfEditing()
        setupNavigationBar()
        setupObservers()
        ingredientsTextView.delegate = self
        stepsTextView.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateShadows()
    }

    //setup
    private func setupAppearance() {
        view.backgroundColor = .systemGroupedBackground
        title = isEditingMode ? "Edit Recipe" : "New Recipe"
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupLayout() {
        // scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        // content
        contentStack.axis = .vertical
        contentStack.spacing = Constants.spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.contentInsets.top),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.contentInsets.left),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.contentInsets.right),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Constants.contentInsets.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Constants.contentInsets.left - Constants.contentInsets.right)
        ])

        // title
        setupTitleField()
        contentStack.addArrangedSubview(createSection(title: "TITLE", view: titleField))

        // type
        setupTypeField()
        contentStack.addArrangedSubview(createSection(title: "CATEGORY", view: typeField))

        // image
        setupImageSection()
        contentStack.addArrangedSubview(createSection(title: "IMAGE", view: imageContainer))

        // ingredients
        setupIngredientsTextView()
        contentStack.addArrangedSubview(createSection(title: "INGREDIENTS (one per line)", view: ingredientsTextView))

        // steps
        setupStepsTextView()
        contentStack.addArrangedSubview(createSection(title: "INSTRUCTIONS (one per line)", view: stepsTextView))
    }

    private func setupTitleField() {
        titleField.placeholder = "Enter recipe title"
        titleField.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleField.backgroundColor = .secondarySystemGroupedBackground
        titleField.layer.cornerRadius = Constants.cornerRadius
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        titleField.leftViewMode = .always
        titleField.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func setupTypeField() {
        typeField.placeholder = "Select category"
        typeField.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        typeField.backgroundColor = .secondarySystemGroupedBackground
        typeField.layer.cornerRadius = Constants.cornerRadius
        typeField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        typeField.leftViewMode = .always
        
        picker.dataSource = self
        picker.delegate = self
        typeField.inputView = picker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))
        ]
        typeField.inputAccessoryView = toolbar
        typeField.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func setupImageSection() {
        
        imageContainer.backgroundColor = .secondarySystemGroupedBackground
        imageContainer.layer.cornerRadius = Constants.cornerRadius
        imageContainer.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemGroupedBackground
        imageView.layer.cornerRadius = Constants.cornerRadius - 2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        chooseImageButton.setTitle("Choose Image", for: .normal)
        chooseImageButton.setTitleColor(.systemBlue, for: .normal)
        chooseImageButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        chooseImageButton.addTarget(self, action: #selector(chooseImage), for: .touchUpInside)
        chooseImageButton.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [imageView, chooseImageButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(stack)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageHeight),
            
            stack.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -16)
        ])
    }

    private func setupIngredientsTextView() {
        setupTextView(ingredientsTextView)
        ingredientsTextView.isScrollEnabled = false
        ingredientsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.textViewHeight).isActive = true
    }

    private func setupStepsTextView() {
        setupTextView(stepsTextView)
        stepsTextView.isScrollEnabled = false
        stepsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.textViewHeight + 40).isActive = true
    }

    private func setupTextView(_ textView: UITextView) {
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .secondarySystemGroupedBackground
        textView.layer.cornerRadius = Constants.cornerRadius
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.showsVerticalScrollIndicator = false
        textView.alwaysBounceVertical = false
    }

    private func createSection(title: String, view: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        
        let stack = UIStackView(arrangedSubviews: [label, view])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func updateShadows() {
        let viewsToShadow: [UIView] = [titleField, typeField, imageContainer, ingredientsTextView, stepsTextView]
        
        viewsToShadow.forEach { view in
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = Constants.shadowOpacity
            view.layer.shadowRadius = Constants.shadowRadius
            view.layer.shadowOffset = Constants.shadowOffset
            view.layer.masksToBounds = false
        }
    }

    // MARK: - Data Handling
    private var isEditingMode: Bool {
        if case .edit = mode { return true } else { return false }
    }

    private func fillIfEditing() {
        switch mode {
        case .add(let suggestion):
            if let suggestion = suggestion {
                titleField.text = suggestion.title
                selectedTypeId = suggestion.typeId
                typeField.text = RecipeStore.shared.typeName(for: suggestion.typeId)
            }
        case .edit(let recipe):
            titleField.text = recipe.title
            selectedTypeId = recipe.typeId
            typeField.text = RecipeStore.shared.typeName(for: recipe.typeId)
            ingredientsTextView.text = recipe.ingredients.joined(separator: "\n")
            stepsTextView.text = recipe.steps.joined(separator: "\n")
            
            if let image = RecipeStore.shared.image(for: recipe.imageFilename) {
                imageView.image = image
                currentImage = image
                chooseImageButton.setTitle("Change Image", for: .normal)
            }
            
            if let row = RecipeStore.shared.recipeTypes.firstIndex(where: { $0.id == recipe.typeId }) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }

    // actions
    @objc private func donePicker() {
        view.endEditing(true)
    }

    @objc private func chooseImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        guard let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            showAlert("Please enter a title")
            return
        }
        
        guard let typeId = selectedTypeId else {
            showAlert("Please choose a recipe type")
            return
        }

        let ingredients = ingredientsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let steps = stepsTextView.text
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var imageFilename: String? = nil
        if let image = currentImage {
            imageFilename = RecipeStore.shared.saveImage(image)
        }

        switch mode {
        case .add:
            let recipe = Recipe(
                title: title,
                typeId: typeId,
                imageFilename: imageFilename,
                ingredients: ingredients,
                steps: steps
            )
            RecipeStore.shared.add(recipe)
            
        case .edit(var recipe):
            recipe.title = title
            recipe.typeId = typeId
            recipe.ingredients = ingredients
            recipe.steps = steps
            if let filename = imageFilename {
                recipe.imageFilename = filename
            }
            RecipeStore.shared.update(recipe)
        }
        
        onSaved?()
        navigationController?.popViewController(animated: true)
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    //keyboard handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        if let image = image {
            currentImage = image
            imageView.image = image
            chooseImageButton.setTitle("Change Image", for: .normal)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    //alert
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // clear
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension AddEditRecipeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        RecipeStore.shared.recipeTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        RecipeStore.shared.recipeTypes[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let type = RecipeStore.shared.recipeTypes[row]
        selectedTypeId = type.id
        typeField.text = type.name
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let type = RecipeStore.shared.recipeTypes[row]
        return NSAttributedString(
            string: type.name,
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        )
    }
}

extension AddEditRecipeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Calculate the required size for the text
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
        
        textView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                if textView == ingredientsTextView {
                    constraint.constant = max(Constants.textViewHeight, newSize.height)
                } else if textView == stepsTextView {
                    constraint.constant = max(Constants.textViewHeight + 40, newSize.height)
                }
            }
        }
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        let rect = textView.convert(textView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}
