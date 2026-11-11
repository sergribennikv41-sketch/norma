PRAGMA foreign_keys = ON;

CREATE TABLE app_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE ingredients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  kcal REAL NOT NULL,
  protein REAL NOT NULL,
  fat REAL NOT NULL,
  carbs REAL NOT NULL
);

CREATE TABLE ingredient_allergens (
  ingredient_id TEXT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  allergen TEXT NOT NULL,
  PRIMARY KEY (ingredient_id, allergen)
);

CREATE TABLE ingredient_prices (
  ingredient_id TEXT PRIMARY KEY REFERENCES ingredients(id) ON DELETE CASCADE,
  price_per_kg REAL NOT NULL,
  updated_at TEXT
);

CREATE TABLE recipes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  servings INTEGER NOT NULL DEFAULT 1,
  minutes INTEGER NOT NULL,
  source TEXT,
  image TEXT
);

CREATE TABLE recipe_meal_types (
  recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  meal_type TEXT NOT NULL,
  PRIMARY KEY (recipe_id, meal_type)
);

CREATE TABLE recipe_ingredients (
  recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(id),
  grams REAL NOT NULL,
  PRIMARY KEY (recipe_id, ingredient_id)
);

CREATE TABLE recipe_steps (
  recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  step_no INTEGER NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (recipe_id, step_no)
);

CREATE TABLE user_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sex TEXT NOT NULL,
  age INTEGER NOT NULL,
  height_cm REAL NOT NULL,
  weight_kg REAL NOT NULL,
  activity TEXT NOT NULL,
  goal TEXT NOT NULL,
  pace TEXT NOT NULL,
  meals_per_day INTEGER NOT NULL,
  max_cook_minutes INTEGER,
  daily_budget_rub INTEGER,
  excluded_allergens TEXT NOT NULL DEFAULT '',
  disliked_ingredients TEXT NOT NULL DEFAULT '',
  preferred_recipes TEXT NOT NULL DEFAULT '',
  blocked_recipes TEXT NOT NULL DEFAULT ''
);

CREATE TABLE meal_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  days INTEGER NOT NULL,
  seed INTEGER NOT NULL,
  target_kcal REAL NOT NULL,
  target_protein REAL NOT NULL,
  target_fat REAL NOT NULL,
  target_carbs REAL NOT NULL
);

CREATE TABLE plan_meals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
  day_index INTEGER NOT NULL,
  meal_type TEXT NOT NULL,
  recipe_id TEXT NOT NULL REFERENCES recipes(id),
  scale REAL NOT NULL
);

CREATE TABLE plan_meal_ingredients (
  plan_meal_id INTEGER NOT NULL REFERENCES plan_meals(id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(id),
  grams REAL NOT NULL,
  PRIMARY KEY (plan_meal_id, ingredient_id)
);

CREATE INDEX idx_recipe_meal_types_type ON recipe_meal_types(meal_type);
CREATE INDEX idx_recipe_ingredients_ingredient ON recipe_ingredients(ingredient_id);
CREATE INDEX idx_plan_meals_plan ON plan_meals(plan_id);
