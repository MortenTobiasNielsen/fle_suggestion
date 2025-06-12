import "@typespec/http";
using Http;

model Position {
  x: float32;
  y: float32;
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
  @post
  @route("/actions")
  op performActions(
    @body actions: PerformActionsRequest
  ): void | ValidationProblemDetails;
}

