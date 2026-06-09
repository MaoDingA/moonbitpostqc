///|
pub(all) struct CleanAction {
  code : String
  original : String
  replacement : String
} derive(Eq, Debug)

///|
pub(all) struct LineCleanResult {
  text : String
  actions : Array[CleanAction]
} derive(Eq, Debug)

///|
pub fn LineCleanResult::is_clean(self : LineCleanResult) -> Bool {
  self.actions.length() == 0
}

///|
pub fn CleanAction::describe(self : CleanAction) -> String {
  "\{self.code}: '\{self.original}' → '\{self.replacement}'"
}
