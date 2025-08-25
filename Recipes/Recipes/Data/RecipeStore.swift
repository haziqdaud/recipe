import UIKit

final class RecipeStore {
    static let shared = RecipeStore()
    
    private init() {
        loadRecipeTypes()
        loadRecipes()
    }
    
    // MARK: - Public state
    private(set) var recipeTypes: [RecipeType] = []
    private(set) var recipes: [Recipe] = []
    
    // MARK: - Loaders
    private func loadRecipeTypes() {
        guard let url = Bundle.main.url(forResource: "recipetypes", withExtension: "json") else {
            assertionFailure("recipetypes.json missing from bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            recipeTypes = try JSONDecoder().decode([RecipeType].self, from: data)
        } catch {
            print("Failed to read recipetypes.json: \(error)")
        }
    }
    
    private func loadRecipes() {
        // Load from UserDefaults or use sample data if none exists
        if let savedRecipesData = UserDefaults.standard.data(forKey: "savedRecipes"),
           let savedRecipes = try? JSONDecoder().decode([Recipe].self, from: savedRecipesData) {
            recipes = savedRecipes
        } else {
            seedSampleData()
        }
    }
    
    private func seedSampleData() {
        let sampleRecipes = [
            Recipe(
                title: "Pancakes",
                typeId: 1,
                imageFilename: "Pancakes",
                ingredients: ["1 cup flour", "1 egg", "1 cup milk", "1 tbsp sugar", "1 tsp baking powder", "Pinch of salt"],
                steps: ["Mix dry ingredients", "Whisk in egg and milk", "Cook on greased pan until bubbles form", "Flip and finish"]
            ),
            Recipe(
                title: "Iced Lemon Tea",
                typeId: 5,
                imageFilename: "Iced lemon tea",
                ingredients: ["Black tea bag", "Lemon juice", "Ice", "Sugar"],
                steps: ["Brew tea", "Add sugar while hot", "Cool, add lemon and ice"]
            ),
            Recipe(
                title: "Spaghetti Aglio e Olio",
                typeId: 3,
                imageFilename: "Spaghetti",
                ingredients: ["Spaghetti", "Olive oil", "Garlic", "Chilli flakes", "Parsley", "Salt"],
                steps: ["Boil pasta", "Sauté garlic & chilli", "Toss pasta with oil", "Season and serve"]
            )
        ]
        
        recipes = sampleRecipes
        saveRecipes()
    }
    
    private func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: "savedRecipes")
        }
    }
    
    // MARK: - CRUD Operations
    func add(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
        saveRecipes()
    }
    
    func update(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
            saveRecipes()
        }
    }
    
    func delete(id: UUID) {
        if let index = recipes.firstIndex(where: { $0.id == id }) {
            // remove image file if exists
            if let filename = recipes[index].imageFilename {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: path)
            }
            recipes.remove(at: index)
            saveRecipes()
        }
    }
    
    // MARK: - Images
    func saveImage(_ image: UIImage) -> String? {
        let name = "img_\(UUID().uuidString).jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            print("Save image failed: \(error)")
            return nil
        }
    }
    
    func image(for filename: String?) -> UIImage? {
        guard let filename = filename else { return nil }
        
        // First try to load from Assets.xcassets (for sample data)
        if let assetImage = UIImage(named: filename) {
            return assetImage
        }
        
        // Then try to load from Documents directory (for user-added images)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }
    
    // Helpers
    func typeName(for id: Int) -> String {
        recipeTypes.first(where: { $0.id == id })?.name ?? "Unknown"
    }
    
    func getRecipesByType(_ typeId: Int?) -> [Recipe] {
        guard let typeId = typeId else { return recipes }
        return recipes.filter { $0.typeId == typeId }
    }
}
