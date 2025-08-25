import UIKit

final class RecipeDetailViewController: UIViewController {
    private var recipe: Recipe
    var onChanged: (() -> Void)?

    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let ingredientsLabel = UILabel()
    private let stepsLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recipe Details"
        view.backgroundColor = .systemBackground
        setupUI()
        fillUI()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped)),
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        ]
    }

    private func setupUI() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        // image view
        imageView.heightAnchor.constraint(equalToConstant: 260).isActive = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        stack.addArrangedSubview(imageView)

        // title
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, typeLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4
        stack.addArrangedSubview(titleStack)

        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        
        typeLabel.font = .systemFont(ofSize: 15, weight: .medium)
        typeLabel.textColor = .secondaryLabel

        // ingredients
        ingredientsLabel.numberOfLines = 0
        stack.addArrangedSubview(makeSection("Ingredients", content: ingredientsLabel, icon: "list.bullet"))

        //steps
        stepsLabel.numberOfLines = 0
        stack.addArrangedSubview(makeSection("Preparation", content: stepsLabel, icon: "number"))
    }

    private func makeSection(_ title: String, content: UIView, icon: String) -> UIView {
        let container = UIView()
        
      
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemOrange
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(titleLabel)
        
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        content.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let contentStack = UIStackView(arrangedSubviews: [headerStack, separator, content])
        contentStack.axis = .vertical
        contentStack.spacing = 10
        
        container.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: container.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }

    private func fillUI() {
        titleLabel.text = recipe.title
        typeLabel.text = RecipeStore.shared.typeName(for: recipe.typeId).uppercased()
        
//format ingrediants
        let ingredientsText = recipe.ingredients.map { ingredient in
            "• \(ingredient)"
        }.joined(separator: "\n")
        
        let ingredientsAttrString = NSMutableAttributedString(string: ingredientsText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        ingredientsAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: ingredientsText.count))
        ingredientsLabel.attributedText = ingredientsAttrString
        ingredientsLabel.font = .systemFont(ofSize: 15)
        ingredientsLabel.textColor = .secondaryLabel // Lighter color for description
        
//steps format
        let stepsText = recipe.steps.enumerated().map { index, step in
            "\(index + 1). \(step)"
        }.joined(separator: "\n")
        
        let stepsAttrString = NSMutableAttributedString(string: stepsText)
        let stepsParagraphStyle = NSMutableParagraphStyle()
        stepsParagraphStyle.lineSpacing = 4
        stepsAttrString.addAttribute(.paragraphStyle, value: stepsParagraphStyle, range: NSRange(location: 0, length: stepsText.count))
        
        recipe.steps.enumerated().forEach { index, _ in
            let searchString = "\(index + 1). "
            if let range = stepsText.range(of: searchString) {
                let nsRange = NSRange(range, in: stepsText)
                stepsAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: nsRange)
                stepsAttrString.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
            }
        }
        
        let fullRange = NSRange(location: 0, length: stepsText.count)
        stepsAttrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: fullRange)
        
        stepsLabel.attributedText = stepsAttrString
        stepsLabel.font = .systemFont(ofSize: 15)
        
        imageView.image = RecipeStore.shared.image(for: recipe.imageFilename)
    }

    @objc private func editTapped() {
        let vc = AddEditRecipeViewController(mode: .edit(recipe))
        vc.onSaved = { [weak self] in
            guard let self else { return }
            if let latest = RecipeStore.shared.recipes.first(where: { $0.id == self.recipe.id }) {
                self.recipe = latest
                self.fillUI()
                self.onChanged?()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func deleteTapped() {
        let ac = UIAlertController(title: "Delete Recipe", message: "This action cannot be undone.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            RecipeStore.shared.delete(id: self.recipe.id)
            self.onChanged?()
            self.navigationController?.popViewController(animated: true)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
}
