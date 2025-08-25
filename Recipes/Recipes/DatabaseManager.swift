//import SQLite
//import Foundation
//
//final class DatabaseManager {
//    static let shared = DatabaseManager()
//    private var db: Connection?
//    
//    private init() {
//        setupDatabase()
//    }
//    
//    private func setupDatabase() {
//        do {
//            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
//            db = try Connection("\(path)/recipes.sqlite3")
//            print("Database path: \(path)/recipes.sqlite3")
//            createTables()
//        } catch {
//            print("Database connection failed: \(error)")
//        }
//    }
//    
//    func getConnection() -> Connection? {
//        return db
//    }
//    
//    // MARK: - Table Definitions
//    struct RecipeTypeTable {
//        static let table = Table("recipe_types")
//        static let id = Expression<Int>("id")
//        static let name = Expression<String>("name")
//    }
//    
//    struct RecipeTable {
//        static let table = Table("recipes")
//        static let id = Expression<String>("id")
//        static let title = Expression<String>("title")
//        static let typeId = Expression<Int>("type_id")
//        static let imageFilename = Expression<String?>("image_filename")
//        static let ingredients = Expression<String>("ingredients")
//        static let steps = Expression<String>("steps")
//        static let createdAt = Expression<Date>("created_at")
//    }
//    
//    // MARK: - Create Tables
//    private func createTables() {
//        createRecipeTypesTable()
//        createRecipesTable()
//    }
//    
//    private func createRecipeTypesTable() {
//        do {
//            try db?.run(RecipeTypeTable.table.create(ifNotExists: true) { t in
//                t.column(RecipeTypeTable.id, primaryKey: true)
//                t.column(RecipeTypeTable.name)
//            })
//            print("Recipe types table created successfully")
//        } catch {
//            print("Failed to create recipe_types table: \(error)")
//        }
//    }
//    
//    private func createRecipesTable() {
//        do {
//            try db?.run(RecipeTable.table.create(ifNotExists: true) { t in
//                t.column(RecipeTable.id, primaryKey: true)
//                t.column(RecipeTable.title)
//                t.column(RecipeTable.typeId)
//                t.column(RecipeTable.imageFilename)
//                t.column(RecipeTable.ingredients)
//                t.column(RecipeTable.steps)
//                t.column(RecipeTable.createdAt)
//            })
//            print("Recipes table created successfully")
//        } catch {
//            print("Failed to create recipes table: \(error)")
//        }
//    }
//    
//    // MARK: - Helper Functions
//    func encodeJSONArray(_ array: [String]) -> String {
//        do {
//            let data = try JSONEncoder().encode(array)
//            return String(data: data, encoding: .utf8) ?? "[]"
//        } catch {
//            return "[]"
//        }
//    }
//    
//    func decodeJSONArray(_ jsonString: String) -> [String] {
//        guard let data = jsonString.data(using: .utf8) else { return [] }
//        do {
//            return try JSONDecoder().decode([String].self, from: data)
//        } catch {
//            return []
//        }
//    }
//    
//    // MARK: - Recipe CRUD Operations
//    func insertRecipe(_ recipe: Recipe) throws {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        let insert = RecipeTable.table.insert(
//            RecipeTable.id <- recipe.id.uuidString,
//            RecipeTable.title <- recipe.title,
//            RecipeTable.typeId <- recipe.typeId,
//            RecipeTable.imageFilename <- recipe.imageFilename,
//            RecipeTable.ingredients <- encodeJSONArray(recipe.ingredients),
//            RecipeTable.steps <- encodeJSONArray(recipe.steps),
//            RecipeTable.createdAt <- recipe.createdAt
//        )
//        try db.run(insert)
//    }
//    
//    func fetchAllRecipes() throws -> [Recipe] {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        let query = RecipeTable.table.order(RecipeTable.createdAt.desc)
//        return try db.prepare(query).map { row in
//            Recipe(
//                id: UUID(uuidString: row[RecipeTable.id]) ?? UUID(),
//                title: row[RecipeTable.title],
//                typeId: row[RecipeTable.typeId],
//                imageFilename: row[RecipeTable.imageFilename],
//                ingredients: decodeJSONArray(row[RecipeTable.ingredients]),
//                steps: decodeJSONArray(row[RecipeTable.steps]),
//                createdAt: row[RecipeTable.createdAt]
//            )
//        }
//    }
//    
//    func updateRecipe(_ recipe: Recipe) throws {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        let recipeRow = RecipeTable.table.filter(RecipeTable.id == recipe.id.uuidString)
//        let update = recipeRow.update(
//            RecipeTable.title <- recipe.title,
//            RecipeTable.typeId <- recipe.typeId,
//            RecipeTable.imageFilename <- recipe.imageFilename,
//            RecipeTable.ingredients <- encodeJSONArray(recipe.ingredients),
//            RecipeTable.steps <- encodeJSONArray(recipe.steps),
//            RecipeTable.createdAt <- recipe.createdAt
//        )
//        try db.run(update)
//    }
//    
//    func deleteRecipe(id: UUID) throws {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        let recipeRow = RecipeTable.table.filter(RecipeTable.id == id.uuidString)
//        try db.run(recipeRow.delete())
//    }
//    
//    // MARK: - Recipe Type Operations
//    func insertRecipeTypes(_ types: [RecipeType]) throws {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        // Clear existing types
//        try db.run(RecipeTypeTable.table.delete())
//        
//        // Insert new types
//        for type in types {
//            let insert = RecipeTypeTable.table.insert(
//                RecipeTypeTable.id <- type.id,
//                RecipeTypeTable.name <- type.name
//            )
//            try db.run(insert)
//        }
//    }
//    
//    func fetchAllRecipeTypes() throws -> [RecipeType] {
//        guard let db = db else { throw DatabaseError.connectionFailed }
//        
//        let query = RecipeTypeTable.table
//        return try db.prepare(query).map { row in
//            RecipeType(id: row[RecipeTypeTable.id], name: row[RecipeTypeTable.name])
//        }
//    }
//}
//
//enum DatabaseError: Error {
//    case connectionFailed
//    case operationFailed
//}
