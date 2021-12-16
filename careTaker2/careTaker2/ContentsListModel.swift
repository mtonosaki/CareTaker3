import Foundation
import Firebase
import FirebaseDatabase
import CodableFirebase


enum ContentsListModelState {
    case loading
    case finish
    case error
}

typealias ResultHandler<T> = (Result<T, Error>) -> Void

class ContentsListModel {
    var contents = [ContentModel]()
    let DBRef = Database.database().reference()
    
    init(idKey:String = "careTakerID", progress: @escaping (ContentsListModelState) -> Void){
        guard let id = UserDefaults.standard.string(forKey: idKey) else {
            self.generateNewUser(idKey: idKey, progress: progress)
            return
        }
        self.pullData(id: id, progress: progress)
    }
    
    func generateNewUser(idKey: String, progress: @escaping (ContentsListModelState) -> Void) {
        progress(.loading)
        DBRef.child("temp").getData(){ error,snap in
            guard let arrayofDicts = snap.value as? [[String:Any]] else {
                progress(.error)
                return
            }
            arrayofDicts.forEach {dict in
                guard let content = try? FirebaseDecoder().decode(ContentModel.self, from: dict) else {
                    progress(.error)
                    print("-----Decode error-----")
                    return
                }
                self.contents.append(content)
            }
            let id = self.DBRef.child("users").childByAutoId()
            let data = try? FirebaseEncoder().encode(self.contents)
            id.setValue(data)
            UserDefaults.standard.set(id.key, forKey: idKey)
            print("----generate----")
            progress(.finish)
        }
    }
    
    func pullData(id: String, progress: @escaping (ContentsListModelState) -> Void) {
        progress(.loading)
        DBRef.child("users/\(id)").getData(){ error,snap in
            guard let arrayofDicts = snap.value as? [[String:Any]] else {
                progress(.error)
                print("----cast error----")
                return
            }
            arrayofDicts.forEach {dict in
                guard let content = try? FirebaseDecoder().decode(ContentModel.self, from: dict) else {
                    progress(.error)
                    print("-----Decode error-----")
                    return
                }
                self.contents.append(content)
            }
            progress(.finish)
            print("----pullData----")
        }
    }
}