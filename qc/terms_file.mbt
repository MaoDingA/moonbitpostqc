///|
pub(all) struct UserTermsFile {
  confusion_pairs : Array[ConfusionPair]
  consistency_terms : Array[ConsistencyTerm]
  user_terms : Array[UserTerm]
} derive(Eq, Debug)

///|
fn terms_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn terms_bool(obj : Map[String, Json], key : String, default : Bool) -> Bool {
  match obj.get(key) {
    Some(True) => true
    Some(False) => false
    _ => default
  }
}

///|
fn parse_confusion_pair_obj(obj : Map[String, Json]) -> ConfusionPair? {
  match (terms_string(obj, "wrong"), terms_string(obj, "correct")) {
    (Some(wrong), Some(correct)) => {
      let context = match terms_string(obj, "context") {
        Some(c) => c
        None => ""
      }
      Some({ wrong, correct, context })
    }
    _ => None
  }
}

///|
fn parse_consistency_term_obj(obj : Map[String, Json]) -> ConsistencyTerm? {
  match terms_string(obj, "canonical") {
    Some(canonical) => {
      let variants = match obj.get("variants") {
        Some(Array(values)) => {
          let vs : Array[String] = []
          for value in values {
            match value {
              String(text) => vs.push(text)
              _ => ()
            }
          }
          vs
        }
        _ => []
      }
      Some({ canonical, variants })
    }
    None => None
  }
}

///|
fn parse_user_term_obj(obj : Map[String, Json]) -> UserTerm? {
  match (terms_string(obj, "pattern"), terms_string(obj, "preferred")) {
    (Some(pattern), Some(preferred)) => {
      let reason = match terms_string(obj, "reason") {
        Some(r) => r
        None => ""
      }
      let forbidden = terms_bool(obj, "forbidden", false)
      Some({ pattern, preferred, reason, forbidden })
    }
    _ => None
  }
}

///|
pub fn parse_user_terms_file(raw : String) -> Result[UserTermsFile, String] {
  let json = @json.parse(raw) catch {
    error => return Err("invalid terms file json: \{error.to_string()}")
  }
  match json {
    Object(obj) => {
      // Parse confusion_pairs
      let confusion_pairs : Array[ConfusionPair] = []
      match obj.get("confusion_pairs") {
        Some(Array(values)) =>
          for value in values {
            match value {
              Object(pair_obj) =>
                match parse_confusion_pair_obj(pair_obj) {
                  Some(pair) => confusion_pairs.push(pair)
                  None => ()
                }
              _ => ()
            }
          }
        _ => ()
      }
      // Parse consistency_terms
      let consistency_terms : Array[ConsistencyTerm] = []
      match obj.get("consistency_terms") {
        Some(Array(values)) =>
          for value in values {
            match value {
              Object(term_obj) =>
                match parse_consistency_term_obj(term_obj) {
                  Some(term) => consistency_terms.push(term)
                  None => ()
                }
              _ => ()
            }
          }
        _ => ()
      }
      // Parse user_terms
      let user_terms : Array[UserTerm] = []
      match obj.get("user_terms") {
        Some(Array(values)) =>
          for value in values {
            match value {
              Object(term_obj) =>
                match parse_user_term_obj(term_obj) {
                  Some(term) => user_terms.push(term)
                  None => ()
                }
              _ => ()
            }
          }
        _ => ()
      }
      Ok({ confusion_pairs, consistency_terms, user_terms })
    }
    _ => Err("terms file root must be an object")
  }
}
