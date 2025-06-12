import "@typespec/http";
using Http;

model Position {
  x: float32;
  y: float32;
}

model Tile {
  name: string;
  position: Position;
}

model Map {
  waterTiles: Array<Tile>;
  landTiles: Array<Tile>;
}

model Product {
  name: string;
  min: int32;
  max: int32;
}

model BoundingBox {
  topLeft: Position;
  BottomRight: Position;
}

model Resource {
  miningTime: int32;
  products: Product;
  selectionBox: BoundingBox;
}

model ResourcePatch extends Resource {
  quantity: int32;
}

model Resources {
  trees: Array<Resource>;
  ironOre: Array<ResourcePatch>;
  copperOre: Array<ResourcePatch>;
}

model item {
  name: string;
}

model Items {
  items: Array<item>;
}

model Recipe {
  name: string;
}

model Recipes {
  recipes: Array<Recipe>;
}

model Character {
  id: string;
  name: string;
  position: Position;
}

model Characters {
  characters: Array<Character>;
}

model MoveTo {
  actionType: "moveTo";
  characterId: string;
  position: Position;
}

model Build {
  actionType: "build";
  characterId: string;
  position: Position;
  item: string;
  direction: string;
}

@discriminated(#{ discriminatorPropertyName: "actionType", envelope: "none" })
union Action {
  moveTo: MoveTo;
  build: Build;
}

model ActionError {
  /** Zero-based index into the incoming array */
  actionIndex: int32;
  /** Description of why it failed */
  message: string;
}

@error
model ValidationProblemDetails {
  /** HTTP status code: 400 */
  @statusCode
  code: 400;

  /** A URI for this error type (optional) */
  type?: string;
  /** Short, human-readable summary */
  title: string;
  /** One entry per bad action */
  errors: ActionError[];
}

model PerformActionsRequest {
  actions: Action[];
}

@service(#{
  title: "FLE API",
})
namespace FLE_API {

  @get
  @route("/map")
  op getMap(
    @query position: Position,
    @query radius: float64
  ): Map;

  @get
  @route("/resources")
  op getResources(
    @query position: Position,
    @query radius: float64
  ): Resources;

  @get
  @route("/items")
  op getItems(
    @query position: Position,
    @query radius: float64
  ): Items;

  @get
  @route("/recipes")
  op getRecipes(
    @query position: Position,
    @query radius: float64
  ): Recipes;

  @get
  @route("/characters")
  op listCharacters(
    @query force: boolean
  ): Characters;

  @post
  @route("/actions")
  op performActions(
    @body actions: PerformActionsRequest
  ): void | ValidationProblemDetails;
}

