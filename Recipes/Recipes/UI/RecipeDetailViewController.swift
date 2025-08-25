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
        title = "Recipe"
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

        stack.axis = .vertical; stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        imageView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        stack.addArrangedSubview(imageView)

        titleLabel.font = .preferredFont(forTextStyle: .title2)
        stack.addArrangedSubview(titleLabel)

        typeLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(typeLabel)

        ingredientsLabel.numberOfLines = 0
        stepsLabel.numberOfLines = 0
        stack.addArrangedSubview(makeSection("Ingredients", ingredientsLabel))
        stack.addArrangedSubview(makeSection("Steps", stepsLabel))
    }

    private func makeSection(_ title: String, _ content: UIView) -> UIStackView {
        let h = UILabel(); h.text = title; h.font = .preferredFont(forTextStyle: .headline)
        let v = UIStackView(arrangedSubviews: [h, content]); v.axis = .vertical; v.spacing = 6
        return v
    }

    private func fillUI() {
        titleLabel.text = recipe.title
        typeLabel.text = RecipeStore.shared.typeName(for: recipe.typeId)
        ingredientsLabel.text = recipe.ingredients.map { "• \($0)" }.joined(separator: "\n")
        stepsLabel.text = recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        imageView.image = RecipeStore.shared.image(for: recipe.imageFilename)
    }

    @objc private func editTapped() {
        let vc = AddEditRecipeViewController(mode: .edit(recipe))
        vc.onSaved = { [weak self] in
            guard let self else { return }
            // reload from store to reflect latest update
            if let latest = RecipeStore.shared.recipes.first(where: { $0.id == self.recipe.id }) {
                self.recipe = latest
                self.fillUI()
                self.onChanged?()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func deleteTapped() {
        let ac = UIAlertController(title: "Delete Recipe", message: "This cannot be undone.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            RecipeStore.shared.delete(id: self.recipe.id)
            self.onChanged?()
            self.navigationController?.popViewController(animated: true)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
}
