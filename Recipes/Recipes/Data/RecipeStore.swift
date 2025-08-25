import UIKit

final class RecipeStore {
    
    static let shared = RecipeStore()
    
    private enum Constants {
        static let recipeTypesJSON = "recipetypes"
        static let savedRecipesKey = "savedRecipes"
        static let imagePrefix = "img_"
        static let imageExtension = ".jpg"
        static let imageCompression: CGFloat = 0.9
        static let imageSize = CGSize(width: 44, height: 44)
    }
    
    private(set) var recipeTypes: [RecipeType] = []
    private(set) var recipes: [Recipe] = []
    
    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let documentsDirectory: URL
    
    private init(
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        loadRecipeTypes()
        loadRecipes()
    }
    
    //data loading
    private func loadRecipeTypes() {
        guard let url = Bundle.main.url(forResource: Constants.recipeTypesJSON, withExtension: "json") else {
            assertionFailure("\(Constants.recipeTypesJSON).json missing from bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            recipeTypes = try JSONDecoder().decode([RecipeType].self, from: data)
        } catch {
            print("Failed to load recipe types: \(error.localizedDescription)")
        }
    }
    
    private func loadRecipes() {
        guard let savedRecipesData = userDefaults.data(forKey: Constants.savedRecipesKey) else {
            seedSampleData()
            return
        }
        
        do {
            recipes = try JSONDecoder().decode([Recipe].self, from: savedRecipesData)
        } catch {
            print("Failed to decode saved recipes: \(error.localizedDescription)")
            seedSampleData()
        }
    }
    
    //sample data - dummy data
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
        do {
            let encoded = try JSONEncoder().encode(recipes)
            userDefaults.set(encoded, forKey: Constants.savedRecipesKey)
        } catch {
            print("Failed to save recipes: \(error.localizedDescription)")
        }
    }
    
    //crud
    func add(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
        saveRecipes()
    }
    
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else {
            print("Recipe not found for update")
            return
        }
        
        recipes[index] = recipe
        saveRecipes()
    }
    
    func delete(id: UUID) {
        guard let index = recipes.firstIndex(where: { $0.id == id }) else {
            print("Recipe not found for deletion")
            return
        }
        
        let recipe = recipes[index]
        removeImageIfNeeded(for: recipe)
        recipes.remove(at: index)
        saveRecipes()
    }
    
    //img manage
    func saveImage(_ image: UIImage) -> String? {
        let filename = Constants.imagePrefix + UUID().uuidString + Constants.imageExtension
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard let imageData = image.jpegData(compressionQuality: Constants.imageCompression) else {
            print("Failed to compress image")
            return nil
        }
        
        do {
            try imageData.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func image(for filename: String?) -> UIImage? {
        guard let filename = filename, !filename.isEmpty else { return nil }
        
        if let assetImage = UIImage(named: filename) {
            return assetImage
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func removeImageIfNeeded(for recipe: Recipe) {
        guard let filename = recipe.imageFilename else { return }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to remove image file: \(error.localizedDescription)")
        }
    }
    
    func typeName(for id: Int) -> String {
        recipeTypes.first { $0.id == id }?.name ?? "Unknown Type"
    }
    
    func getRecipesByType(_ typeId: Int?) -> [Recipe] {
        guard let typeId = typeId else { return recipes }
        return recipes.filter { $0.typeId == typeId }
    }
    
    func recipe(with id: UUID) -> Recipe? {
        recipes.first { $0.id == id }
    }
    
    var recipesCount: Int {
        recipes.count
    }
    
    var availableTypes: [RecipeType] {
        recipeTypes
    }
}
